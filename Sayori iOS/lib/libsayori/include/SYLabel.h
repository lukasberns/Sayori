/*
SYLabel.h

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "SYTextRun.h"
#if TARGET_OS_MAC
#import "HMUtil.h"
#endif

extern int  SYLabelSelectionView;

@class SYCss;

#if TARGET_OS_IPHONE
@interface SYLabel : UIView <UIGestureRecognizerDelegate>
#elif TARGET_OS_MAC
@interface SYLabel : NSView
#endif

// Property
@property (nonatomic) NSString* html;
@property (nonatomic) NSString* cssString;
@property (nonatomic) SYCss* css;
@property (nonatomic, readonly) NSString* text;
@property (nonatomic) int numberOfLines;
@property (nonatomic) int writingMode;
@property (nonatomic) float outlineWidth;
#if TARGET_OS_IPHONE
@property (nonatomic) UIColor* outlineColor;
@property (nonatomic) UIColor* linkHighlightColor;
@property (nonatomic) UIColor* selectedBackgroundColor;
#elif TARGET_OS_MAC
@property (nonatomic) NSColor* outlineColor;
@property (nonatomic) NSColor* linkHighlightColor;
@property (nonatomic) NSColor* selectedBackgroundColor;
#endif
@property (nonatomic) float hangingIndent;
@property (nonatomic) float rowHeightForVertical;
@property (nonatomic) float rowMarginForVertical;
@property (nonatomic) BOOL ignoreBlock;
@property (nonatomic) NSArray* floatRects;
@property (nonatomic, readonly) SYTextRunContext* runContext;
@property (nonatomic) BOOL selectable;
@property (nonatomic, readonly) SYTextRun* beginSelectedRun;
@property (nonatomic, readonly) SYTextRun* endSelectedRun;
@property (nonatomic, readonly) CGRect selectedRect;
@property (nonatomic, readonly) NSString* selectedText;
@property (nonatomic, readonly) NSArray* selectedViews;
@property (nonatomic, weak) id delegate;

// Run
- (SYTextRun*)runAtPoint:(CGPoint)point;
- (NSString*)textBetweenBeginRun:(SYTextRun*)beginRun endRun:(SYTextRun*)endRun;
- (NSArray*)runRectsBetweenBeginRun:(SYTextRun*)beginRun endRun:(SYTextRun*)endRun 
        containsLineHeight:(BOOL)lineHeight;
- (void)selectTextBetweenPoint0:(CGPoint)point0 point1:(CGPoint)point1;
- (void)deselectText;

// Geometry
+ (CGSize)sizeWithConstrainedToSize:(CGSize)size 
        html:(NSString*)html css:(SYCss*)css;
+ (CGSize)sizeWithConstrainedToSize:(CGSize)size 
        html:(NSString*)html 
        css:(SYCss*)css 
        numberOfLines:(int)numberOfLines 
        writingMode:(int)writingMode 
        rowHeightForVertical:(float)rowHeightForVertical 
        rowMarginForVertical:(float)rowMarginForVertical 
        floatRects:(NSArray*)floatRects 
        ignoreBlock:(BOOL)ignoreBlock;
- (CGSize)sizeWithConstrainedToSize:(CGSize)size;

@end

@interface NSObject (SYLabelDelegate)

- (BOOL)label:(SYLabel*)label shouldSelectLink:(NSURL*)url 
        beginRun:(SYTextRun*)beginRun endRun:(SYTextRun*)endRun;
- (void)label:(SYLabel*)label linkTapped:(NSURL*)url 
        beginRun:(SYTextRun*)beginRun endRun:(SYTextRun*)endRun;
#if TARGET_OS_IPHONE
- (void)label:(SYLabel*)label longPressed:(UILongPressGestureRecognizer*)recognizer;
#endif

@end
