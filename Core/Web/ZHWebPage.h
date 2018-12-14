//
//  ZHWebPage.h
//  Pod
//
//  Created by YeQing on 16/10/16.
//  Copyright © 2016年 naruto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZHWebPage : UIViewController

@property (nonatomic, strong) NSString      *url;
@property (nonatomic, strong) NSString      *cookies;//默认是 [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
@property (nonatomic, strong) NSString      *localHtmlString;
@property (nonatomic, strong) NSURL         *localBaseURL;
// HTTPHeader
@property (nonatomic, strong) NSDictionary<NSString*,NSString*> *headers;
// 支付的回调url 用户支付宝支付截取判断是否支付成功
@property (nonatomic, strong) NSString      *payBackurl;

#pragma mark - 添加js调用oc 的bridge 任务

/**
 准备 交互bridge任务，子类重写，添加自己的任务
 */
- (void)prepareBridges;

/**
 添加 js 、oc交互bridge
 
 @param ObjName 交互的对象名称
 @param selectorName 交互的协议名称
 @param action 交互需要做的事情
 */
//- (void)addBridge:(NSString *)ObjName selector:(NSString *)selectorName action:(void (^)(id msgBody))action;

/**
  添加 js 、oc交互bridge

 @param ObjName 交互的对象名称
 @param action routerUrl 需要打开的路由
 */
- (void)addBridgeHandler:(NSString *)ObjName action:(void (^)(NSString *routerUrl))action;

#pragma mark - oc 调用js
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError * error))completionHandler;
@end
