/*
NSValueAddition.h

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@interface NSValue (UIKitAddition)

// Initialize
+ (NSValue*)valueWithCGRect:(CGRect)rect;

// Getting value
- (CGRect)CGRectValue;

@end
