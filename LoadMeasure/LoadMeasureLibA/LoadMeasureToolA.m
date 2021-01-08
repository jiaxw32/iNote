//
//  LoadMeasureToolA.m
//  LoadMeasureLibA
//
//  Created by jiaxw on 2021/1/8.
//

#import "LoadMeasureToolA.h"

@implementation LoadMeasureToolA

+ (void)load{
    printf(">>> LoadMeasureLibA %s method called.\n", __func__);
}

@end

__attribute__((constructor)) static void ctorLoadMeasureToolA(){
    printf(">>> LoadMeasureLibA %s function called.\n", __func__);
}
