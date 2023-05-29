//
//  ViewController.m
//  LIEFIntegration
//
//  Created by jiaxw on 2023/5/29.
//

#import "ViewController.h"
#include <LIEF/MachO.hpp>
#include <LIEF/logging.hpp>
#include <mach-o/dyld.h>

#include <iostream>
#include <iomanip>

using namespace LIEF::MachO;

/*
 0: 参考集成文档：https://lief-project.github.io/doc/latest/installation.html
 1. 执行下面命令：
 pkg-config --cflags./LIEF-0.13.0-iOS-aarch64/lib/pkgconfig/LIEF.pc
 Output：-I/usr/local/include
 2. 将输出结果添加到 Build Settings -> Other C Flags 选项中
 3. 以 Release 模式运行，Debug 与 FLAGS::DEBUG 枚举定义冲突
 */

void dump_macho() {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    std::string workdir([docPath UTF8String]);
    
    std::string logfile = workdir + "/lief.log";
    
    std::cout << "log file:" << logfile << "\n";
    
    // 默认日志路径 "/tmp/lief.log", 非越狱设备，没有写入权限，自定义日志路径
    LIEF::logging::set_path(logfile);
    
    LIEF::logging::set_level(LIEF::logging::LOGGING_LEVEL::LOG_DEBUG);
    
    const uintptr_t base = reinterpret_cast<uintptr_t>(_dyld_get_image_header(0));
    if (base == 0) {
        return;
    }
    
    std::cout << "Base address: 0x" << std::hex << base << "\n";
    std::unique_ptr<FatBinary> binaries = Parser::parse_from_memory(base);
    if (binaries == nullptr || binaries->empty()) {
        std::cerr << "Parsing failed" << '\n';
    }
    std::cout << "Parsing Done!" << "\n";
    
    std::string binfile = workdir + "/mem_rewrite.bin";
    for (Binary& bin : *binaries) {
        bin.write(binfile);
    }
    
    std::cout << "dump macho Done!" << "\n";
}

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dump_macho();
    });
}


@end
