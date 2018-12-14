//
//  BCRouterProtocol.h
//  Pods
//
//  Created by YeQing on 2018/11/3.
//

#ifndef BCRouterProtocol_h
#define BCRouterProtocol_h

@class BCRouter;
@class BCRouteRequest;

#pragma mark - route 组件协议
@protocol  BCRouteProtocol <NSObject>
@optional
/**
 route 将要push，这里可以做统一拦截
 
 @param router router
 @param request BCRouteRequest
 */
- (void )bcroute:(BCRouter *)router willPushRequest:(BCRouteRequest *)request;
@end


#pragma mark - route 页面协议
@protocol  BCRoutePageProtocol <NSObject>
@optional

/**
 获取自定义转场动画 实现（只支持present模式）
 
 @return return value description
 */
- (id<UIViewControllerTransitioningDelegate> )zhroutePressentTransitioningDelegate;

/**
 获取自定义转场动画 实现（只支持dismiss模式）
 
 @return return value description
 */
- (id<UIViewControllerTransitioningDelegate> )zhrouteDismissTransitioningDelegate;


/**
 route 将要push，返回值 标识是否可以push
 
 @param params route url 参数
 @param extData 扩展参数
 */
+ (BOOL )zhrouteWillPush:(NSDictionary *)params extData:(NSDictionary *)extData;

/**
 route 将要push，vc 已经初始化完成，等待验证是否可以push
 
 @param params route url 参数
 @param extData 扩展参数
 @param nextBlock 继续执行block
 */
- (void )zhrouteWillPush:(NSDictionary *)params extData:(NSDictionary *)extData withNextBlock:(void(^)(BOOL canContinue) )nextBlock;


/**
 route page 重新加载
 
 @param params route url 参数
 @param extData 扩展参数
 */
- (void )zhroutePageReload:(NSDictionary *)params extData:(NSDictionary *)extData;
@end


#endif /* BCRouterProtocol_h */
