//
//  BCRouter.h
//  Pod
//
//  Created by green on 17/3/15.
//  Copyright © 2017年 green. All rights reserved.
//  路由组件


#import <Foundation/Foundation.h>
#import "BCRouterProtocol.h"


@interface BCRouter : NSObject

/** 路由的host，区分不同app，默认是 @"http://www.ececloud.cn/ios" */
@property (nonatomic, copy) NSString    *routeHost;
/** 版本号，默认app版本号 */
@property (nonatomic, copy) NSString    *routeVersion;
/** 导航栏的class name，默认是 UINavigationController */
@property (nonatomic, copy) NSString    *navClsName;

#pragma mark - system
/**
 初始化
 */
+ (instancetype )sharedInstance;

#pragma mark - bind unbind
- (void)bind:(id<BCRouteProtocol> )delegate;
- (void)unbind:(id<BCRouteProtocol> )delegate;

#pragma mark - 初始化

/**
 初始化
 */
- (void)zh_setup;


#pragma mark - 注册 route


/**
 注册route

 @param path UIViewController 唯一key，支持 domain/key、key 两种方式
 @param clsName 对应UIViewController class name
 */
- (void)registerRoute:(NSString *)path withClsName:(NSString *)clsName;

/**
 注册route

 @param domain 区分不同sdk
 @param key UIViewController 唯一key
 @param clsName 对应UIViewController class name
 */
- (void)registerRoute:(NSString *)domain withKey:(NSString *)key withClsName:(NSString *)clsName;


#pragma mark - push route 

/**
 push route

 @param url route的url
 */
- (void)pushRoute:(NSString *)url;

/**
 push route

 @param url route的url
 @param extData 其他参数，一般存储无法urlEncode的自定义对象，也可以存储所有参数。
 */
- (void)pushRoute:(NSString *)url extData:(NSDictionary *)extData;
/**
 push route

 @param url route的url,参考标准URL格式 <scheme>://<host>/<path>?<query>#<anchor>
 @param extData 其他参数，一般存储无法urlEncode的自定义对象，也可以存储所有参数。
 @param completion 完成回调
 */
- (void)pushRoute:(NSString *)url  extData:(NSDictionary *)extData completion:(void(^ )(NSError * error) )completion;


#pragma mark - pop route

/**
 弹出 route

 @param animated 是否需要动画
 */
- (void)popRoute:(BOOL )animated;

/**
 弹出 route 到指定界面
 
 @param url 推出到的界面 url，若当前navigation栈中不含该界面，则推出到 rootVC
 @param animated 是否需要动画
 */
- (BOOL )popToRoute:(NSString *)url animated:(BOOL)animated;


/**
 弹出root 到 root页面

 @param animated animated description
 */
- (void)popRouteToRoot:(BOOL )animated;

#pragma mark - 移除 route
/**
 移除指定的route

 @param url url description
 @param animated animated description
 @return return value description
 */
- (BOOL )removeRoute:(NSString *)url animated:(BOOL)animated;
- (void )removeRoutes:(NSArray *)urls animated:(BOOL)animated;

#pragma mark - helper

/**
 判断是否有路由

 @param url url description
 @return return value description
 */
- (UIViewController *)hasRoute:(NSString *)url;

/**
 根据URL获取路由
 
 @param url url description
 @return return value description
 */
- (UIViewController *)getRoute:(NSString *)url;
@end
