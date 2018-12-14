//
//  BCRouteResponse.h
//  Pod
//
//  Created by green on 17/3/30.
//  Copyright © 2017年 green. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class UIViewController;

@interface BCRouteResponse : NSObject

@property (readonly) NSString *url; // 路由的初始url
@property (readonly) NSInteger statusCode; // 路由结果状态码
@property (weak, nonatomic) UIViewController *source; // 跳转的来源界面
@property (weak, nonatomic) UIViewController *target; // 跳转的目的界面

//- (instancetype) initWithUrl:(NSString *)url statusCode:(NSInteger)statusCode source:(UIViewController *)source;
- (instancetype)initWithUrl:(NSString *)url statusCode:(NSInteger)statusCode;

@end
