//
//  BCRouteResponse.m
//  Pod
//
//  Created by green on 17/3/30.
//  Copyright © 2017年 green. All rights reserved.
//

#import "BCRouteResponse.h"

@implementation BCRouteResponse

- (instancetype)initWithUrl:(NSString *)url statusCode:(NSInteger)statusCode
{
    self = [super init];
    if (self) {
        _url = url;
        _statusCode = statusCode;
        _source = nil;
        _target = nil;
    }
    return self;
}

@end
