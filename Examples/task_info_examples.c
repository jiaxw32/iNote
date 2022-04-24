#include <stdio.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>


// ref: https://blog.lse.epita.fr/2017/03/14/playing-with-mach-os-and-dyld.html
static void list_dyld_images(void) {
    // Get DYLD task infos
    struct task_dyld_info dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    kern_return_t ret;
    ret = task_info(mach_task_self(),
                    TASK_DYLD_INFO,
                    (task_info_t)&dyld_info,
                    &count);
    if (ret != KERN_SUCCESS) {
        return;
    }
    
    // Get image array's size and address
    mach_vm_address_t image_infos = dyld_info.all_image_info_addr;
    struct dyld_all_image_infos *infos;
    infos = (struct dyld_all_image_infos *)image_infos;
    uint32_t image_count = infos->infoArrayCount;
    const struct dyld_image_info *image_array = infos->infoArray;
    
    for (int i = 0; i < image_count; ++i) {
        const struct dyld_image_info *info = &image_array[i];
        printf(">>> %s\n", info->imageFilePath);
    }
    
//    if (strstr(image->imageFilePath, "/System/Library") || strstr(image->imageFilePath, "/usr/lib/")) {
//        continue;
//    } else {
//        //return (char*)image->imageLoadAddress;
//        printf(">>> %s\n", image->imageFilePath);
//    }
}


static double get_memory_usage(){
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        int64_t memory_usage_in_byte = (int64_t) vmInfo.phys_footprint;
        return memory_usage_in_byte;
    } else {
        return -1;
    }
}

int main(int argc, char * argv[]) {
    list_dyld_images();
    int64_t memory_usage = get_memory_usage();
    printf("the used memory of current program is: %lld bytes\n", memory_usage);
    return 0;
}