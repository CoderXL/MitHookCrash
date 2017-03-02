//
//  NSTimer+MitCrash.m
//  CrashHook
//
//  Created by MENGCHEN on 2017/3/1.
//  Copyright © 2017年 MENGCHEN. All rights reserved.
//

#import "NSTimer+MitCrash.h"
#import "NSObject+MethodSwizz.h"
#import "MitTimerSubOBJ.h"
#import "MitCrashHandler.h"
#import <objc/runtime.h>
@implementation NSTimer (MitCrash)
+(void)load{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [NSObject swizzleMethod:[self class] origin:@selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:) new:@selector(MitCrash_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:)];
//        Class cls = [self class];
//        if(class_addMethod(cls, @selector(MitCrash_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:),class_getMethodImplementation(cls, @selector(MitCrash_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:)), "#d@:@B")){
//            //原来的方法
//            Method dis_originalMethod = class_getInstanceMethod(cls,@selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:));
//            //现在的方法
//            Method dis_swizzledMethod = class_getInstanceMethod(cls, @selector(MitCrash_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:));
//            //交换实现
//            method_exchangeImplementations(dis_originalMethod, dis_swizzledMethod);
//        }
//    });
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError * err = nil;
        [self swizzleClassMethod:@selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:) withClassMethod:@selector(MitCrash_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:) error:&err];
        if (err) {
            NSLog(@"替换错误 = %@",err);
        }
    });
}



#pragma mark action 替换方法
+ (NSTimer *)MitCrash_scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo{
    if (!yesOrNo) {
        return [self MitCrash_scheduledTimerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
    } else {
        MitTimerSubOBJ * obj = [MitTimerSubOBJ new];
        obj.target = aTarget;
        obj.selector = NSStringFromSelector(aSelector);
        //针对 timer 的循环引用是由于， timer 会强引用 target，这时创建中间类，中间类作为 timer 的 target，中间类保留原始 target 的一个弱引用，这时如果target 释放掉了，那么中间类会发现没有 target，那么就回调，解除定时器
        NSTimer * timer = [NSTimer MitCrash_scheduledTimerWithTimeInterval:ti target:obj selector:@selector(forward) userInfo:userInfo repeats:yesOrNo];
        __weak NSTimer * wTimer = timer;
        __weak typeof(self) weakSelf = self;
        obj.callBack = ^(BOOL isinvalidate){
            __strong typeof(self) strongSelf = weakSelf;
            __strong NSTimer * STimer = wTimer;
            if (strongSelf) {
                [MitCrashHandler handleCrashCls:[self class] message:@"NSTimer 没释放" sel:_cmd];
            }else{
                [MitCrashHandler handleCrashCls:[self class] message:@"NSTimer 没释放" sel:_cmd];
            }
            if (STimer) {
                [STimer invalidate];
                STimer = nil;
            }
        };
        return timer;
    }
    return nil;
}

@end