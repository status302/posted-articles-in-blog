//
//  CIContext+vs.m
//  QRCodeDemo
//
//  Created by 程庆春 on 2017/2/21.
//  Copyright © 2017年 Qiun Cheng. All rights reserved.
//

#import "CIContext+vs.h"

@implementation CIContext (vs)
+ (CIContext *)vs_contextWithOptions:(NSDictionary<NSString *,id> *)options {
    return [CIContext contextWithOptions:options];
}
@end


