//
//  BCRouteKitPrivate.h
//  Pods
//
//  Created by YeQing on 2018/11/3.
//

#ifndef BCRouteKitPrivate_h
#define BCRouteKitPrivate_h


#pragma mark - route 参数
#define kBCRouteTable_TransitKey                    @"bcts"//转场动画类型
#define kBCRouteTable_RootPushKey                   @"bcroot"//是否在root上push，默认NO,在最顶层nvc上push
#define kBCRouteTransitType_Push                    0//转场动画，push
#define kBCRouteTransitType_Present                 1//转场动画, present

//路由模块下默认页面路径（rest风格）
#define kZHRoute_DomainDefaultPage      @"index"

#endif /* BCRouteKitPrivate_h */
