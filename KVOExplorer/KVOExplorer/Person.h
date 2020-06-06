//
//  Person.h
//  KVOExplorer
//
//  Created by jiaxw on 2020/6/4.
//  Copyright © 2020 jiaxw. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject{
    NSString *_nickname;
}

@property (nonatomic,copy) NSString *name;


@property (nonatomic,assign) NSInteger age;

- (void)setNickName:(NSString *)nickname;

@end

NS_ASSUME_NONNULL_END
