//
//  BCRouter.m
//  Pod
//
//  Created by green on 17/3/15.
//  Copyright © 2017年 green. All rights reserved.
//

#import "BCRouter.h"
#import "BCRouteRequest.h"
#import "BCRouteResponse.h"
#import "BCRouteKitPublic.h"
#import "BCRouteKitPrivate.h"
#import "BCRouteUtils.h"

#import <objc/runtime.h>
#import <BCFoundation/BCFoundationUtils.h>
#import <BCFoundation/NSString+BCHelper.h>
#import <BCUIKit/UIViewController+ZHPage.h>

#define BCRouterErrorDomain @"BCRouterErrorDomain"
#define kBCRouter_DefaultDomain @""//默认域

@interface BCRouter ()
@property (nonatomic, strong) BCRouteRequest        *request;
@property (nonatomic, strong) BCRouteResponse       *response;
@property (nonatomic, strong) NSMutableDictionary   *routeTable;//路由表
@property (nonatomic, strong) NSHashTable       *bindedDelegates;
@property (nonatomic, strong) Class     zh_navCls;//navigation class

@end

@implementation BCRouter
#pragma mark - system
static BCRouter *kBCRouterInstance;
+ (instancetype)sharedInstance
{
    static dispatch_once_t kBCRouterOnceToken;
    dispatch_once(&kBCRouterOnceToken,^{
        kBCRouterInstance = [[[self class] alloc] init];
    });
    return kBCRouterInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _routeTable = [[NSMutableDictionary alloc] init];
        _routeHost = @"http://www.ececloud.cn/ios";
        [self setNavClsName:@"UINavigationController"];
        _bindedDelegates = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:0];
    }
    return self;
}

#pragma mark - 初始化
- (void)zh_setup
{
}


#pragma mark - bind unbind
- (void)bind:(id<BCRouteProtocol> )delegate
{
    if (!delegate ) {
        return;
    }
    if(![_bindedDelegates containsObject:delegate]){
        [_bindedDelegates addObject:delegate];
    }
}

- (void)unbind:(id<BCRouteProtocol> )delegate
{
    [_bindedDelegates removeObject:delegate];
}

#pragma mark - 注册 route
- (void)registerRoute:(NSString *)path withClsName:(NSString *)clsName
{
    NSString *domain = kBCRouter_DefaultDomain;
    NSString *key = path;
    if ([path containsString:@"/"]) {
        NSMutableArray *pathList = [[path componentsSeparatedByString:@"/"] mutableCopy];
        if (pathList.count>1) {
            key = [[pathList lastObject] copy];
            [pathList removeLastObject];
            domain = [pathList componentsJoinedByString:@"/"];
        }
    }
    [self registerRoute:domain withKey:key withClsName:clsName];
}

- (void)registerRoute:(NSString *)domain withKey:(NSString *)key withClsName:(NSString *)clsName
{
    if(domain.length<=0){
        //没有指定域，则默认在第一级目录
        self.routeTable[key] = clsName;
        return;
    }
    //指定了其他域
    NSMutableDictionary *routeDomain = self.routeTable[domain];
    if(!routeDomain){
        //domain 为空
        routeDomain = [[NSMutableDictionary alloc] init];
        _routeTable[domain]= routeDomain;
    }
#ifdef DEBUG
    if (routeDomain[key]) {
        NSAssert(0, @"bcroute exsit route");
    }
#endif
    routeDomain[key] = clsName;
}


#pragma mark - push
- (void)pushRoute:(NSString *)url
{
    [self pushRoute:url extData:nil completion:nil];
}

- (void)pushRoute:(NSString *)url extData:(NSDictionary * _Nullable)extData
{
    [self pushRoute:url extData:extData completion:nil];
}

- (void)pushRoute:(NSString *)url extData:(NSDictionary * _Nullable)extData completion:(void (^ _Nullable)(NSError * _Nullable))completion
{
    if (self.routeTable == nil) {
        [self returnError:-1 localizedDescription:@"路由表为空" byCompletionBlock:completion];
        return;
    }
    if (url.length<=0) {
        [self returnError:-1 localizedDescription:nil byCompletionBlock:completion];
        return;
    }
    BCRouteRequest *request = [[BCRouteRequest alloc] initWithURLStr:url];
    request.extData = extData;
    if (request.paths.count<=0) {
        [self returnError:-1 localizedDescription:nil byCompletionBlock:completion];
        return;
    }
    self.request = request;
    [self pushRouteHandle:request completion:completion];
}

