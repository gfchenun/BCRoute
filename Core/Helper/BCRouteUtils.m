//
//  BCRouteUtils.m
//  BCRouteKit
//
//  Created by YeQing on 2018/11/3.
//

#import "BCRouteUtils.h"
#import "BCRouteKitPrivate.h"
#import "BCRouteKitPublic.h"
#import "BCRouter.h"
#import <BCFoundation/NSString+BCHelper.h>

#define kZHRoute_Host                 BCRouter.sharedInstance.routeHost

@implementation BCRouteUtils

#pragma mark - 注册路由
void BCRouterRegist(NSString *key, NSString *clsName) {
    [[BCRouter sharedInstance] registerRoute:key withClsName:clsName];
}
void BCRouterRegister(NSString *domian, NSString *key, NSString *clsName) {
    [[BCRouter sharedInstance] registerRoute:domian withKey:key withClsName:clsName];
}

#pragma mark - 构造h5路由
NSString * kZHRouteH5URL(NSString *linkURL){
    return [NSString stringWithFormat:@"%@/%@?url=%@",kZHRoute_Host, kZHRoute_WebPage, [linkURL bc_encode]];
}
NSString * ZHRouteH5URLWithVersion(NSString *linkURL, NSString *ver) {
    return [NSString stringWithFormat:@"%@/%@?url=%@&version=%@", kZHRoute_Host, kZHRoute_WebPage, [linkURL bc_encode], ver];
}

#pragma mark - 构造普通路由
NSString * kZHRouteURL(NSString *url){
    return BCRouteURLString(kZHRoute_Host, url, kBCRouteTransitType_Push, NO, nil);
}
NSString * kZHRouteURLS(NSString *url, NSDictionary *params) {
    return BCRouteURLString(kZHRoute_Host, url, kBCRouteTransitType_Push, NO, params);
}
NSString * kZHRouteRootURLS(NSString *url, NSDictionary *params) {
    return BCRouteURLString(kZHRoute_Host, url, kBCRouteTransitType_Push, YES,params);
}
NSString * kZHRoutePresentURL(NSString *url) {
    return BCRouteURLString(kZHRoute_Host, url, kBCRouteTransitType_Present, NO, nil);
}
NSString * kZHRoutePresentURLS(NSString *url, NSDictionary *params) {
    return BCRouteURLString(kZHRoute_Host, url, kBCRouteTransitType_Present, NO, params);
}

NSString * BCRouteURLString(NSString *host, NSString *url,NSInteger transit,BOOL rootPush, NSDictionary *params)
{
    __block NSMutableString *urlMStr = [[NSMutableString alloc] initWithFormat:@"%@/%@",host,url];
    [urlMStr appendFormat:@"?%@=%ld",kBCRouteTable_TransitKey, (long)transit];
    if (rootPush) {
        [urlMStr appendFormat:@"&%@=%d",kBCRouteTable_RootPushKey, rootPush];
    }
    if (params.allKeys.count>0) {
        [params.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id pvalue = params[obj];
            if ([pvalue isKindOfClass:[NSString class]]) {//字符串需要 encode
                pvalue = [pvalue bc_encode];
            }
            [urlMStr appendFormat:@"&%@=%@", obj, pvalue];
        }];
    }
    //    if(paramsFormat.length>0){
    //        [urlMStr appendString:@"&"];
    //        va_list args;
    //        va_start(args, paramsFormat);
    //        [urlMStr appendString:[[NSString alloc] initWithFormat:paramsFormat arguments:args]];
    //        va_end(args);
    //    }
    return (NSString *)urlMStr;
}

@end
