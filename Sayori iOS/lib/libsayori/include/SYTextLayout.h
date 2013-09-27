/*
SYTextLayout.h

Author: Makoto Kinoshita

Copyright 2010-2011 HMDT. All rights reserved.
*/

#import <objc/runtime.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "HMXML.h"
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif
#import <CoreText/CoreText.h>
#import "SYTextRun.h"
#import "SYTextStyle.h"
#if !TARGET_OS_IPHONE && TARGET_OS_MAC
#import "HMUtil.h"
#endif

@class SYTextParser;

@interface SYTextLayout : NSObject
{
    CGSize              _pageSize;
    float               _minX, _maxX;
    float               _minY, _maxY;
    
    SYTextRunContext*   _runContext;
}

// Property
@property (nonatomic) CGSize pageSize;

// Layout
- (BOOL)layoutWithParser:(SYTextParser*)parser;

@end

// Utility
BOOL SYTextLayoutIsTateChuYoko(
        SYTextRun* run, 
        SYTextInlineStyle* inlineStyle);
