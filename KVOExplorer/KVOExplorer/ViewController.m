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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Person *personA = [[Person alloc] init];
    Person *personB = [[Person alloc] init];
    Person *personAB = [[Person alloc] init];
    Person *person = [[Person alloc] init];
    
    [personA addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    [personB addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:NULL];
    [personAB addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    [personAB addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:NULL];
    
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
    
    
    [personAB setName:@"John"];
    [personAB setAge:30];
    
    [personA removeObserver:self forKeyPath:@"name"];
    [personB removeObserver:self forKeyPath:@"age"];
    [personAB removeObserver:self forKeyPath:@"name"];
    [personAB removeObserver:self forKeyPath:@"age"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%@", change);
}


- (void)dealloc {
    
}
@end
