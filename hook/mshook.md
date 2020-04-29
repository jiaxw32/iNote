# MSHook 框架使用

## OC 方法

使用 `MSHookMessageEx` hook OC 方法

```C++
#import <substrate.h>

// `-[MicroMessengerAppDelegate application:didFinishLaunchingWithOptions:]

BOOL (*original_didFinishLaunching)(id self, SEL _cmd, id application, id options);

BOOL replaced_didFinishLaunching(id self, SEL _cmd, id application, id options){
    NSLog(@">>> app didFinishLaunchingWithOptions");
    return original_didFinishLaunching(self, _cmd, application, options);
}

static __attribute__((constructor)) void cy_oc(){
    MSHookMessageEx(NSClassFromString(@"MicroMessengerAppDelegate"), @selector(application:didFinishLaunchingWithOptions:), (IMP)&replaced_didFinishLaunching, (IMP*)&original_didFinishLaunching);
}
```

## C/C++ 方法

使用 `MSHookFunction` hook 形如 sub_xxx 无符号匿名方法

```C++
#import <substrate.h>
#include <mach-o/dyld.h>

//mach-o 文件中匿名函数 sub_10004c724

int64_t (*orig_func)(int64_t,int64_t,int64_t,int64_t,int64_t,BOOL);

int64_t replaced_func(int64_t arg1,int64_t arg2,int64_t arg3, int64_t arg4, int64_t arg5, BOOL arg6){
    NSLog(@">>> replaced function execute, code: %lld, arg2: %lld , arg3: %lld,", arg1, arg2, arg3);
    return orig_func(arg1, arg2, arg3, arg4, arg5, arg6);
}

static __attribute__((constructor)) void cy_sub(){
    __uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    __uint64_t addr = 0x10004c724;
    __uint64_t symbolAddress = addr + slide;
    NSLog(@">>> image slide address: %#llx, sub symbol address: %#llx\n", slide,  symbolAddress);
    MSHookFunction((void *)symbolAddress, (void *)&replaced_func, (void **)&orig_func);

    Dl_info info;
    dladdr((void *)symbolAddress, &info);
    NSLog(@">>> base address: %#llx, image file: %s", (long long)info.dli_fbase, info.dli_fname);
}
```

## 参考链接

* [Cydia Substrate 介绍](https://iphonedevwiki.net/index.php/Cydia_Substrate)
* [Cyida 官方文档](http://www.cydiasubstrate.com/id/264d6581-a762-4343-9605-729ef12ff0af/)
* [Cydia MSHookMessageEx](http://www.cydiasubstrate.com/api/c/MSHookMessageEx/)