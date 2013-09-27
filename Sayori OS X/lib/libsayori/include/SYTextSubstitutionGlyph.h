/*
SYTextSubstitutionGlyph.h

Author: Makoto Kinoshita

Copyright 2010 HMDT. All rights reserved.
*/

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

NSArray* SYTextAltKanjiSubstitutionGlyphsWithGlyph(
        NSString* fontName, 
        CGGlyph glyph);
CGGlyph SYTextVerticalSubstitutionGlyphWithGlyph(
        NSString* fontName, 
        CGGlyph glyph);
