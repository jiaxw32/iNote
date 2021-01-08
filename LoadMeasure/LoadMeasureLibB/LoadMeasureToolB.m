//
//  LoadMeasureToolB.m
//  LoadMeasureLibB
//
//  Created by jiaxw on 2021/1/8.
//

#import "LoadMeasureToolB.h"

@implementation LoadMeasureToolB

+ (void)load{
    printf(">>> LoadMeasureLibB %s method called.\n", __func__);
}

@end

__attribute__((constructor)) static void ctorLoadMeasureToolB(){
    printf(">>> LoadMeasureLibB %s function called.\n", __func__);
}
