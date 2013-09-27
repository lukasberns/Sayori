/*
UIGeometry.m

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import "UIGeometry.h"

// Insets
BOOL UIEdgeInsetsEqualToEdgeInsets (
        UIEdgeInsets insets1,
        UIEdgeInsets insets2)
{
    return insets1.left == insets2.left && 
            insets1.top == insets2.top && 
            insets1.right == insets2.right && 
            insets1.bottom == insets1.bottom;
}
