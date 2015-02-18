//
//  KSHObjcUML.h
//  KSHObjcUML
//
//  Created by 金聖輝 on 15-2-18.
//  Copyright (c) 2015年 KimSungwhee. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface KSHObjcUML : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end