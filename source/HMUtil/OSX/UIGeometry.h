/*
UIGeometry.h

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

// Structs
typedef struct UIEdgeInsets {
    CGFloat top, left, bottom, right;
} UIEdgeInsets;

// Insets
BOOL UIEdgeInsetsEqualToEdgeInsets (
        UIEdgeInsets insets1,
        UIEdgeInsets insets2);
