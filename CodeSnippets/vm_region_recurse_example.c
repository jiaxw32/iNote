#include <stdlib.h>
#include <stdio.h>
#include <mach/mach.h>
#include <errno.h>
#include <unistd.h>
#include <sys/syslimits.h>

/*
ref links:
1. vm_region_recurse example: https://gist.github.com/wiggin15/0a4c51b5bc6c52e6e31e2234f88558ab
2. proc_regionfilename source code: https://opensource.apple.com/source/Libc/Libc-583/darwin/libproc.c
3. psutil: https://chromium.googlesource.com/external/github.com/giampaolo/psutil/+/release-1.2.0/psutil/_psutil_osx.c
*/

extern int proc_regionfilename(int pid, uint64_t address, void * buffer, uint32_t buffersize);

void vm_region_recurse_example(){
    kern_return_t krc = KERN_SUCCESS;
    vm_address_t address = 0;
    vm_size_t size = 0;
    uint32_t depth = 1;
    pid_t pid = getpid();
    char buf[PATH_MAX];
    char perms[8];
    int ret;
    while (1) {
        struct vm_region_submap_info_64 info;
        mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
        krc = vm_region_recurse_64(mach_task_self(), &address, &size, &depth, (vm_region_info_64_t)&info, &count);
        if (krc == KERN_INVALID_ADDRESS){
            break;
        }
        if (info.is_submap){
            depth++;
            printf("Recursing into %016lx-%016lx, size: %#lx\n", address, address+size, size);
        } else {
            memset(buf, 0, sizeof(buf));
            memset(perms, 0, sizeof(perms));
            
            sprintf(perms, "%c%c%c/%c%c%c",
                                (info.protection & VM_PROT_READ) ? 'r' : '-',
                                (info.protection & VM_PROT_WRITE) ? 'w' : '-',
                                (info.protection & VM_PROT_EXECUTE) ? 'x' : '-',
                                (info.max_protection & VM_PROT_READ) ? 'r' : '-',
                                (info.max_protection & VM_PROT_WRITE) ? 'w' : '-',
                                (info.max_protection & VM_PROT_EXECUTE) ? 'x' : '-');
            errno = 0;
            ret = proc_regionfilename(pid, address, buf, sizeof(buf));
            if (ret > 0) {
                printf("VM Region: %016lx to %016lx (depth=%d, size=%#lx), protection: %s, user_tag:%d, name:%s\n", address, (address+size), depth, size, perms, info.user_tag, buf);
            } else {
                printf("VM Region: %016lx to %016lx (depth=%d, size=%#lx), protection: %s, user_tag:%d, errno:%d, error msg: %s\n", address, (address+size), depth, size, perms, info.user_tag, errno, strerror(errno));
            }
            address += size;
        }
    }
}

int main(){
    vm_region_recurse_example();
    return 0;
}


