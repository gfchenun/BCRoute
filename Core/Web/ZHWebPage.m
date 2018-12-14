//
//  ZHWebPage.m
//  Pod
//
//  Created by YeQing on 16/10/16.
//  Copyright © 2016年 naruto. All rights reserved.
//


#import "ZHWebPage.h"
#import "ZHWebBridgeTask.h"
#import "BCRouteUtils.h"
#import "BCRouteKitPublic.h"
#import "BCRouter.h"
#import "NJKWebViewProgress.h"
#import "NJKWebViewProgressView.h"

#import <BCComConfigKit/BCComConfigKit.h>
#import "UIBarButtonItem+ZHHelper.h"
#import <WebKit/WebKit.h>
#import <BCFoundation/BCFoundation.h>
#import <BCFileLog/BCFileLog.h>

#import "ZHWXPayWebVIew.h"

@interface ZHWebPage () <WKNavigationDelegate, WKUIDelegate, NJKWebViewProgressDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) NJKWebViewProgressView                        * progressView;
@property (nonatomic, strong) NJKWebViewProgress                            * progressProxy;
@property (nonatomic, strong) UIBarButtonItem                               * backButtonItem;
@property (nonatomic, strong) UIBarButtonItem                               * closedButtonItem;
@property (nonatomic, strong) WKWebView                          * webView;
@property (nonatomic, strong) NSMutableURLRequest                           * currentRequest;
@property (nonatomic, strong) NSMutableArray<ZHWebBridgeTask *>             * listBridges;
@property (strong, nonatomic) NSMutableDictionary     *registerJSObjDict;//交互的js对象 集合

@end

@implementation ZHWebPage
#pragma mark - system
+(void)load
{
    BCRouterRegist(kZHRoute_WebPage, NSStringFromClass([self class]));
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _listBridges = [[NSMutableArray<ZHWebBridgeTask *> alloc] init];
    _registerJSObjDict = [[NSMutableDictionary alloc] init];
//    //添加cookies
//    __block NSMutableString *cookieStr = [[NSMutableString alloc] init];
//    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
//    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [cookieStr appendFormat:@"%@=%@;",obj.name,obj.value];
//    }];
////    cookieStr = @"a=b;c=d;e=f;";
//    _cookies = (NSString *)cookieStr;
    BCLog(@"ZHWebPage url = %@",self.url);
    [self initSubViews];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    for (ZHWebBridgeTask *task in self.listBridges) {
        if (!_registerJSObjDict[task.ObjName]) {//判断是否已经注册过
            _registerJSObjDict[task.ObjName] = @(YES);
            [self.webView.configuration.userContentController addScriptMessageHandler:self name:task.ObjName];
        }
        
    }
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // alert cookie
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [self.webView evaluateJavaScript:@"alert(document.cookie)" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
    //        }];
    //    });
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    for (ZHWebBridgeTask *task in self.listBridges) {
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:task.ObjName];
        _registerJSObjDict[task.ObjName] = nil;
    }
}
- (void)dealloc
{
    [self cleanWebCache];
}

#pragma mark - 初始化sub view
- (void)initSubViews
{
    [self.view addSubview:self.webView];
    [self.navigationController.navigationBar addSubview:self.progressView];
    self.navigationItem.leftBarButtonItems = @[self.backButtonItem];
    BCLogInfo(@"zhweb load url:%@",_url);
    if (self.localHtmlString.length>0) {
        //使用本地 html
        [self.webView loadHTMLString:self.localHtmlString baseURL:self.localBaseURL];
    } else {
        [self.webView loadRequest:self.currentRequest];
    }
    //添加默认监听
    [self prepareBridges];
    

}
- (void)cleanWebCache
{
    [_listBridges removeAllObjects];
    self.webView.UIDelegate = nil;
    self.webView.navigationDelegate = nil;
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView scrollView].delegate = nil;
    [self.webView stopLoading];
    [self.webView loadHTMLString:@"" baseURL:nil];
    [self.webView stopLoading];
    [self.webView removeFromSuperview];
    _webView = nil;
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:self.currentRequest];
    
    [self.progressView removeFromSuperview];
}


/**
 webview 是否可以倒退（不是一个页面,可以js回退）

 @param webview webview description
 @param url url description
 @return return value description
 */
