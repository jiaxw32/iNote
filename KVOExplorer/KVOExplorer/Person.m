//
//  Person.m
//  KVOExplorer
//
//  Created by jiaxw on 2020/6/4.
//  Copyright © 2020 jiaxw. All rights reserved.
//

#import "Person.h"

#define kEnableKVONotifying_Person 0

#define kTriggerKVOManual 1

@implementation Person


- (void)setNickName:(NSString *)nickname{
#if kTriggerKVOManual
    //手动触发 KVO
    [self willChangeValueForKey:@"_nickname"];
    _nickname = nickname;
    [self didChangeValueForKey:@"_nickname"];
#else
    //直接为私有变量赋值不会触发 KVO；使用 KVO 方式为私有变量赋值是，可以触发 KVO
    _nickname = nickname;
#endif

}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end


#if kEnableKVONotifying_Person

//手动为 Person 类，定个一个 NSKVONotifying_Person 类时，会导致系统无法动态创建 NSKVONotifying_Person 类，KVO 失效

@interface NSKVONotifying_Person : NSObject

@end

@implementation NSKVONotifying_Person


@end

#endif
