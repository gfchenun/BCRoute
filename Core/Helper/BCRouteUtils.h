//
//  BCRouteUtils.h
//  BCRouteKit
//
//  Created by YeQing on 2018/11/3.
//  路由帮助类

#import <Foundation/Foundation.h>

@interface BCRouteUtils : NSObject

#pragma mark - 注册路由
void BCRouterRegist(NSString *key, NSString *clsName);
void BCRouterRegister(NSString *domian, NSString *key, NSString *clsName);

#pragma mark - 构造h5路由
NSString * kZHRouteH5URL(NSString *linkURL);
NSString * ZHRouteH5URLWithVersion(NSString *linkURL, NSString *ver);

#pragma mark - 构造普通路由
NSString * kZHRouteURL(NSString *url);
NSString * kZHRouteURLS(NSString *url, NSDictionary *params);
NSString * kZHRouteRootURLS(NSString *url, NSDictionary *params);
NSString * kZHRoutePresentURL(NSString *url);
NSString * kZHRoutePresentURLS(NSString *url, NSDictionary *params);

/**
 url 字符串
 
 @param host 域名
 @param url url 页面id
 @param transit 转场动画类型
 @param rootPush 是否在root上push
 @param params 参数字典
 @return NSString
 */
NSString * BCRouteURLString(NSString *host, NSString *url,NSInteger transit,BOOL rootPush, NSDictionary *params);
@end

