/*
SYTextStyle.h

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

enum SYStyleUnit {
	SYStyleUnitPX = 0x0,
	SYStyleUnitEX = 0x1,
	SYStyleUnitEM = 0x2,
	SYStyleUnitIN = 0x3,
	SYStyleUnitCM = 0x4,
	SYStyleUnitMM = 0x5,
	SYStyleUnitPT = 0x6,
	SYStyleUnitPC = 0x7,

	SYStyleUnitPCT = 0x8,	/* Percentage */

	SYStyleUnitDEG = 0x9,
	SYStyleUnitGRAD = 0xa,
	SYStyleUnitRAD = 0xb,

	SYStyleUnitMS = 0xc,
	SYStyleUnitS = 0xd,

	SYStyleUnitHZ = 0xe,
	SYStyleUnitKHZ = 0xf
};

enum {
    SYStyleFontFamilySerif = 0, 
    SYStyleFontFamilySansSerif, 
    SYStyleFontFamilyCursive, 
    SYStyleFontFamilyMonospace, 
    SYStyleFontFamilyFantasy, 
};

enum {
    SYStyleFontStyleNormal = 0, 
    SYStyleFontStyleItalic, 
    SYStyleFontStyleOblique, 
};

enum {
    SYStyleFontVariantNormal = 0, 
    SYStyleFontVariantSmallCaps, 
};

enum {
    SYStyleFontWeightNormal = 400, 
    SYStyleFontWeightBold = 600, 
    SYStyleFontWeightBolder = 99998, 
    SYStyleFontWeightLighter = 99999, 
};

enum {
    SYStyleClearNone = 0, 
    SYStyleClearLeft, 
    SYStyleClearRight, 
    SYStyleClearBoth, 
};

enum {
    SYStyleBorderStyleNone = 1, 
    SYStyleBorderStyleHidden = 2, 
    SYStyleBorderStyleDotted = 3, 
    SYStyleBorderStyleDashed = 4, 
    SYStyleBorderStyleSolid = 5, 
    SYStyleBorderStyleDouble = 6, 
    SYStyleBorderStyleGroove = 7, 
    SYStyleBorderStyleRidge = 8, 
    SYStyleBorderStyleInset = 9, 
    SYStyleBorderStyleOutset = 10, 
};

enum {
    SYStyleTextAlignLeft = 0, 
    SYStyleTextAlignCenter, 
    SYStyleTextAlignRight, 
    SYStyleTextAlignJustify, 
};

enum {
    SYStyleVerticalAlignBaseLine = 0, 
    SYStyleVerticalAlignMiddle, 
    SYStyleVerticalAlignSub, 
    SYStyleVerticalAlignSuper, 
    SYStyleVerticalAlignTextTop, 
    SYStyleVerticalAlignTextBottom, 
    SYStyleVerticalAlignTop, 
    SYStyleVerticalAlignBottom, 
};

enum {
    SYStyleFloatNone = 0, 
    SYStyleFloatLeft, 
    SYStyleFloatRight, 
};

enum {
    SYStyleWritingModeLrTb = 0, // Horizontal: Left－right, Top－bottom
    SYStyleWritingModeTbRl = 1, // Vertiacal:  Top－bottom, Right－left
};

typedef struct {
    unsigned short  colorRed;
    unsigned short  colorGreen;
    unsigned short  colorBlue;
    unsigned short  colorAlpha;
} SYTextColor;

typedef struct {
    float           width;
    float           value;
    unsigned char   unit;
    unsigned short  style;
    SYTextColor     color;
} SYTextBorder;

typedef struct {
    SYTextColor     color;
    unsigned short  fontFamily;
    unsigned short  fontStyle;
    unsigned short  fontVariant;
    unsigned int    fontWeight;
    float           fontSize;
    const char*     fontName;
    float           letterSpacing;
    float           lineHeight;
    unsigned short  verticalAlign;
    unsigned short  floatMode;
    unsigned short  writingMode;
    BOOL            originalSpelling;
    
    SYTextBorder    borderTop;
    SYTextBorder    borderRight;
    SYTextBorder    borderLeft;
    SYTextBorder    borderBottom;
    
    float           ascent;
    float           descent;
    
    void*           baseRun;
    NSURL* __unsafe_unretained  linkUrl;
} SYTextInlineStyle;

typedef struct {
    SYTextColor     backgroundColor;
    float           marginTop;
    unsigned char   marginTopUnit;
    float           marginRight;
    unsigned char   marginRightUnit;
    float           marginLeft;
    unsigned char   marginLeftUnit;
    float           marginBottom;
    unsigned char   marginBottomUnit;
    float           paddingTop;
    unsigned char   paddingTopUnit;
    float           paddingRight;
    unsigned char   paddingRightUnit;
    float           paddingLeft;
    unsigned char   paddingLeftUnit;
    float           paddingBottom;
    unsigned char   paddingBottomUnit;
    unsigned short  textAlign;
    float           width;
    unsigned char   widthUnit;
    float           height;
    unsigned char   heightUnit;
    
    SYTextBorder    borderTop;
    SYTextBorder    borderRight;
    SYTextBorder    borderLeft;
    SYTextBorder    borderBottom;
    
    unsigned short  writingMode;
    
    unsigned int    tableCellPadding;
    unsigned int    tableCellSpacing;
} SYTextBlockStyle;

#define SY_INLINESTACK_MAX 256

typedef struct {
    SYTextInlineStyle*  styles[SY_INLINESTACK_MAX];
    SYTextInlineStyle** currentStyle;
} SYTextInlineStyleStack;

typedef struct {
    SYTextBlockStyle*   styles[SY_INLINESTACK_MAX];
    SYTextBlockStyle**  currentStyle;
} SYTextBlockStyleStack;

// Functions
SYTextInlineStyleStack* SYTextInlineStyleStackCreate();
void SYTextInlineStyleStackRelease(
        SYTextInlineStyleStack* inlineStyleStack);
void SYTextInlineStyleStackPush(
        SYTextInlineStyleStack* inlineStyleStack, 
        SYTextInlineStyle* inlineStyle);
SYTextInlineStyle* SYTextInlineStyleStackPop(
        SYTextInlineStyleStack* inlineStyleStack);

SYTextBlockStyleStack* SYTextBlockStyleStackCreate();
void SYTextBlockStyleStackRelease(
        SYTextBlockStyleStack* blockStyleStack);
void SYTextBlockStyleStackPush(
        SYTextBlockStyleStack* blockStyleStack, 
        SYTextBlockStyle* blockStyle);
SYTextBlockStyle* SYTextBlockStyleStackPop(
        SYTextBlockStyleStack* blockStyleStack);

// Unit value
float SYStyleCalcUnitValue(
        float value, 
        unsigned char unit, 
        float wide, 
        float fontSize);
float SYStyleMarginTop(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);
float SYStyleMarginRight(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);
float SYStyleMarginLeft(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);
float SYStyleMarginBottom(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);
float SYStylePaddingTop(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);
float SYStylePaddingRight(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);
float SYStylePaddingLeft(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);
float SYStylePaddingBottom(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide);

#if TARGET_OS_IPHONE
UIColor* SYStyleColor(
#elif TARGET_OS_MAC
NSColor* SYStyleColor(
#endif
        SYTextColor* textColor);
