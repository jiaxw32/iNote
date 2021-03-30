//
//  main.m
//  BlockAnalyze
//
//  Created by jiaxw on 2021/2/22.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef void(^blk_t)(void);

static Class _BlockClass(void);

// Block 继承链：
// __NSMallocBlock -> NSBlock -> NSObject
// __NSStackBlock -> NSBlock -> NSObject
// __NSGlobalBlock__ -> __NSGlobalBlock -> NSBlock -> NSObject

/// 获取 block 基类 NSBlock，摘自 FBRetainCycleDetector 源码
static Class _BlockClass() {
  static dispatch_once_t onceToken;
  static Class blockClass;
  dispatch_once(&onceToken, ^{
    void (^testBlock)(void) = [^{} copy];
    blockClass = [testBlock class];
      NSLog(@"%@", blockClass);
    while(class_getSuperclass(blockClass) && class_getSuperclass(blockClass) != [NSObject class]) {
      blockClass = class_getSuperclass(blockClass);
        NSLog(@"%@", blockClass);
    }
  });
  return blockClass;
}


/// 判断一个对象是否为 block
/// @param object 待检测对象指针
BOOL CheckObjectIsBlock(void *object) {
  Class blockClass = _BlockClass();
  
  Class candidate = object_getClass((__bridge id)object);
  return [candidate isSubclassOfClass:blockClass];
    
}

#pragma mark - MYClass

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

#pragma mark - test

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

NSArray* testBlockArray01(){
    /*
     可变参数，只会 copy 第一个，第一个 block 存储在堆上，其他 block 存储在栈上。作用域结束调用 release，就触发崩溃。
     
     + (instancetype)arrayWithObjects:(ObjectType)firstObj, ... ;
     
     第一个类型是明确的，显式指定转为对象，编译器才会调用 block 的 copy/retain。变参是非显式指定的，所以调用前编译不知道他要转成对象，调用时 NSArray 不知道是个 stackblock。
     变参的类型默认是 int 的，所 objc_msgsend 直接禁用了变参版本
     */
    int i = 0;
    NSArray *arr = [NSArray arrayWithObjects:
                    ^(){ printf("%d", i); }, // __NSMallocBlock 分配在堆上
                    ^(){ printf("%d", i); }, // __NSStackBlock__ 分配在栈上
                    ^(){ printf("%d", i); }, // __NSStackBlock__ 分配在栈上
                    nil];
    return arr;
}

NSArray* testBlockArray02(){
    int i = 0;
    NSArray *arr = [NSArray arrayWithObjects:
                    [^(){ printf("%d", i); } copy], // __NSMallocBlock 分配在堆上
                    [^(){ printf("%d", i); } copy], // __NSMallocBlock 分配在堆上
                    [^(){ printf("%d", i); } copy], // __NSMallocBlock 分配在堆上
                    nil];
    return arr;
}

NSArray* testBlockArray03(){
    int i = 0;
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObject:^(){ printf("%d", i); }]; // __NSMallocBlock 分配在堆上
    [arr addObject:^(){ printf("%d", i); }]; // __NSMallocBlock 分配在堆上
    [arr addObject:^(){ printf("%d", i); }]; // __NSMallocBlock 分配在堆上
    
    return arr;
}

NSArray* testBlockArray04(){
    NSArray *arr = [NSArray arrayWithObjects:
                    ^(){ printf("Objective-C"); }, // __NSGlobalBlock
                    ^(){ printf("C++"); }, // __NSGlobalBlock
                    ^(){ printf("Swift"); }, // __NSGlobalBlock
                    nil];
    return arr;
}


#pragma mark - main

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        testBlockAllocation();
        
        testBlockCaptureVar();
        
        {
            MYClass *obj = [[MYClass alloc] init];
            NSLog(@"%@", obj);
        }
        
//        {
//            NSArray *arr01 = testBlockArray01();
//            NSLog(@"%@", arr01);
//            // 作用域结束时触发 EXC_BAD_ACCESS 异常
//        }
        
        testBlockArray03();
        
        testBlockArray04();

        printf("Hello world!");
        
    }
    return 0;
}
