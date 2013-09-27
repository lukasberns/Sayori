/*
SYTextParser.h

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
#import "SYTextRun.h"
#import "SYTextStyle.h"

@class SYCss;

@interface SYTextParser : NSObject
{
    NSData*                 _htmlData;
    NSData*                 _cssData;
    SYCss*                  _css;
    float                   _baseFontSize;
    int                     _numberOfLines;
    int                     _writingMode;
    float                   _rowHeightForVertical;
    float                   _rowMarginForVertical;
    NSArray*                _floatRects;
    BOOL                    _ignoreBlock;
    float                   _hangingIndent;
    SYTextRunContext*       _runContext;
}

// Property
@property (nonatomic) NSData* htmlData;
@property (nonatomic) NSData* cssData;
@property (nonatomic) SYCss* css;
@property (nonatomic) float baseFontSize;
@property (nonatomic) int numberOfLines;
@property (nonatomic) int writingMode;
@property (nonatomic) float rowHeightForVertical;
@property (nonatomic) float rowMarginForVertical;
@property (nonatomic) NSArray* floatRects;
@property (nonatomic) float hangingIndent;
@property (nonatomic) BOOL ignoreBlock;
@property (nonatomic, readonly) SYTextRunContext* runContext;

// Parse
- (BOOL)parse;

@end
