//
//  main.m
//  DobbyExample
//
//  Created by jiaxw on 2022/11/28.
//

#import <Foundation/Foundation.h>
#import "dobby.h"
#import <dlfcn.h>
#import <mach-o/getsect.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <sys/ptrace.h>

typedef void (*scan_memory_handler)(intptr_t addr);

#if !defined(PT_DENY_ATTACH)
#define PT_DENY_ATTACH 31
#endif
typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);


//void * dlopen(const char * __path, int __mode);

void * (*orig_dlopen)(const char * path, int mode);

void* fake_dlopen(const char * path, int mode){
    printf("call %s, path: %s\n", __func__, path);
    return orig_dlopen(path, mode);
}

int (*orig_ptrace)(int _request, pid_t _pid, caddr_t _addr, int _data);

int fake_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data){
    if (_request == PT_DENY_ATTACH) {
        _request = 0;
    }
    return orig_ptrace(_request, _pid, _addr, _data);
}

static void scan_executable_memory(const struct mach_header_64 *header, const uint8_t *target, const uint32_t target_len, scan_memory_handler handler) {
    if (target == NULL || header == NULL) return;
    
    const struct section_64 *executable_section = getsectbynamefromheader_64(header, "__TEXT", "__text");
    
    if (executable_section == NULL) {
        return;
    }

    uint8_t *start_address = (uint8_t *) ((intptr_t) header + executable_section->offset);
    uint8_t *end_address = (uint8_t *) (start_address + executable_section->size);

    uint8_t *current = start_address;
    uint32_t index = 0;
    uint8_t current_target = 0;

    while (current < end_address) {
        current_target = target[index];

        if (current_target == *current++) {
            index++;
        } else {
            index = 0;
        }

        if (index == target_len) {
            index = 0;
            if (handler != NULL) {
                handler((intptr_t)(current - target_len));
            }
        }
    }
}

static void SVC80_handler(void *addr, DobbyRegisterContext *ctx) {
    
#if defined __arm64__ || defined __arm64e__
    int syscall_num = (int)ctx->general.regs.x16;
    if (syscall_num == 0) {
        syscall_num = (int)ctx->general.x[0];
        if (syscall_num == 26) {
            int request = (int)ctx->general.x[1];
            if (request == PT_DENY_ATTACH) {
                ctx->general.x[1] = 0;
            }
        }
    } else if(syscall_num == 26){
        int request = (int)ctx->general.x[0];
        if (request == PT_DENY_ATTACH) {
            ctx->general.x[0] = 0;
        }
    }
#endif
}

#define kPatchSVC 0

static void scan_svc_callback(const intptr_t target_addr){
    
#if kPatchSVC
    uint8_t nop[] = {
        0x1F, 0x20, 0x03, 0xD5  //NOP
    };
    
    DobbyCodePatch((void *)target_addr, nop, sizeof(nop));
#else
    
#if defined __arm64__ || defined __arm64e__
    dobby_enable_near_branch_trampoline();
    DobbyInstrument((void *)(target_addr), SVC80_handler);
    dobby_disable_near_branch_trampoline();
#endif
    
#endif
}

static const struct mach_header_64* get_main_image_header(){
    const struct mach_header_64 *header = NULL;
    uint32_t count = _dyld_image_count();
    for (int i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "DobbyExample") != NULL) {
            header = (const struct mach_header_64 *)_dyld_get_image_header(i);
            break;
        }
    }
    return header;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        log_set_level(0);
        DobbyHook((void *)dlopen, (dobby_dummy_func_t)fake_dlopen, (dobby_dummy_func_t *)&orig_dlopen);
        void *handle = dlopen("/usr/lib/system/libsystem_kernel.dylib", RTLD_LAZY);
        NSLog(@">>> handle: %lx", (intptr_t)handle);
        dlclose(handle);
        
        handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
        ptrace_ptr_t ptrace_ptr = dlsym(handle, "ptrace");
        DobbyHook((void *)ptrace_ptr, (dobby_dummy_func_t)fake_ptrace, (dobby_dummy_func_t *)&orig_ptrace);
        ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
        dlclose(handle);

#ifdef __arm64__
        
        const struct mach_header_64 *header = get_main_image_header();
        
        const uint8_t target[] = {
            0x01, 0x10, 0x00, 0xD4  //SVC #0x80
        };
        
        scan_executable_memory(header, target, sizeof(target), scan_svc_callback);
        
        asm volatile (
                      "mov x0, #26\n"
                      "mov x1, #31\n"
                      "mov x2, #0\n"
                      "mov x3, #0\n"
                      "mov x16, #0\n"
                      "svc #128\n"
                      );
        
#endif
        
        printf("Hello World!");
        

    }
    return 0;
}
