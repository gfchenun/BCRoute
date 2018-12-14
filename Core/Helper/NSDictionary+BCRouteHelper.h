//
//  NSDictionary+ParamterString.h
//  BalanceAssistant
//
//  Created by green on 28/07/2017.
//  Copyright © 2017 green. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (BCRouteHelper)

- (NSString *)zh_paramString;
+ (instancetype)zh_dictionaryWithParamString:(NSString *)zh_paramString;

@end
