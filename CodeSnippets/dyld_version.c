//
//  dyld_version.c
//  CodeSnippets
//
//  Created by jiaxw on 2021/5/1.
//

#include <mach-o/dyld_images.h>

/*
 Reference：
 * Playing with Mach-O binaries and dyld: https://blog.lse.epita.fr/2017/03/14/playing-with-mach-os-and-dyld.html
 * dyld source code：https://opensource.apple.com/source/dyld/
 */

/// get dyld lib version
const char* dyldVersion(void);

const char* dyldVersion(){
    // Get DYLD task infos
    struct task_dyld_info dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    kern_return_t ret;
    ret = task_info(mach_task_self_,
                    TASK_DYLD_INFO,
                    (task_info_t)&dyld_info,
                    &count);
    if (ret != KERN_SUCCESS) {
            return NULL;
    }
    
    // Get dyld version
    mach_vm_address_t image_infos = dyld_info.all_image_info_addr;
    struct dyld_all_image_infos *infos;
    infos = (struct dyld_all_image_infos *)image_infos;
    const char *version = infos->dyldVersion;
    return version;
}
