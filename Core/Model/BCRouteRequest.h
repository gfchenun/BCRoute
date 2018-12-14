//
//  BCRouteRequest.h
//  Pod
//
//  Created by green on 17/3/30.
//  Copyright © 2017年 green. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BCRouteRequest: NSObject
/** URL 中的path列表 */
@property (strong, nonatomic, readonly) NSArray<NSString *>   *paths;
/** URL参数 */
@property (strong, nonatomic) NSDictionary          *params;
/** 其他参数，一般存储无法urlEncode的自定义对象，也可以存储所有参数。 */
@property (strong, nonatomic) NSDictionary          *extData;
/** 所有参数，包括 parameter和 extData */
@property (strong, nonatomic, readonly) NSDictionary *allParams;
/** 路由的初始url */
@property (strong, nonatomic, readonly) NSString    *urlString;
/** 转场动画类型,默认是push；kBCRouteRequestTransitType_Push、kBCRouteRequestTransitType_Present */
@property (assign, nonatomic, readonly) NSInteger   transitType;
/** 是否在root上push，默认NO,在最顶层nvc上push */
@property (assign, nonatomic, readonly) BOOL        rootPush;


#pragma mark - 初始化

/**
  通过url初始化路由请求，url会被nginx替换成ruleType和replacement

 @param urlString urlString description
 @return return value description
 */
- (instancetype)initWithURLStr:(NSString *)urlString;

@end
