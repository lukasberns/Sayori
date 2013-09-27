/*
SYFontManager.h

Author: Makoto Kinoshita

Copyright 2010-2013 HMDT. All rights reserved.
*/

#import <objc/runtime.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "HMXML.h"
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif
#import <CoreText/CoreText.h>
#import "SYTextStyle.h"

@interface SYFontManager : NSObject

// Font
- (NSString*)fontNameWithFamilyName:(int)familyName 
        weight:(int)weight character:(unichar)character;
- (NSString*)fontNameWithStyle:(SYTextInlineStyle*)style 
        character:(unichar)character;
- (CTFontRef)ctFontWithStyle:(SYTextInlineStyle*)style 
        character:(unichar)character;
- (CGFontRef)cgFontWithStyle:(SYTextInlineStyle*)style 
        character:(unichar)character;

@end
