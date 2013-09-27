/*
SYTextStyle.m

Author: Makoto Kinoshita, Hajime Nakamura

Copyright 2010-2013 HMDT. All rights reserved.
*/

#import "SYTextStyle.h"

//--------------------------------------------------------------//
#pragma mark -- Functions --
//--------------------------------------------------------------//

SYTextInlineStyleStack* SYTextInlineStyleStackCreate()
{
    // Allocate inline style stack
    SYTextInlineStyleStack* inlineStyleStack;
    inlineStyleStack = malloc(sizeof(SYTextInlineStyleStack));
    
    // Initialize inline style stack
    inlineStyleStack->currentStyle = inlineStyleStack->styles;
    
    return inlineStyleStack;
}

void SYTextInlineStyleStackRelease(
        SYTextInlineStyleStack* inlineStyleStack)
{
    // Check argument
    if (!inlineStyleStack) {
        return;
    }
    
    // Free inline style stack
    free(inlineStyleStack);
}

void SYTextInlineStyleStackPush(
        SYTextInlineStyleStack* inlineStyleStack, 
        SYTextInlineStyle* inlineStyle)
{
    // Check count
    if (inlineStyleStack->currentStyle - inlineStyleStack->styles >= SY_INLINESTACK_MAX - 1) {
        NSLog(@"Stack exceeds limit");
        
        return;
    }
    
    // Push inline style
    *(inlineStyleStack->currentStyle) = inlineStyle;
    inlineStyleStack->currentStyle++;
}

SYTextInlineStyle* SYTextInlineStyleStackPop(
        SYTextInlineStyleStack* inlineStyleStack)
{
    // Check current style
    if (inlineStyleStack->currentStyle == inlineStyleStack->styles) {
        return NULL;
    }
    
    // Pop inline style
    inlineStyleStack->currentStyle--;
    
    return *(inlineStyleStack->currentStyle);
}

SYTextBlockStyleStack* SYTextBlockStyleStackCreate()
{
    // Allocate block style stack
    SYTextBlockStyleStack*  blockStyleStack;
    blockStyleStack = malloc(sizeof(SYTextBlockStyleStack));
    
    // Initialize block style stack
    blockStyleStack->currentStyle = blockStyleStack->styles;
    
    return blockStyleStack;
}

void SYTextBlockStyleStackRelease(
        SYTextBlockStyleStack* blockStyleStack)
{
    // Check argument
    if (!blockStyleStack) {
        return;
    }
    
    // Free inline style stack
    free(blockStyleStack);
}

void SYTextBlockStyleStackPush(
        SYTextBlockStyleStack* blockStyleStack, 
        SYTextBlockStyle* blockStyle)
{
    // Check count
    if (blockStyleStack->currentStyle - blockStyleStack->styles >= SY_INLINESTACK_MAX - 1) {
        NSLog(@"Stack exceeds limit");
        
        return;
    }
    
    // Push block style
    *(blockStyleStack->currentStyle) = blockStyle;
    blockStyleStack->currentStyle++;
}

SYTextBlockStyle* SYTextBlockStyleStackPop(
        SYTextBlockStyleStack* blockStyleStack)
{
    // Check current style
    if (blockStyleStack->currentStyle == blockStyleStack->styles) {
        return NULL;
    }
    
    // Pop block style
    blockStyleStack->currentStyle--;
    
    return *(blockStyleStack->currentStyle);
}

//--------------------------------------------------------------//
#pragma mark -- Unit value --
//--------------------------------------------------------------//

float SYStyleCalcUnitValue(
        float value, 
        unsigned char unit, 
        float relative, 
        float fontSize)
{
    // For em
    if (unit == SYStyleUnitEM) {
        return value * fontSize;
    }
    
    // For percentage
    if (unit == SYStyleUnitPCT) {
        return value * (relative / 100);
    }
    
    return value;
}

inline float SYStyleMarginTop(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->marginTop, 
            blockStyle->marginTopUnit, 
            wide, 
            inlineStyle->fontSize);
}

inline float SYStyleMarginRight(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->marginRight, 
            blockStyle->marginRightUnit, 
            wide, 
            inlineStyle->fontSize);
}

inline float SYStyleMarginLeft(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->marginLeft, 
            blockStyle->marginLeftUnit, 
            wide, 
            inlineStyle->fontSize);
}

inline float SYStyleMarginBottom(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->marginBottom, 
            blockStyle->marginBottomUnit, 
            wide, 
            inlineStyle->fontSize);
}

inline float SYStylePaddingTop(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->paddingTop, 
            blockStyle->paddingTopUnit, 
            wide, 
            inlineStyle->fontSize);
}

inline float SYStylePaddingRight(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->paddingRight, 
            blockStyle->paddingRightUnit, 
            wide, 
            inlineStyle->fontSize);
}

inline float SYStylePaddingLeft(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->paddingLeft, 
            blockStyle->paddingLeftUnit, 
            wide, 
            inlineStyle->fontSize);
}

inline float SYStylePaddingBottom(
        SYTextBlockStyle* blockStyle, 
        SYTextInlineStyle* inlineStyle, 
        float wide)
{
    return SYStyleCalcUnitValue(
            blockStyle->paddingBottom, 
            blockStyle->paddingBottomUnit, 
            wide, 
            inlineStyle->fontSize);
}

#if TARGET_OS_IPHONE
UIColor* SYStyleColor(
        SYTextColor* textColor)
#elif TARGET_OS_MAC
NSColor* SYStyleColor(
        SYTextColor* textColor)
#endif
{
    // Convert color
#if TARGET_OS_IPHONE
    UIColor*    color;
    color = [UIColor colorWithRed:textColor->colorRed / 255.0f 
            green:textColor->colorGreen / 255.0f 
            blue:textColor->colorBlue / 255.0f
            alpha:textColor->colorAlpha / 255.0f];
#elif TARGET_OS_MAC
    NSColor*    color;
    color = [NSColor colorWithCalibratedRed:textColor->colorRed / 255.0f 
            green:textColor->colorGreen / 255.0f 
            blue:textColor->colorBlue / 255.0f
            alpha:textColor->colorAlpha / 255.0f];
#endif
    
    return color;
}
