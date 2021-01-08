//
//  LoadMeasureBaseTool.m
//  LoadMeasure
//
//  Created by jiaxw on 2021/1/8.
//

#import "LoadMeasureBaseTool.h"

@implementation LoadMeasureBaseTool

+ (void)load{
    printf(">>> LoadMeasureTool %s method called.\n", __func__);
}

@end

__attribute__((constructor)) static void ctorLoadMeasureBaseTool(){
    printf(">>> LoadMeasure %s function called.\n", __func__);
}

