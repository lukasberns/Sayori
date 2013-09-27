/*
NSValueAddition.m

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import "NSValueAddition.h"

@implementation NSValue (UIKitAddition)

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (NSValue*)valueWithCGRect:(CGRect)rect
{
    // Create value with NSRect
    return [NSValue valueWithRect:NSRectFromCGRect(rect)];
}

//--------------------------------------------------------------//
#pragma mark -- Getting value --
//--------------------------------------------------------------//

- (CGRect)CGRectValue
{
    // Get rect value and convert to CGRect
    return NSRectToCGRect([self rectValue]);
}

@end
