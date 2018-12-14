#import "ZHWXPayWebVIew.h"

@interface ZHWXPayWebVIew ()<UIWebViewDelegate>

@property (strong, nonatomic) UIWebView *myWebView;
@property (assign, nonatomic) BOOL isLoading;

@end

@implementation ZHWXPayWebVIew
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.myWebView = [[UIWebView alloc] initWithFrame:self.frame];
        self.myWebView.delegate = self;
        [self addSubview:self.myWebView];
    }
    return self;
}
- (void)loadRequestWithUrlString:(NSString *)url {
    //首先要设置为NO
    self.isLoading = NO;
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}
#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    NSString *newUrl = url.absoluteString;
    if (!self.isLoading) {
        if ([newUrl rangeOfString:@"weixin://wap/pay"].location != NSNotFound) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
            [self.myWebView loadRequest:request];
            self.isLoading = YES;
            return NO;
        }
    } else {
        if ([newUrl rangeOfString:@"weixin://wap/pay"].location != NSNotFound) {
            self.myWebView = nil;
            UIWebView *web = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
            [self addSubview:web];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
            [web loadRequest:request];
            return YES;
        }
    }

    NSDictionary *headers = [request allHTTPHeaderFields];
    BOOL hasReferer = [headers objectForKey:@"Referer"] != nil;
    if (hasReferer) {
        return YES;
    } else {
        // relaunch with a modified request
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *url = [request URL];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
                [request setHTTPMethod:@"GET"];
                // 设置授权域名
                // 首先把Referer设置成：www.xxx.com://这个样式的然后把scheme设置成：www.xxx.com这样的话支付成功或者取消支付都可以直接返回到APP了
                NSMutableString *relReferer = [NSMutableString stringWithString:self.referer];
                if ([relReferer containsString:@"http://"]) {
                    NSRange httpRange = [relReferer rangeOfString:@"http://"];
                    [relReferer replaceCharactersInRange:httpRange withString:@""];
                }else if ([relReferer containsString:@"https://"]) {
                    NSRange httpsRange = [relReferer rangeOfString:@"https://"];
                    [relReferer replaceCharactersInRange:httpsRange withString:@""];
                }
                [relReferer appendString:@"://"];
                [request setValue:relReferer forHTTPHeaderField:@"Referer"];
                [self.myWebView loadRequest:request];
            });
        });
        return NO;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{

}

@end
