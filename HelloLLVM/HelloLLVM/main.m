//
//  main.c
//  HelloLLVM
//
//  Created by jiaxw on 2021/11/3.
//

#include <stdio.h>
#include <mach-o/dyld.h>
#import <Foundation/Foundation.h>

/*
 -Xclang -load -Xclang libSkeletonPass.so
 -Xclang -load -Xclang LLVMWObfuscation.dylib -mllvm -enable-indibran
 -Xclang -load -Xclang libHikari.so -flegacy-pass-manager
 -Xclang -load -Xclang libHikari.so -mllvm -enable-allobf
 

 -enable-bcfobf Enable Bogus Control Flow
 -enable-cffobf Enable Control Flow Flattening
 -enable-splitobf Enable Basic Block Spliting
 -enable-subobf Enable Instruction Substitution
 -enable-acdobf Enable AntiClassDump Mechanisms
 -enable-indibran Enable Register-Based Indirect Branching
 -enable-strcry Enable String Encryption
 -enable-funcwra Enable Function Wrapper
 -enable-fco Enable FunctionCallObfuscate. (See HERE for full usage)
 
 -mllvm -enable-allobf
 -mllvm -enable-bcfobf
 -mllvm -enable-indibran -mllvm -enable-strcry
 -mllvm -enable-indibran -mllvm split_num=2
 
 bcf, fla, fco, fw, indibr, split, strenc, sub
 */

int sum(int a, int b);
int multiply(int a, int b);
void swap(int *a, int *b);
int max(int a, int b) __attribute__((annotate("sub,indibr")));
int main(void) __attribute__((annotate("strenc,indibr")));

BOOL gs_checkEnv(void);

int sum(int a, int b) {
    return a + b;
}

int multiply(int a, int b) {
    return a * b;
}

void swap(int *a, int *b){
    int temp;
    temp = *a;
    *a = *b;
    *b = temp;
}

int max(int a, int b){
    return a >= b ? a : b;
}

BOOL check_env(void) __attribute__((annotate("strenc, fco, indibr"))) {
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    if (NULL != env) {
        return YES;
    }
    return NO;
}

BOOL check_dylib(void) __attribute__((annotate("strenc, fco, indibr"))) {
    int count = _dyld_image_count();
    if (count > 0) {
        for (int i = 0; i < count; i++) {
            const char * dyld = _dyld_get_image_name(i);
            if (strstr(dyld, "DynamicLibraries")) {
                return YES;
            }
        }
    }
    return NO;
}

BOOL combine_check(void) __attribute__((annotate("fco"))) {
    return check_env() || check_dylib();
}

#pragma mark - MYClass

@interface MYClass : NSObject

@end

@implementation MYClass

extern void hikari_strenc(void);
extern void hikari_nostrenc(void);

extern void hikari_bcf(void);
extern void hikari_nobcf(void);

extern void hikari_indibr(void);
extern void hikari_nodibr(void);

extern void hikari_fco(void);
extern void hikari_nofco(void);

- (void)foo{
//    hikari_nobcf();
    NSLog(@"call method: %s", __func__);
}

- (void)bar{
//    hikari_strenc();
//    hikari_indibr();
    NSLog(@"call method: %s", __func__);
}

// 混淆正常
+ (BOOL)checkEnv{
    hikari_fco();
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    if (NULL != env) {
        return YES;
    }
    return NO;
}

// 混淆正常
+ (BOOL)checkDylib{
    hikari_fco();
    int count = _dyld_image_count();
    for (int i = 0; i < count; i++) {
        const char * name = _dyld_get_image_name(i);
        if (strstr(name, "/Library/MobileSubstrate/DynamicLibraries")) {
            return YES;
        }
    }
    return NO;
}

// 混淆正常
+ (BOOL)test01{
    return check_env();
}

// 混淆正常
+ (BOOL)test02{
    return check_dylib();
}

// 混淆正常
+ (BOOL)test03{
    return check_env() || check_dylib();
}

//+ (BOOL)test04{
//    // 混淆报错
////    return [self test01] || [self test02];
//
//    BOOL ret = [self test01];
//    if (ret) {
//        return ret;
//    } else {
//        return [self test02];
//    }
//}


//+ (BOOL)test05{
//    // 混淆报错
////    return [self checkEnv] || [self checkDylib];
//
//    BOOL ret = [self checkEnv];
//    return ret ?: [self checkDylib];
//}

@end


#pragma mark - main

int main() {
    // insert code here...
    printf("Hello, World!\n");
    
    int a = 1;
    int b = 2;
    
    int c = sum(a, b);
    printf("%d plus %d is equal to %d\n", a, b, c);

    int d = multiply(a, b);
    printf("%d multiplied by %d equal to %d\n",a, b, d);

    swap(&a, &b);
    printf("a = %d, b = %d\n", a, b);
    
    int e = max(a, b);
    printf("max value of (%d, %d) is %d\n", a, b, e);
    
    return 0;
}
