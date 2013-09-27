/*
UIKitFunction.h

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

// String Conversions
CGPoint CGPointFromString(
        NSString* string);
CGSize CGSizeFromString(
        NSString* string);
CGRect CGRectFromString(
        NSString* string);
NSString* NSStringFromCGPoint(
        CGPoint point);
NSString* NSStringFromCGSize(
        CGSize size);
NSString* NSStringFromCGRect(
        CGRect rect);
