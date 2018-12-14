//
//  ZHWebBridgeTask.h
//  Pods
//
//  Created by YeQing on 2017/6/21.
// js 和oc交互的bridge 模型
// mark: js调用示例：window.webkit.messageHandlers.ObjName.postMessage('{"funNane":"params"}')

#import <Foundation/Foundation.h>

@class WKScriptMessage;

@interface ZHWebBridgeTask : NSObject
@property (nonatomic, strong) NSString      *ObjName;//js 和oc交互的bridge 对象名称
@property (nonatomic, strong) NSString      *selectorName;//js 和oc交互的方法 name

/**
 bridge 需要做的事情
 */
@property (nonatomic, copy) void(^bridgeAction)(id msgBody);
@end
