//
//  ViewController.m
//  KVOExplorer
//
//  Created by jiaxw on 2020/6/4.
//  Copyright © 2020 jiaxw. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import "Person.h"


static NSArray *ClassMethodNames(Class c)
{
    NSMutableArray *array = [NSMutableArray array];
    
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for(i = 0; i < methodCount; i++)
        [array addObject: NSStringFromSelector(method_getName(methodList[i]))];
    free(methodList);
    
    return array;
}

static void printDescription(NSString *name, id obj){
    
    NSString *str = [NSString stringWithFormat:
                     @"%@: %@\n\tNSObject class: %s\n\tlibobjc class: %s\n\timplements methods: <%@>",
                     name,
                     obj,
                     class_getName([obj class]),
                     class_getName(object_getClass(obj)),
                     ClassMethodNames(object_getClass(obj))
                     ];
    printf("%s\n", [str UTF8String]);
}



@interface ViewController ()

@property (nonatomic,strong) Person *personA;

@property (nonatomic,strong) Person *personB;

@property (nonatomic,strong) Person *personAB;

@property (nonatomic,strong) Person *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Person *personA = [[Person alloc] init];
    Person *personB = [[Person alloc] init];
    Person *personAB = [[Person alloc] init];
    Person *person = [[Person alloc] init];
    self.personA = personA;
    self.personB = personB;
    self.personAB = personAB;
    self.person = person;
    
    //观察对象弱引用 observer
    [personA addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    [personB addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:nil];
    [personAB addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    [personAB addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:nil];
    
    //为私有变量添加观察者
    [personAB addObserver:self forKeyPath:@"_nickname" options:NSKeyValueObservingOptionNew context:nil];
    
    printDescription(@"person", person);
    printDescription(@"personA", personA);
    printDescription(@"personB", personB);
    printDescription(@"personAB", personAB);
    
    printf("Using NSObject methods, normal setName: is %p, overridden setName: is %p\n",
          [person methodForSelector:@selector(setName:)],
          [personA methodForSelector:@selector(setName:)]);
    
    printf("Using libobjc functions, normal setName: is %p, overridden setName: is %p\n",
          method_getImplementation(class_getInstanceMethod(object_getClass(person),
                                   @selector(setName:))),
          method_getImplementation(class_getInstanceMethod(object_getClass(personA),
                                   @selector(setName:))));
    
    
    personAB.name = @"John"; //通过属性赋值，会触发 KVO
    [personAB setValue:@"Jack" forKey:@"name"]; //使用 KVO 访问，也会触发 KVO
    
    [personAB setNickName:@"Air Jonh"]; //直接访问私有变量赋值, 不会触发 KVO
    [personAB setValue:@"Big Boss" forKey:@"_nickname"]; //使用 KVO，为私有变量赋值，会触发 KVO
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%s: %@", __func__, change);
}


- (void)dealloc {
    NSLog(@"%s", __func__);
    
    //不移除 KVO 不会崩溃，不会引起内存泄露
//    [self.personA removeObserver:self forKeyPath:@"name"];
    
//   personA 没有为属性 age 注册 observer，移除时会触发崩溃：
//    Cannot remove an observer <ViewController> for the key path "age" from <Person> because it is not registered as an observer. userInfo: (null)
//    [self.personA removeObserver:self forKeyPath:@"age"];
    
    [self.personB removeObserver:self forKeyPath:@"age"];
    [self.personAB removeObserver:self forKeyPath:@"name"];
    [self.personAB removeObserver:self forKeyPath:@"age"];
}
@end
