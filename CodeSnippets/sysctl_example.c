#include <stdio.h>
#include <errno.h>
#include <sys/sysctl.h>

// ref: https://www.coredump.gr/articles/ios-anti-debugging-protections-part-2/
static int is_debugger_present(void){
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    info.kp_proc.p_flag = 0;

    int name[4];
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    if(sysctl(name, sizeof(name)/sizeof(*name), &info, &info_size, NULL, 0) != 0) {
        printf("sysctl: %s\n", strerror(errno));
        return 0;
    }
    return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

static void kern_osrelease_example(){
    size_t len;
    int mib[] = {CTL_KERN, KERN_OSRELEASE};
    sysctl(mib, sizeof mib / sizeof(*mib), NULL, &len, NULL, 0);

    char *kernelVersion = (char *)malloc(sizeof(char)*len);
    sysctl(mib, sizeof mib / sizeof(int), kernelVersion, &len, NULL, 0);
    
    printf("kernel version: %s\n", kernelVersion);
    free(kernelVersion);
}

static void cpu_number_example(){
    int mib[2] = {CTL_HW, HW_NCPU};
    int numcpu = 0;
    size_t numcpu_size;

    sysctl (mib, sizeof(mib) / sizeof(int), &numcpu, &numcpu_size, NULL, 0);
    printf("cpu number: %d\n", numcpu);
}