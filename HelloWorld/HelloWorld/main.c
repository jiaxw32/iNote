//
//  main.c
//  HelloWorld
//
//  Created by jiaxw on 2021/1/15.
//

#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach/mach.h>
#include <sys/syslimits.h>
#include <libgen.h>
#include <unistd.h>
#include "zlog.h"
#include <sys/time.h>
#import <sys/sysctl.h>

void identify_function_ptr( void *ptr)  {
    Dl_info info;
    int rc = dladdr(ptr, &info);
    
    if (!rc)  {
        printf("Problem retrieving program information for %llx:  %s\n", (int64_t)ptr, dlerror());
    }
    printf("lib path: %s\n", info.dli_fname);
    printf("base address : %llx\n", (int64_t)info.dli_fbase);
    
    
    
    
}

int max(int num1, int num2);

int max(int num1, int num2){
    
    int64_t link_register = 0;
    __asm ("MOV %[output], LR" : [output] "=r" (link_register));
    
    printf("%#llx\n", link_register);
    
    identify_function_ptr((void *)link_register);
    
    
    if (num1 >= num2) {
        return num1;
    } else {
        return num2;
    }
}

char app_dir[PATH_MAX] = {0};

const char* get_main_bundle_path(void);

const char* get_main_bundle_path(){
    if (strlen(app_dir) == 0) {
        char file[PATH_MAX];
        uint32_t size = sizeof(file);
        if(_NSGetExecutablePath(file, &size) == 0){
            strcpy(app_dir, dirname(file));
        }
    }
    
    return app_dir;
}


char home_dir[PATH_MAX] = {0};


const char* get_basename(const char *path){
    static char name[PATH_MAX];
    
    if (path == NULL) {
        return NULL;
    }
    
    size_t len = strlen(path);
    if (len == 0) {
        return NULL;
    }

    size_t idx = len -1;
    while (idx >= 0) {
        if(path[idx] == '/'){
            break;
        }
        --idx;
    }
    
    if (idx >= 0 && idx < (len -1)) {
        strcpy(name, &path[idx + 1]);
        return name;
    } else {
        return path;
    }
}

int test_vm_region(void){
    void *handle = dlopen("/usr/lib/system/libsystem_kernel.dylib", RTLD_LAZY);
    void *ptr = dlsym(handle, "stat");
    if (ptr != NULL) {
        vm_address_t addr = (vm_address_t)ptr;
        vm_size_t vmsize;
        vm_region_basic_info_data_64_t info;
        mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
        vm_region_flavor_t flavor = VM_REGION_BASIC_INFO_64;
        mach_port_t object;
        kern_return_t kr = vm_region_64(mach_task_self(), &addr, &vmsize, flavor, (vm_region_info_t)&info, &info_count, &object);
        if (kr != KERN_SUCCESS) {
            return 0 ;
        } else {
            
#define VM_PROT_NONE    ((vm_prot_t) 0x00)

#define VM_PROT_READ    ((vm_prot_t) 0x01)      /* read permission */
#define VM_PROT_WRITE   ((vm_prot_t) 0x02)      /* write permission */
#define VM_PROT_EXECUTE ((vm_prot_t) 0x04)      /* execute permission */
            return info.protection;
        }
    }
    return 0;
}


static void sysctl_example_1(){
    int name[2] = {CTL_HW, HW_USERMEM};
     int usermem_bytes;
     size_t size = sizeof(usermem_bytes);
     sysctl( name, 2, &usermem_bytes, &size, NULL, 0 );
    printf(">>> user memory: %d\n", usermem_bytes / 1024 / 1024);
}

static void sysctl_example_2(){
    unsigned int physmem;
    size_t len = sizeof physmem;
    static int mib[2] = { CTL_HW, HW_PHYSMEM };

    if (sysctl (mib, 2, &physmem, &len, NULL, 0) == 0){
        printf(">>> physical memory: %d\n", physmem / 1024 / 1024 / 1024);
    }
}

static void sysctl_example_3(){
    size_t len;
    int mib[] = {CTL_KERN, KERN_OSRELEASE};
    sysctl(mib, sizeof mib / sizeof(int), NULL, &len, NULL, 0);

    char *kernelVersion = (char *)malloc(sizeof(char)*len);
    sysctl(mib, sizeof mib / sizeof(int), kernelVersion, &len, NULL, 0);
    
    printf("kernel version: %s\n", kernelVersion);
    
    free(kernelVersion);
}

static void sysctl_example_4(){
    size_t numcpu_size;
    int mib[2] = {CTL_HW, HW_NCPU};

    int numcpu = 0;
    numcpu_size = sizeof (numcpu);

    sysctl (mib, sizeof(mib) / sizeof(int), &numcpu, &numcpu_size, NULL, 0);
    printf("cpu number: %d\n", numcpu);
}

int main(int argc, const char * argv[]) {    
    printf("size of uuid_t: %ld\n", sizeof(uuid_t));
    
    
    sysctl_example_1();
    
    sysctl_example_2();
    
    sysctl_example_3();
    
    sysctl_example_4();
    
    const char *dir = getenv("HOME");
    if (strlen(dir) > 8) {  // /private
        strcpy(home_dir, &dir[8]);
    }
    

    struct timeval tv;
    gettimeofday(&tv,NULL);
    __darwin_time_t t = tv.tv_sec; // seconds
    
    printf("%ld", t);
    
    
    printf("%s\n", get_main_bundle_path());
    
    printf("Hello, World!\n");
    
    int a = arc4random() % 100;
    int b = arc4random() % 100;
    int c = max(a, b);
    printf("%d\n", c);
    
    const struct mach_header_64 *header = (const struct mach_header_64*) _dyld_get_image_header(0);
    printf("mach headers adress: %#llx\n", (int64_t)header);
    const struct section_64 *executable_section = getsectbynamefromheader_64(header, "__TEXT", "__text");

    uint64_t start_address = (uint64_t) ((intptr_t) header + executable_section->offset);
    uint64_t end_address = (uint64_t) (start_address + executable_section->size);
    
    
    printf("begin adress: %#llx, end adress: %#llx.\n", start_address ,end_address);
    
    
    extern char **environ;
    //...

    int i = 0;
    while(environ[i]) {
      printf("%s\n", environ[i++]); // prints in form of "variable=value"
    }
    
    const char *path = "/private/var/containers/Bundle/Application/54384453-8031-4C84-9998-90484651B50F/imeituan.app/imeituan";
    const char *ret = get_basename(path);
    printf("%s", ret);
    
//    path = "/var/mobile/";
//    ret = get_basename(path);
//    printf("%s", ret);
//
//    path = "/";
//    ret = get_basename(path);
//    printf("%s", ret);
//
//    path = "";
//    ret = get_basename(path);
//    printf("%s", ret);
    
    path = NULL;
    ret = get_basename(path);
    printf("%s", ret);
    
    test_vm_region();

    
    return 0;
}