- (BOOL)webViewGoBack:(WKWebView *)webview url:(NSString *)url
{
    if([webview canGoBack]){
        NSString *url_all=[[webview URL] absoluteString];//当前url  http://c2.kuaidadi.com/taxi/web/p/score.htm?idx=259065&token=31671d911d67c6961d85d78be06d0630
        NSString *url_html=nil;//xxxx.htm
        if(url_all.length>0){
            NSArray *array_all=[url_all componentsSeparatedByString:@"?"];
            if(array_all && array_all.count>0){
                url_html=[array_all firstObject];//  http://10.0.50.169:8080/taxi/web/p/category/score.htm?
                if(url_html.length>0){
                    if([url rangeOfString:url_html].location==NSNotFound){
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}


#pragma mark - getter
-(UIBarButtonItem *)backButtonItem
{
    if(!_backButtonItem){
        BCWeakObj(self);
        _backButtonItem = [[UIBarButtonItem alloc] zh_initBackItem:^(UIButton *sender) {
            BCStrongObj(self);
            [self onBackItemAction:sender];
        }];
    }
    return _backButtonItem;
}
-(UIBarButtonItem *)closedButtonItem
{
    if(!_closedButtonItem){
        BCWeakObj(self);
        _closedButtonItem = [[UIBarButtonItem alloc] zh_initLeftItem:[BCComConfig.config.navCloseImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] highlightImage:nil text:nil textColor:nil action:^(UIButton *sender) {
            BCStrongObj(self);
            [self onCloseItemAction:sender];
        }];
    }
    return _closedButtonItem;
}
-(NJKWebViewProgress *)progressProxy
{
    if(!_progressProxy){
        _progressProxy = [[NJKWebViewProgress alloc] init];
        _progressProxy.progressDelegate = self;
    }
    return _progressProxy;
}
-(NJKWebViewProgressView *)progressView
{
    if(!_progressView){
        CGFloat progressBarHeight = 2.f;
        CGRect navigaitonBarBounds = self.navigationController.navigationBar.bounds;
        CGRect barFrame = CGRectMake(0, navigaitonBarBounds.size.height - progressBarHeight, navigaitonBarBounds.size.width, progressBarHeight);
        _progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
        _progressView.progressBarView.backgroundColor = BCComConfig.config.defaultColor;
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return _progressView;
}
-(WKWebView *)webView
{
    if(!_webView){
        //设置cookies
        __block NSMutableString *cookieStr = [[NSMutableString alloc] init];
        NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
        [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [cookieStr appendFormat:@"document.cookie='%@=%@;path=/';",obj.name,obj.value];
        }];
        NSString *jScript = (NSString *)cookieStr;
        
        WKUserScript* wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        WKUserContentController *wkUController = [[WKUserContentController alloc] init];
        [wkUController addUserScript:wkUScript];
        WKWebViewConfiguration* wkWebConfig = [[WKWebViewConfiguration alloc] init];
        wkWebConfig.userContentController = wkUController;
        
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:wkWebConfig];
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.opaque = NO;
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
        [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        [_webView setFrame:self.view.bounds];
        [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
    return _webView;
}
-(NSMutableURLRequest *)currentRequest
{
    if(!_currentRequest){
        //先处理URL
        NSString *strURLAdd = nil;
        //add ts
        if(![_url containsString:@"ts="]){
            //        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding
            long long reqTs = [[NSDate date] timeIntervalSince1970]*1000;
            strURLAdd = [NSString stringWithFormat:@"ts=%@",@(reqTs)];
        }
        
        if(strURLAdd.length>0){
            if(![_url containsString:@"?"]){
                //请求的url没有？
                _url = [NSString stringWithFormat:@"%@?%@",_url,strURLAdd];
            }
            else{
                //请求的url有？
                _url = [NSString stringWithFormat:@"%@&%@",_url,strURLAdd];
            }
        }
        _url = [NSString bc_getValidURL:_url];//过滤非法url
        if(_url.length<=0){
            BCLog(@"zhweb error url");
        }
        NSURL *requestURL = [NSURL URLWithString:_url];
        if(!requestURL){
            BCLog(@"zhweb error request");
        }
        _currentRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];
        if (self.headers) {
            for (NSString *key in self.headers.allKeys) {
                NSString *value = self.headers[key];
                if (value.length > 0) {
                    [_currentRequest setValue:value forHTTPHeaderField:key];
                }
            }
        }
        //        if (self.cookies.length>0) {
        //            [_currentRequest addValue:self.cookies forHTTPHeaderField:@"Cookie"];
        //        }
    }
    return _currentRequest;
}


#pragma mark - 添加js调用oc 的bridge 任务
-(void)prepareBridges
{
    //子类重写
    // 添加文件预览桥接
    [self addBridgeHandler:@"filePreview" action:^(NSString *routerUrl) {
        if (routerUrl.length > 0 && [routerUrl isKindOfClass:[NSString class]]) {
             [[BCRouter sharedInstance] pushRoute:routerUrl];
        }
    }];
}
- (void)addBridgeHandler:(NSString *)ObjName action:(void (^)(NSString *routerUrl))action {
    ZHWebBridgeTask *bridgeTask = [[ZHWebBridgeTask alloc] init];
    bridgeTask.ObjName = ObjName;
    [bridgeTask setBridgeAction:action];
    [self.listBridges addObject:bridgeTask];
}
//- (void)addBridge:(NSString *)ObjName selector:(NSString *)selectorName action:(void (^)(id msgBody))action
//{
//    ZHWebBridgeTask *bridgeTask = [[ZHWebBridgeTask alloc] init];
//    bridgeTask.ObjName = ObjName;
//    bridgeTask.selectorName = selectorName;
//    [bridgeTask setBridgeAction:action];
//    [self.listBridges addObject:bridgeTask];
//}

#pragma mark - oc 调用js
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError * error))completionHandler;
{
    [self.webView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}


#pragma mark - Event
- (void)onBackItemAction:(id)sender
{
    BOOL canGoBack = [self webViewGoBack:_webView url:_url];
    if (canGoBack) {
        if (self.navigationItem.leftBarButtonItems.count < 2) {
            self.navigationItem.leftBarButtonItems = @[ self.backButtonItem, self.closedButtonItem ];
        }
        [_webView goBack];
    }
    else {
        [self onCloseItemAction:sender];
    }
}

- (void)onCloseItemAction:(id)sender
{
    if (self.navigationController.viewControllers.count == 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - observe
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        float progress = [change[NSKeyValueChangeNewKey] floatValue];
        [_progressView setProgress:progress animated:YES];
    }
    else if ([keyPath isEqualToString:@"title"]) {
        self.title = change[NSKeyValueChangeNewKey];
    }
}


#pragma mark - NJKWebViewProgress Delegate
- (void)webViewProgress:(NJKWebViewProgress*)webViewProgress updateProgress:(float)progress
{
    [_progressView setProgress:progress animated:YES];
}

#pragma mark - WKWebView delegate
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    BCLogInfo(@"zhweb %@",message.body);
    if(message.name.length<=0 || !message.body){
        return;
    }
    //    NSDictionary *msgDict = [NSString bc_jsonObject:message.body];
    //    if (![msgDict isKindOfClass:[NSDictionary class]]) {
    //        return;
    //    }
    NSString *objName = message.name;
    for (ZHWebBridgeTask *task in self.listBridges) {
        if ([objName isEqualToString:task.ObjName]){//找到要执行的对象
            // message.body进行了encode操作路由无法解析 需要进行decoded
            NSString *bodyString = [NSString stringWithFormat:@"%@",message.body];
            NSString *decodedString=(__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)bodyString, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            task.bridgeAction(decodedString);
            break;
        }
    }
    
    //    for (ZHWebBridgeTask *task in self.listBridges) {
    //        if ([objName isEqualToString:task.ObjName]){//找到要执行的对象
    //            id funParams = msgDict[task.selectorName];
    //            if (funParams) {//找到要执行的方法
    //                task.bridgeAction(funParams);
    //                break;
    //            }
    //        }
    //    }
    
}
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    BCLogInfo(@"zhweb err:%@",[error userInfo]);
    if (self.title.length<=0) {
        self.title = BCLOC(@"加载出错啦");
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSString *requestUrl = navigationAction.request.URL.absoluteString;
    // decoded url
    //    NSString *decodedString=(__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)requestUrl, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    //    BCLog(@"encodeURL url = %@",decodedString);
    WKNavigationActionPolicy actionPolicy = WKNavigationActionPolicyCancel;
    
    if ([requestUrl hasPrefix:@"alipays://"] || [requestUrl hasPrefix:@"alipay://"]) {
        NSString *replaceUrl = [NSString stringWithFormat:@"%@",requestUrl];
        if ([replaceUrl containsString:@"fromAppUrlScheme"] && [replaceUrl containsString:@"alipays"]) {
            replaceUrl = [replaceUrl stringByReplacingOccurrencesOfString:@"alipays" withString:BCComConfig.config.setting[@"public_scheme"]];
        }
        //NOTE: 跳转支付宝App
        BOOL isSucc = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:replaceUrl]];
        if (!isSucc) {
            BCLog(@"用户未安装支付宝客户端");
        }
    }else if ([requestUrl containsString:@"https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?"]) {
        //        // TODO: 微信支付链接不要拼接redirect_url，如果拼接了还是会返回到浏览器的
        //        //传入的是微信支付链接：https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx201801291021026cb304f9050743178155&package=3456576571
        //这里把webView设置成一个像素点，主要是不影响操作和界面，主要的作用是设置referer和调起微信
        ZHWXPayWebVIew *h5View = [[ZHWXPayWebVIew alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        [h5View loadRequestWithUrlString:requestUrl];
        if (self.headers[@"Referer"]) {
            h5View.referer = self.headers[@"Referer"];
        }
        [self.view addSubview:h5View];
        
    } else if (self.payBackurl.length>0 && [requestUrl hasPrefix:self.payBackurl]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBCRouteNotifcation_PaySucc object:nil];
        [self.navigationController popViewControllerAnimated:NO];
        
    } else {
        actionPolicy = WKNavigationActionPolicyAllow;
    }
    decisionHandler(actionPolicy);
}

// 解决网页中有target="_blank" 在新窗口打开链接的一种方法
-(WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
@end