#pragma mark - push handle

/**
 路由跳转handle
 
 @param request 路由request
 @param completion 完成回调
 */
- (void)pushRouteHandle:(BCRouteRequest *)request completion:(void(^)(NSError *error))completion
{
    //关闭键盘输入
    [[[UIApplication sharedApplication].delegate window] endEditing:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBCRouteNotifcation_WillPush object:nil];
    //查找class
    Class clazz = [self getRouteClassWithRequest:request];
    if (!clazz) {
        //没有找到class，跳转到默认页面
        [BCRouter.sharedInstance pushRoute:ZHRouteH5URLWithVersion(self.request.urlString, self.routeVersion)];
        return;
    }
    //找到class，先判断是不是vc
    if (![clazz isSubclassOfClass:[UIViewController class]]) {
        return;
    }
    //检测是否可以push、present
    BOOL canPush = YES;
    if ([clazz respondsToSelector:@selector(zhrouteWillPush:extData:)]) {
        canPush  = [(id<BCRoutePageProtocol> )clazz zhrouteWillPush:request.params extData:request.extData];
    }
    if (!canPush) {
        [self returnError:-1 localizedDescription:@"can not push" byCompletionBlock:completion];
        return;
    }
    UIViewController *controller = [self configRoutePage:clazz withRequest:self.request];
    //跳转之前可以做一些事情，处理参数，或者判断是否可以继续跳转
    if ([controller respondsToSelector:@selector(zhrouteWillPush:extData:withNextBlock:)]) {
        @BCWeakify(self);
        [(id<BCRoutePageProtocol> )controller zhrouteWillPush:request.params extData:request.extData withNextBlock:^(BOOL canContinue) {
            @BCStrongify(self);
            [self zh_routeToViewController:controller completion:completion];
        }];
        return;
    }
    [self zh_routeToViewController:controller completion:completion];
}


- (void)zh_routeToViewController:(UIViewController *)viewController completion:(void(^)(NSError *error))completion
{
    //组件通知，将要push
    NSHashTable *bindDelegates  = [self.bindedDelegates mutableCopy];
    for (id<BCRouteProtocol> bindItem in bindDelegates) {
        if([bindItem respondsToSelector:@selector(bcroute:willPushRequest:)]){
            [bindItem bcroute:self willPushRequest:self.request];
        }
    }
    // 获取当前顶层视图
    UIViewController *currentVC = nil;
    if (self.request.rootPush) {//在root上push
        UIViewController *vcRoot = [[[UIApplication sharedApplication] delegate] window].rootViewController;
        if ([vcRoot isKindOfClass:[UINavigationController class]]) {
            currentVC = [(UINavigationController *)vcRoot topViewController];
        }
        else if ([vcRoot isKindOfClass:[UITabBarController class]]) {
            currentVC = [(UINavigationController *)[(UITabBarController *)vcRoot selectedViewController] topViewController];
        }
    }
    if (!currentVC) {
        currentVC = [UIViewController bc_topPage];//[UIViewController bc_topNavPage];
    }
    UISearchController *searchVC = nil;
    if ([currentVC isKindOfClass:[UISearchController class]]) {
        searchVC = (UISearchController *)currentVC;
    }
    
    //    __weak BCRouter *weakSelf = self;
    void (^completionBlock)(void) = ^{
        //        __strong typeof(weakSelf) strongSelf = weakSelf;
        //        BCRouteResponse *response = [[BCRouteResponse alloc] initWithUrl:strongSelf.request.urlString statusCode:200];
        //        response.source = currentVC;
        //        response.target = viewController;
        //        strongSelf.response = response;
        if (completion != nil) {
            completion(nil);
        }
    };
    //push
    if(self.request.transitType == kBCRouteTransitType_Push){//PUSH
        
        if (searchVC) {
            currentVC = searchVC.presentingViewController;
        }
        if (currentVC.navigationController != nil) {
            [currentVC.navigationController pushViewController:viewController animated:YES];
            if (completionBlock) {
                completionBlock();
            }
            //            completion();
        }
        else {
            if (searchVC) {
                searchVC.active = NO;
                currentVC = searchVC.presentingViewController;
            }
            
            [self zh_presentPage:viewController currentPage:currentVC completion:completionBlock];
        }
    } else if(self.request.transitType == kBCRouteTransitType_Present){//present
        if (searchVC) {
            searchVC.active = NO;
            currentVC = searchVC.presentingViewController;
        }
        [self zh_presentPage:viewController currentPage:currentVC completion:completionBlock];
    }
}

