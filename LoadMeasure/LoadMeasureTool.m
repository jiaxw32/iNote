//
//  LoadMeasureTool.m
//  LoadMeasure
//
//  Created by jiaxw on 2021/1/8.
//

#import "LoadMeasureTool.h"

@implementation LoadMeasureTool

+ (void)load{
    printf(">>> LoadMeasureTool %s method called.\n", __func__);
}

@end

__attribute__((constructor)) static void ctorLoadMeasureTool(){
    printf(">>> LoadMeasure %s function called.\n", __func__);
}
