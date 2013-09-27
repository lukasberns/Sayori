/*
UIKitFunction.m

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import "UIKitFunction.h"

//--------------------------------------------------------------//
#pragma mark -- String Conversions --
//--------------------------------------------------------------//

CGPoint CGPointFromString(
        NSString* string)
{
    return NSPointToCGPoint(NSPointFromString(string));
}

CGSize CGSizeFromString(
        NSString* string)
{
    return NSSizeToCGSize(NSSizeFromString(string));
}

CGRect CGRectFromString(
        NSString* string)
{
    return NSRectToCGRect(NSRectFromString(string));
}

NSString* NSStringFromCGPoint(
        CGPoint point)
{
    return NSStringFromPoint(NSPointFromCGPoint(point));
}

NSString* NSStringFromCGSize(
        CGSize size)
{
    return NSStringFromSize(NSSizeFromCGSize(size));
}

NSString* NSStringFromCGRect(
        CGRect rect)
{
    return NSStringFromRect(NSRectFromCGRect(rect));
}
