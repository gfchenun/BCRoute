//
//  BCRouteRequest.m
//  Pod
//
//  Created by green on 17/3/30.
//  Copyright © 2017年 green. All rights reserved.
//

#import "BCRouteRequest.h"
#import "BCRouteKitPrivate.h"
#import "BCRouteKitPublic.h"
#import "NSDictionary+BCRouteHelper.h"


@implementation BCRouteRequest
#pragma mark - system
- (instancetype) initWithURLStr:(NSString *)urlString
{
    self = [super init];
    if (self) {
        _urlString = urlString;
        [self bc_parseURL:urlString];
    }
    return self;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"BCRouteRequest dealloc");
#endif
}


#pragma mark - getter
-(NSInteger)transitType
{
    NSInteger transitType = [self.params[kBCRouteTable_TransitKey] integerValue];
    return transitType;
}

- (BOOL )rootPush
{
    BOOL rootPush = [self.params[kBCRouteTable_RootPushKey] boolValue];
    return rootPush;
}

-(void)setExtData:(NSDictionary *)extData {
    _extData = extData;
    //保存所有的参数
    if (!_extData) {
        _allParams = self.params;
    } else {
        NSMutableDictionary *allParmasTmp = [[NSMutableDictionary alloc] init];
        if (self.params) {
            [allParmasTmp addEntriesFromDictionary:self.params];
        }
        [allParmasTmp addEntriesFromDictionary:_extData];
        _allParams = allParmasTmp;
    }
}

#pragma mark - helper

- (void)bc_parseURL:(NSString *)urlString
{
    if (urlString.length <=0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    if (url == nil) {
        return;
    }
    // 找到参数
    NSString *query = [url query];
    _params = [NSDictionary zh_dictionaryWithParamString:query];
    // 找到path
    NSString *path = [url path];
    if ([path hasPrefix:@"/"]) {
        //去除第一个/
        path = [path substringFromIndex:1];
    }
    NSMutableArray *mPaths = [[path componentsSeparatedByString:@"/"] mutableCopy];
    if ([mPaths.firstObject isEqualToString:@"ios"]) {
        [mPaths removeObjectAtIndex:0];
    }
    if (mPaths.count > 2) {
        NSString *key = [[mPaths lastObject] copy];
        [mPaths removeLastObject];
        NSString *domain = [mPaths componentsJoinedByString:@"/"];
        _paths = @[domain,key];
        
    }else{
        _paths = [mPaths copy];
    }
}
@end
