//
//  ZHWXPayWebVIew.h
//  BCRouteKit
//
//  Created by chun.chen on 2018/10/22.
//  微信支付H5

#import <UIKit/UIKit.h>

@interface ZHWXPayWebVIew : UIView

/**
 微信支付需要设置 header 的referer
 */
@property (nonatomic, strong) NSString *referer;


/**
 加载URL

 @param url url description
 */
- (void)loadRequestWithUrlString:(NSString *)url;

@end