/*
// output:
VM Region: 0000000100250000 to 0000000100254000 (depth=0, size=0x4000), protection: r-x/r-x, user_tag:0, name:/Users/jiaxw/Desktop/vm_region
VM Region: 0000000100254000 to 0000000100258000 (depth=0, size=0x4000), protection: r--/rw-, user_tag:0, name:/Users/jiaxw/Desktop/vm_region
VM Region: 0000000100258000 to 000000010025c000 (depth=0, size=0x4000), protection: r--/r--, user_tag:0, name:/Users/jiaxw/Desktop/vm_region
VM Region: 000000010025c000 to 0000000100264000 (depth=0, size=0x8000), protection: rw-/rwx, user_tag:73, name:/usr/lib/dyld
VM Region: 0000000100264000 to 0000000100268000 (depth=0, size=0x4000), protection: r--/r--, user_tag:0, name:/usr/lib/dyld
VM Region: 0000000100268000 to 000000010026c000 (depth=0, size=0x4000), protection: r--/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 000000010026c000 to 0000000100270000 (depth=0, size=0x4000), protection: rw-/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 0000000100270000 to 0000000100274000 (depth=0, size=0x4000), protection: ---/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 0000000100274000 to 000000010027c000 (depth=0, size=0x8000), protection: rw-/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 000000010027c000 to 0000000100280000 (depth=0, size=0x4000), protection: ---/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 0000000100280000 to 0000000100284000 (depth=0, size=0x4000), protection: ---/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 0000000100284000 to 000000010028c000 (depth=0, size=0x8000), protection: rw-/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 000000010028c000 to 0000000100290000 (depth=0, size=0x4000), protection: ---/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 0000000100290000 to 0000000100294000 (depth=0, size=0x4000), protection: ---/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 0000000100294000 to 000000010029c000 (depth=0, size=0x8000), protection: rw-/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 000000010029c000 to 00000001002a0000 (depth=0, size=0x4000), protection: ---/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 00000001002a0000 to 00000001002a4000 (depth=0, size=0x4000), protection: r--/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 00000001002a4000 to 00000001002a8000 (depth=0, size=0x4000), protection: r--/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 00000001002a8000 to 00000001002ac000 (depth=0, size=0x4000), protection: rw-/rwx, user_tag:1, name:/usr/lib/dyld
VM Region: 000000010032c000 to 000000010038c000 (depth=0, size=0x60000), protection: r-x/r-x, user_tag:0, name:/usr/lib/dyld
VM Region: 000000010038c000 to 000000010039c000 (depth=0, size=0x10000), protection: r--/rw-, user_tag:0, name:/usr/lib/dyld
VM Region: 000000010039c000 to 00000001003a0000 (depth=0, size=0x4000), protection: rw-/rw-, user_tag:0, name:/usr/lib/dyld
VM Region: 00000001003a0000 to 00000001003d8000 (depth=0, size=0x38000), protection: r--/r--, user_tag:0, name:/usr/lib/dyld
VM Region: 00000001003d8000 to 00000001004d8000 (depth=0, size=0x100000), protection: r--/rwx, user_tag:60, errno:22, msg: Invalid argument
VM Region: 000000011c600000 to 000000011c700000 (depth=0, size=0x100000), protection: rw-/rwx, user_tag:7, errno:22, msg: Invalid argument
VM Region: 000000011c800000 to 000000011d000000 (depth=0, size=0x800000), protection: rw-/rwx, user_tag:2, errno:22, msg: Invalid argument
VM Region: 000000016bbb0000 to 000000016f3b4000 (depth=0, size=0x3804000), protection: ---/rwx, user_tag:30, errno:22, msg: Invalid argument
VM Region: 000000016f3b4000 to 000000016fbb0000 (depth=0, size=0x7fc000), protection: rw-/rwx, user_tag:30, errno:22, msg: Invalid argument
Recursing into 0000000180000000-00000001d8000000, size: 0x58000000
VM Region: 0000000183590000 to 00000001d2ccc000 (depth=1, size=0x4f73c000), protection: r-x/r-x, user_tag:0, errno:22, msg: Invalid argument
VM Region: 00000001d4ccc000 to 00000001d78c4000 (depth=1, size=0x2bf8000), protection: r--/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 00000001d98c4000 to 00000001d98e8000 (depth=0, size=0x24000), protection: rw-/rw-, user_tag:35, errno:22, msg: Invalid argument
Recursing into 00000001d98e8000-00000001da000000, size: 0x718000
VM Region: 00000001d98e8000 to 00000001da000000 (depth=1, size=0x718000), protection: rw-/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 00000001da000000 to 00000001dc000000 (depth=1, size=0x2000000), protection: rw-/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 00000001dc000000 to 00000001dc528000 (depth=1, size=0x528000), protection: rw-/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 00000001dc528000 to 00000001ddc60000 (depth=0, size=0x1738000), protection: rw-/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 00000001ddc60000 to 00000001e0efc000 (depth=0, size=0x329c000), protection: r--/rw-, user_tag:0, errno:22, msg: Invalid argument
Recursing into 00000001e0efc000-00000001e2000000, size: 0x1104000
VM Region: 00000001e2efc000 to 00000001e2f28000 (depth=1, size=0x2c000), protection: r--/r--, user_tag:0, errno:22, msg: Invalid argument
VM Region: 00000001e2f28000 to 0000000207bb8000 (depth=1, size=0x24c90000), protection: r-x/r-x, user_tag:0, errno:22, msg: Invalid argument
VM Region: 0000000209bb8000 to 000000020a930000 (depth=1, size=0xd78000), protection: r--/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 000000020c930000 to 000000020e000000 (depth=1, size=0x16d0000), protection: rw-/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 000000020e000000 to 000000020f0a8000 (depth=1, size=0x10a8000), protection: rw-/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 000000020f0a8000 to 000000020fdac000 (depth=0, size=0xd04000), protection: rw-/rw-, user_tag:0, errno:22, msg: Invalid argument
VM Region: 000000020fdac000 to 0000000210f78000 (depth=0, size=0x11cc000), protection: r--/rw-, user_tag:0, errno:22, msg: Invalid argument
Recursing into 0000000210f78000-0000000212000000, size: 0x1088000
VM Region: 0000000212f78000 to 000000023a76c000 (depth=1, size=0x277f4000), protection: r--/r--, user_tag:0, errno:22, msg: Invalid argument
VM Region: 0000000fc0000000 to 0000001000000000 (depth=0, size=0x40000000), protection: ---/---, user_tag:0, errno:22, msg: Invalid argument
VM Region: 0000001000000000 to 0000007000000000 (depth=0, size=0x6000000000), protection: ---/---, user_tag:0, errno:22, msg: Invalid argument
VM Region: 0000600000000000 to 0000600008000000 (depth=0, size=0x8000000), protection: rw-/rwx, user_tag:11, errno:22, msg: Invalid argument
VM Region: 0000600008000000 to 0000600010000000 (depth=0, size=0x8000000), protection: rw-/rwx, user_tag:11, errno:22, msg: Invalid argument
VM Region: 0000600010000000 to 0000600018000000 (depth=0, size=0x8000000), protection: rw-/rwx, user_tag:11, errno:22, msg: Invalid argument
VM Region: 0000600018000000 to 0000600020000000 (depth=0, size=0x8000000), protection: rw-/rwx, user_tag:11, errno:22, msg: Invalid argument
*/