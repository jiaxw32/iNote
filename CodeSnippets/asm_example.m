#import <Foundation/Foundation.h>

/*
* [ARM GCC Inline Assembler Cookbook](http://www.ethernut.de/en/documents/arm-inline-asm.html)
* [How to Use Inline Assembly Language in C Code](https://dmalcolm.fedorapeople.org/gcc/2015-08-31/rst-experiment/how-to-use-inline-assembly-language-in-c-code.html#extended-asm-assembler-instructions-with-c-expression-operands)
*/

// [MonkeyDev] AntiAntiDebug.m
int my_syscall(int code, va_list args){
    int request;
    va_list newArgs;
    va_copy(newArgs, args);
    if(code == 26){
#ifdef __LP64__
        __asm__(
                "ldr %w[result], [fp, #0x10]\n"
                : [result] "=r" (request)
                :
                :
                );
#else
        request = va_arg(args, int);
#endif
        if(request == 31){
            NSLog(@"[AntiAntiDebug] - syscall call ptrace, and request is PT_DENY_ATTACH");
            return 0;
        }
    }
    return orig_syscall(code, newArgs);
}

// [SnapHide] https://github.com/AeonLucid/SnapHide
%hookf(id, objc_getClass, const char* name) {
    int64_t link_register = 0;
    __asm ("MOV %[output], LR" : [output] "=r" (link_register));

    if (is_in_process(link_register) == 0) {
        for (int i = 0; i < classCount; i++) {
            if (strstr(name, classes[i]) != 0) {
                // NSLog(@"[SnapHide] > Denied objc_getClass of %s, was actually %p", name, %orig(name));
                return 0;
            }
        }
    }

    return %orig(name);
}