#pragma mark - present / dismiss
- (void)zh_presentPage:(UIViewController *)page currentPage:(UIViewController *)currentPage completion:(void (^)(void) )completion
{
    UINavigationController *navcPage = [[self.zh_navCls alloc] initWithRootViewController:page];
    id<UIViewControllerTransitioningDelegate> customAnimator = nil;//自定义 转场动画
    if ([page respondsToSelector:@selector(zhroutePressentTransitioningDelegate)]) {
        customAnimator = [page performSelector:@selector(zhroutePressentTransitioningDelegate) withObject:nil];
    }
    if (customAnimator) {
        navcPage.modalPresentationStyle = UIModalPresentationCustom;
        navcPage.transitioningDelegate = customAnimator;
    }
    [currentPage presentViewController:navcPage animated:YES completion:completion];
}

- (void)zh_dismissPage:(UIViewController *)page completion:(void (^)(void) )completion
{
    UINavigationController *navcPage = page.navigationController;
    id<UIViewControllerTransitioningDelegate> customAnimator = nil;//自定义 转场动画
    if ([page respondsToSelector:@selector(zhrouteDismissTransitioningDelegate)]) {
        customAnimator = [page performSelector:@selector(zhrouteDismissTransitioningDelegate) withObject:nil];
    }
    if (customAnimator) {
        navcPage.modalPresentationStyle = UIModalPresentationCustom;
        navcPage.transitioningDelegate = customAnimator;
    }
    [page dismissViewControllerAnimated:YES completion:completion];
}

#pragma mark - pop
- (void)popRoute:(BOOL )animated
{
    [[[UIApplication sharedApplication].delegate window] endEditing:YES];
    UIViewController *topVC = [UIViewController bc_topPage];
    if (topVC.navigationController.viewControllers.count == 1) {
        [self zh_dismissPage:topVC completion:nil];
    }
    else {
        [topVC.navigationController popViewControllerAnimated:animated];
    }
}

