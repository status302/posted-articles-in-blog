//
//  CIContext+vs.h
//  QRCodeDemo
//
//  Created by 程庆春 on 2017/2/21.
//  Copyright © 2017年 Qiun Cheng. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface CIContext (vs)
+ (CIContext * _Nonnull)vs_contextWithOptions:(nullable NSDictionary<NSString*,id> *)options
NS_AVAILABLE(10_4,5_0);
@end
