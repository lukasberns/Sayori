/*
SYFontManager.m

Author: Makoto Kinoshita, Hajime Nakamura

Copyright 2010-2013 HMDT. All rights reserved.
*/

#import "SYFontManager.h"
#import "SYTextStyle.h"

static float                _defaultFontSize = 18.0f;
static NSString*            _defaultFontName = @"HiraMinProN-W3";

@implementation SYFontManager
{
    NSMutableDictionary*    _ctFontCache;
    
    float                _ctFontSize;
    NSString*            _ctFontName;
    CTFontRef            _ctFont;
    SYTextInlineStyle*   _cgInlineStyle;
    NSString*            _cgFontName;
    CGFontRef            _cgFont;
}

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Initialize instance variables
    _ctFontCache = [NSMutableDictionary dictionary];
    
    return self;
}

//--------------------------------------------------------------//
#pragma mark -- Font --
//--------------------------------------------------------------//

- (NSString*)fontNameWithFamilyName:(int)familyName 
        weight:(int)weight character:(unichar)character
{
    // Decide bold or not
    BOOL    bold;
    if (weight == SYStyleFontWeightBolder) {
        bold = YES;
    }
    else if (weight == SYStyleFontWeightLighter) {
        bold = NO;
    }
    else {
        bold = weight >= SYStyleFontWeightBold;
    }
    
    // Decide font name
    NSString*   fontName = nil;
    
    // For serif
    if (familyName == SYStyleFontFamilySerif) {
        // For bold
        if (bold) {
            fontName = @"HiraMinProN-W6";
        }
        // For other
        else {
            fontName = @"HiraMinProN-W3";
        }
    }
    // For sans serif
    else if (familyName == SYStyleFontFamilySansSerif) {
        // For bold
        if (bold) {
            fontName = @"HiraKakuProN-W6";
        }
        // For other
        else {
            fontName = @"HiraKakuProN-W3";
        }
    }
    // For monospace
    else if (familyName == SYStyleFontFamilyMonospace) {
        // For Non-ASCII
        if (character > 255) {
            // For bold
            if (bold) {
                fontName = @"HiraKakuProN-W6";
            }
            // For other
            else {
                fontName = @"HiraKakuProN-W3";
            }
        }
        // For bold
        else if (bold) {
            fontName = @"Courier-Bold";
        }
        // For other
        else {
            fontName = @"Courier";
        }
    }
    
    // Use default
    if (!fontName) {
        fontName = @"HiraKakuProN-W3";
    }
    
    return fontName;
}

- (NSString*)fontNameWithStyle:(SYTextInlineStyle*)style 
        character:(unichar)character
{
    // Get font name
    NSString*   fontName;
    fontName = [self fontNameWithFamilyName:style->fontFamily weight:style->fontWeight character:character];
    
    return fontName;
}

- (CTFontRef)ctFontWithStyle:(SYTextInlineStyle*)style 
        character:(unichar)character
{
    // Get font size
    float   fontSize = 0;
    if (style) {
        fontSize = style->fontSize;
    }
    if (fontSize == 0) {
        fontSize = _defaultFontSize;
    }
    
    // Get font name
    NSString*   fontName = _defaultFontName;
    if (style) {
        fontName = [self fontNameWithStyle:style character:character];
    }
    
#if 0
    // Find in cache
    NSString*   key;
    CTFontRef   ctFont;
    key = [NSString stringWithFormat:@"%@_%f", fontName, fontSize];
    ctFont = (CTFontRef)[[_ctFontCache objectForKey:key] unsignedIntegerValue];
    if (!ctFont) {
        // Create ct font
        ctFont = CTFontCreateWithName((__bridge CFStringRef)(fontName), fontSize, NULL);
        
        // Cache ct font
        [_ctFontCache setObject:[NSNumber numberWithUnsignedInt:(unsigned int)ctFont] forKey:key];
    }
    
    return ctFont;
#else
    // Compare with previous
    if (fontSize == _ctFontSize && 
        [fontName isEqualToString:_ctFontName])
    {
        return _ctFont;
    }
    
    // Release old font
    if (_ctFont) {
        CFRelease(_ctFont);
    }
    
    // Create font
    //_ctFont = CTFontCreateWithName((CFStringRef)CFBridgingRetain(fontName), fontSize, NULL);
    _ctFont = CTFontCreateWithName((__bridge CFStringRef)(fontName), fontSize, NULL);
    
    return _ctFont;
#endif
}

- (CGFontRef)cgFontWithStyle:(SYTextInlineStyle*)style 
        character:(unichar)character
{
    // Check style
    if (style == _cgInlineStyle && 
        style->fontFamily != SYStyleFontFamilyMonospace)
    {
        return _cgFont;
    }
    
    // Set style
    _cgInlineStyle = style;
    
    // Get font name
    NSString*   fontName;
    fontName = [self fontNameWithFamilyName:style->fontFamily weight:style->fontWeight character:character];
    
    // Compare with previous
    if ([fontName isEqualToString:_cgFontName]) {
        return _cgFont;
    }
    
    // Release old font
    if (_cgFont) {
        CGFontRelease(_cgFont);
    }
    
    // Create font
    _cgFont = CGFontCreateWithFontName((__bridge CFStringRef)(fontName));
    
    return _cgFont;
}

@end