- (void)popRouteToRoot:(BOOL )animated
{
    [[[UIApplication sharedApplication].delegate window] endEditing:YES];
    UIViewController *vcRoot = [[[UIApplication sharedApplication] delegate] window].rootViewController;
    if ([vcRoot isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navcTmp = (UINavigationController *)vcRoot;
        if (navcTmp.viewControllers.count == 1) {
            [navcTmp.presentedViewController dismissViewControllerAnimated:animated completion:nil];
        } else {
            [navcTmp popToRootViewControllerAnimated:YES];
        }
    }
    else if ([vcRoot isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabbarTmp = (UITabBarController *)vcRoot;
        if ([tabbarTmp.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navcTmp = (UINavigationController *)tabbarTmp.selectedViewController;
            if (navcTmp.viewControllers.count == 1) {
                [navcTmp.presentedViewController dismissViewControllerAnimated:animated completion:nil];
            } else {
                [navcTmp popToRootViewControllerAnimated:YES];
            }
        } else {
            [tabbarTmp.selectedViewController dismissViewControllerAnimated:animated completion:nil];
        }
    }
    //    if (topVC.navigationController.viewControllers.count == 1) {
    //        [topVC dismissViewControllerAnimated:animated completion:nil];
    //    }
    //    else {
    //        [topVC.navigationController popToRootViewControllerAnimated:animated];
    //    }
}

- (BOOL )popToRoute:(NSString *_Nullable)url animated:(BOOL)animated
{
    if (url.length<=0) {
        //        [self popRouteToRoot:animated];
        return NO;
    }
    [[[UIApplication sharedApplication].delegate window] endEditing:YES];
    BCRouteRequest *request = [[BCRouteRequest alloc] initWithURLStr:url];
    Class clazz = [self getRouteClassWithRequest:request];
    if (!clazz) {
        return NO;
    }
    UIViewController *findVC = [UIViewController bc_findPage:clazz];
    if (findVC) {
        [findVC.navigationController popToViewController:findVC animated:animated];
    }
    return (findVC!=nil);
}


- (BOOL )removeRoute:(NSString *_Nullable)url animated:(BOOL)animated
{
    if (url.length<=0) {
        //        [self popRouteToRoot:animated];
        return NO;
    }
    [[[UIApplication sharedApplication].delegate window] endEditing:YES];
    BCRouteRequest *request = [[BCRouteRequest alloc] initWithURLStr:url];
    Class clazz = [self getRouteClassWithRequest:request];
    if (!clazz) {
        return NO;
    }
    UIViewController *findVC = [UIViewController bc_findPage:clazz];
    if (findVC) {
        NSMutableArray *vcNews = [[NSMutableArray alloc] init];
        for (UIViewController *vcTemp in findVC.navigationController.viewControllers) {
            if (vcTemp != findVC) {
                [vcNews addObject:vcTemp];
            }
        }
        if (vcNews.count>0) {
            [findVC.navigationController setViewControllers:vcNews animated:animated];
        } else if (findVC.presentingViewController) {
            [findVC dismissViewControllerAnimated:animated completion:nil];
        }
    }
    return (findVC!=nil);
}

- (void )removeRoutes:(NSArray *_Nullable)urls animated:(BOOL)animated
{
    if (urls.count<=0) {
        return ;
    }
    [[[UIApplication sharedApplication].delegate window] endEditing:YES];
    NSMutableArray *vcNews = [[NSMutableArray alloc] init];
    UIViewController *findVC = nil;
    for (NSString *url in urls) {
        BCRouteRequest *request = [[BCRouteRequest alloc] initWithURLStr:url];
        Class clazz = [self getRouteClassWithRequest:request];
        if (!clazz) {
            return;
        }
        findVC = [UIViewController bc_findPage:clazz];
        if (findVC) {
            for (UIViewController *vcTemp in findVC.navigationController.viewControllers) {
                if (vcTemp != findVC) {
                    [vcNews addObject:vcTemp];
                }
            }
        }
    }
    if (vcNews.count>0) {
        [findVC.navigationController setViewControllers:vcNews animated:animated];
    }
}



#pragma mark - helper
- (UIViewController *)hasRoute:(NSString *)url
{
    if (url.length<=0) {
        return nil;
    }
    BCRouteRequest *request = [[BCRouteRequest alloc] initWithURLStr:url];
    Class clazz = [self getRouteClassWithRequest:request];
    if (!clazz) {
        return nil;
    }
    UIViewController *destVC = nil;
    UIViewController *topVC = [UIViewController bc_topPage];
    NSArray *vcs = topVC.navigationController.viewControllers;
    for (UIViewController *vc in vcs) {
        if ([vc isKindOfClass:clazz]) {
            destVC = vc;
            break;
        }
    }
    return destVC;
}
-(UIViewController *)getRoute:(NSString *)url
{
    BCRouteRequest *request = [[BCRouteRequest alloc] initWithURLStr:url];
    Class clazz = [self getRouteClassWithRequest:request];
    return [self configRoutePage:clazz withRequest:request];
}

-(Class )getRouteClassWithRequest:(BCRouteRequest *)request
{
    if (request.paths.count<=0) {
        return nil;
    }
    Class findCls = nil;
    for (NSInteger i=0; i<request.paths.count; i++) {
        NSString *pathTmp = request.paths[i];
        if (pathTmp.length<=0) {
            //为空，继续下一个
            continue;
        }
        id pathData = self.routeTable[pathTmp];
        if (!pathData) {
            //没找到，继续下一个
            continue;
        } else if([pathData isKindOfClass:[NSDictionary class]]) {
            //找到了，是一个domain 域，在domain中取下一个
            NSDictionary *pathDict = (NSDictionary *)pathData;
            NSString *nextPath = nil;
            if (i>=request.paths.count-1) {
                //已经到最后一个了，取domain的默认页面，默认是index
                nextPath = kZHRoute_DomainDefaultPage;
            } else {
                nextPath = request.paths[i+1];
            }
            //取下个节点的数据
            id nextPathData = pathDict[nextPath];
            if([nextPathData isKindOfClass:[NSString class]]) {
                //找到了，下一个是route节点，直接返回
                findCls = NSClassFromString((NSString *)nextPathData);
                break;
            } else {
                //没有找到，对应domain 里没有对应子节点的信息，直接返回
                break;
            }
        } else if([pathData isKindOfClass:[NSString class]]) {
            //找到了，是一个route 节点，直接返回
            findCls = NSClassFromString((NSString *)pathData);
            break;
        }
    }
    return findCls;
}

-(UIViewController *)configRoutePage:(Class )pageCls withRequest:(BCRouteRequest *)request {
    if (!pageCls) {
        return nil;
    }
    UIViewController *controller = nil;
    if (![pageCls isSubclassOfClass:[UIViewController class]]) {
        return nil;
    }
    NSBundle *pageBundle = [NSBundle bundleForClass:pageCls];
    if (pageBundle) {
        //bundle存在,判断xib是否存在
        NSString *pageClsName = NSStringFromClass(pageCls);
        if ([pageBundle pathForResource:pageClsName ofType:@"nib"]) {
            //xib存在
            controller = [[pageCls alloc] initWithNibName:pageClsName bundle:pageBundle];
        } else {
            //xib不存在
            controller = [[pageCls alloc] init];
        }
    } else {
        //bundle 不存在
        controller = [[pageCls alloc] init];
    }
    
    
    // 设置相应的属性
    for (NSString *key in request.params.allKeys) {
        if(![key isKindOfClass:[NSString class]] || key.length<=0){
            continue;
        }
        NSString *firstWord=[[key substringToIndex:1] uppercaseString];
        NSString *otherWord=[key substringFromIndex:1];
        NSString *destMethodName = [NSString stringWithFormat:@"set%@%@:",firstWord,otherWord];
        SEL selectorDest = NSSelectorFromString(destMethodName);
        if([controller respondsToSelector:selectorDest]){
            id pValue = request.params[key];
            if ([pValue isKindOfClass:[NSString class]]) {//如果是string类型 ，需要decode
                pValue = [pValue bc_decode];
            }
            [controller setValue:pValue forKey:key];
        }
    }
    //设置扩展数据
    for (NSString *key in request.extData.allKeys) {
        if(![key isKindOfClass:[NSString class]] || key.length<=0){
            continue;
        }
        NSString *firstWord=[[key substringToIndex:1] uppercaseString];
        NSString *otherWord=[key substringFromIndex:1];
        NSString *destMethodName = [NSString stringWithFormat:@"set%@%@:",firstWord,otherWord];
        SEL selectorDest = NSSelectorFromString(destMethodName);
        if([controller respondsToSelector:selectorDest]){
            [controller setValue:request.extData[key] forKey:key];
        }
    }
    return controller;
}

- (void)returnError:(NSInteger)errcode localizedDescription:(NSString *)localizedDescription byCompletionBlock:(void(^)(NSError *error) )completion
{
    //    NSLog(@"%s", __func__);
    if (localizedDescription == nil) {
        localizedDescription = @"未知错误";
    }
    //    NSLog(@"BCRouterError: [%ld] %@", errcode, localizedDescription);
    if (completion) {
        NSError *error = [NSError errorWithDomain:BCRouterErrorDomain code:errcode userInfo:@{NSLocalizedDescriptionKey:localizedDescription}];
        completion(error);
    }
}


#pragma mark - setter
-(void)setNavClsName:(NSString *)navClsName
{
    if (navClsName.length<=0) {
        return;
    }
    _navClsName = navClsName;
    _zh_navCls = NSClassFromString(navClsName);
}

-(NSString *)routeVersion {
    if (!_routeVersion) {
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        _routeVersion = bundleInfo[@"CFBundleShortVersionString"];
    }
    return _routeVersion;
}
@end
