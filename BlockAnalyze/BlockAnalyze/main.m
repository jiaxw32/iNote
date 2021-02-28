//
//  main.m
//  BlockAnalyze
//
//  Created by jiaxw on 2021/2/22.
//

#import <Foundation/Foundation.h>

typedef void(^blk_t)(void);

@interface MYClass : NSObject{
    NSString *_name;
}

@property (nonatomic, copy) NSString *code;

@property (nonatomic,copy) blk_t blk1;

@end

@implementation MYClass

- (instancetype)init{
    if (self = [super init]) {
        
        // 错误写法，Block 会捕获 self，导致循环引用
//        _blk1 = ^(){
//            NSLog(@"%@", _name);
//        };
        
        /*
         struct __block_impl {
           void *isa;
           int Flags;
           int Reserved;
           void *FuncPtr;
         };


         struct __MYClass__init_block_impl_0 {
           struct __block_impl impl;
           struct __MYClass__init_block_desc_0* Desc;
           MYClass *self;
           __MYClass__init_block_impl_0(void *fp, struct __MYClass__init_block_desc_0 *desc, MYClass *_self, int flags=0) : self(_self) {
             impl.isa = &_NSConcreteStackBlock;
             impl.Flags = flags;
             impl.FuncPtr = fp;
             Desc = desc;
           }
         };

         static void __MYClass__init_block_func_0(struct __MYClass__init_block_impl_0 *__cself) {
           MYClass *self = __cself->self; // bound by copy
             NSLog((NSString *)&__NSConstantStringImpl__var_folders_xr_3w5bs_f52rl80kt8ymmdkxgc0000gn_T_main_bd9026_mi_0, (*(NSString **)((char *)self + OBJC_IVAR_$_MYClass$_name)));
         }
         */
        
        blk_t blk2 = ^(){
            NSLog(@"%@", _name);
        };
        
        // 正确写法
//        __weak typeof(self) weakSelf = self;
//        _blk1 = ^(){
//            __strong typeof(weakSelf) strongSelf = weakSelf;
//            NSLog(@"%@", strongSelf->_name);
//        };
    }
    return self;
}

- (void)dealloc{
    NSLog(@">>> %s\n", __func__);
}

@end

int g_var1 = 0;

static int g_var2 = 0;

void testBlockAllocation(){
    int var0 = 0;
    
    // __unsafe_unretained 修饰，block 分配在栈上 -> __NSStackBlock__
    __unsafe_unretained blk_t blk0 = ^(){
        NSLog(@"var0 = %@", @(var0));
    };
    
    // 默认 strong 修饰，block 分配在堆上 -> __NSMallocBlock__
    blk_t blk1 = ^(){
        NSLog(@"var1 = %@", @(var0));
    };
    
    // block 未捕获局部变量，全局类型的 Block -> __NSGlobalBlock__
    blk_t blk2 = ^(){
        NSLog(@"%s", __func__);
    };
    
    // 执行 copy 操作后，block 拷贝到堆上 -> __NSStackBlock__
    blk_t blk4 = [blk0 copy];
    
    blk0();
    blk1();
    blk2();
    blk4();
}

void printVar(int var1, int var2, int var3, int var4){
    printf("global var1 = %d\nglobal static var2 = %d\nauto var3 = %d\nstatic local var4 = %d\n", var1, var2, var3, var4);
}

void testBlockCaptureVar(){
    
    int var3 = 0; // 局部变量，值传递
    static int var4 = 0; // 静态变量，引用传递
    NSLog(@"before blcok declaration:");
    printVar(g_var1, g_var2, var3, var4);
    
    blk_t loc_blk = ^(){
        NSLog(@"blk capture var value:");
        // g_var1、g_var2 全局变量，block 不会捕获，可以直接访问
        printVar(g_var1, g_var2, var3, var4);
        
        NSLog(@"increment var inside block:");
        printVar(++g_var1, ++g_var2, var3, ++var4);
    };
    
    g_var1++;
    g_var2++;
    var3++;
    var4++;
    NSLog(@"after var increment:");
    printVar(g_var1, g_var2, var3, var4);
    
    loc_blk();
    
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        testBlockAllocation();
        
        testBlockCaptureVar();
        
        {
            MYClass *obj = [[MYClass alloc] init];
            NSLog(@"%@", obj);
        }
    }
    return 0;
}
