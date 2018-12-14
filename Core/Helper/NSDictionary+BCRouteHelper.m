//
//  NSDictionary+ParamterString.m
//  BalanceAssistant
//
//  Created by green on 28/07/2017.
//  Copyright © 2017 green. All rights reserved.
//

#import "NSDictionary+BCRouteHelper.h"

@implementation NSDictionary (BCRouteHelper)

- (NSString *)zh_paramString
{
    if (self.allKeys.count == 0) {
        return @"";
    }
    
    NSString *result = nil;
    NSMutableString *muString = [NSMutableString string];
    for (NSString *key in self.allKeys) {
        NSString *value = self[key];
        [muString appendFormat:@"&%@=%@", key, [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    if (muString.length > 1) {
        result = [muString substringFromIndex:1];
    }
    return result;
}

+ (instancetype)zh_dictionaryWithParamString:(NSString *)zh_paramString
{
    if (zh_paramString == nil || [zh_paramString isEqualToString:@""]) {
        return nil;
    }
    NSArray *aArr = [zh_paramString componentsSeparatedByString:@"&"];
    NSMutableArray *mArr = [[NSMutableArray alloc] init];
    for (NSString *string in aArr) {
        NSArray *strArr = [string componentsSeparatedByString:@"?"];
        if (strArr.count > 0) {
            [mArr addObjectsFromArray:strArr];
        }
    }
    NSMutableDictionary *parameterDict = [NSMutableDictionary dictionary];
    for (int i = 0; i < mArr.count; i++) {
        NSArray *str = [mArr[i] componentsSeparatedByString:@"="];
        if (str.count == 2) {
            NSString *value = str[1];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [parameterDict setObject:value forKey:str[0]];
        }
        else if (str.count > 2){
            
            NSMutableString *appending = [[NSMutableString alloc] initWithCapacity:0];
            for (NSUInteger j = str.count - 1; j == 1; j--) {
                [appending appendString:str[j]];
            }
            
            NSString *value = [appending copy];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [parameterDict setObject:value forKey:str[0]];
        }
        else {
            NSLog(@"没有等号的参数跳过");
        }
    }
    
    return [parameterDict copy];
}

@end
