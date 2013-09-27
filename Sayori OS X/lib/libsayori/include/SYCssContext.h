/*
SYCssContext.h

Author: Makoto Kinoshita

Copyright 2010-2011 HMDT. All rights reserved.
*/

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "HMXML.h"
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif
#import "fpmath.h"
#import "types.h"
#import "select.h"
#import "stylesheet.h"
#import "SYTextStyle.h"

typedef struct {
    css_select_ctx* context;
    
    float           baseFontSize;
} SYCssContext;

SYCssContext* SYCssContextCreate();
void SYCssContextRelease(
        SYCssContext* cssContext);
void SYCssContextSetBaseFontSize(
        SYCssContext* cssContext, 
        float baseFontSize);
void SYCssContextAddStylesheetData(
        SYCssContext* cssContext, 
        NSData* data);
void SYCssContextSelectStyle(
        SYCssContext* cssContext, 
#if TARGET_OS_IPHONE
        HMXMLNode* node, 
#elif TARGET_OS_MAC
        NSXMLNode* node, 
#endif
        int writingMode, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle);

@interface SYCss : NSObject
{
    NSData*         _cssData;
    float           _baseFontSize;
    
    BOOL            _needsToParse;
    SYCssContext*   _cssContext;
    
    NSMutableDictionary*    _cacheDict;
}

// Property
@property (nonatomic) NSData* cssData;
@property (nonatomic) float baseFontSize;
@property (nonatomic, readonly) SYCssContext* cssContext;

// Cache
#ifdef CACHE_AND_NO_COPY
#if TARGET_OS_IPHONE
- (BOOL)cachedInlinStyle:(SYTextInlineStyle**)outInlineStyle
        blockStyle:(SYTextBlockStyle**)outBlockStyle 
        forNode:(HMXMLNode*)node;
#elif TARGET_OS_MAC
- (BOOL)cachedInlinStyle:(SYTextInlineStyle**)outInlineStyle
        blockStyle:(SYTextBlockStyle**)outBlockStyle 
        forNode:(NSXMLNode*)node;
#endif
#else
#if TARGET_OS_IPHONE
- (BOOL)cachedInlinStyle:(SYTextInlineStyle*)inlineStyle 
        blockStyle:(SYTextBlockStyle*)blockStyle 
        forNode:(HMXMLNode*)node 
        writingMode:(int)writingMode;
#elif TARGET_OS_MAC
- (BOOL)cachedInlinStyle:(SYTextInlineStyle*)inlineStyle 
        blockStyle:(SYTextBlockStyle*)blockStyle 
        forNode:(NSXMLNode*)node 
        writingMode:(int)writingMode;
#endif
#endif
#if TARGET_OS_IPHONE
- (void)cacheInlinStyle:(SYTextInlineStyle*)inlineStyle 
        blockStyle:(SYTextBlockStyle*)blockStyle 
        forNode:(HMXMLNode*)node
        writingMode:(int)writingMode;
#elif TARGET_OS_MAC
- (void)cacheInlinStyle:(SYTextInlineStyle*)inlineStyle 
        blockStyle:(SYTextBlockStyle*)blockStyle 
        forNode:(NSXMLNode*)node
        writingMode:(int)writingMode;
#endif

@end

