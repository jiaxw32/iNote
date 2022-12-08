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

// ref: https://stackoverflow.com/questions/677530/how-can-i-programmatically-get-the-mac-address-of-an-iphone
- (NSString *)getMacAddress{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0){
        errorFlag = @"if_nametoindex failure";
    } else {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0){
            errorFlag = @"sysctl mgmtInfoBase failure";
        } else {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL){
                errorFlag = @"buffer allocation failure";
                
            } else {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL){
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    NSLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}