/*
HMRuntimeUtil.m

Author: Makoto Kinoshita

Copyright 2012-2013 HMDT. All rights reserved.
*/

#import "HMRuntimeUtil.h"

//--------------------------------------------------------------//
#pragma mark -- Runtime --
//--------------------------------------------------------------//

int HMSystemMajorVersion()
{
    static  int _majorVersion = 0;
    if (_majorVersion == 0) {
        // Get system version
        NSString*   version;
        version = [UIDevice currentDevice].systemVersion;
        
        // Get major version
        NSArray*    components;
        components = [version componentsSeparatedByString:@"."];
        if ([components count] > 0) {
            _majorVersion = [components[0] integerValue];
        }
    }
    
    return _majorVersion;
}

float HMStatusBarHeight()
{
    // Get status bar frame
    CGRect  frame;
    frame = [UIApplication sharedApplication].statusBarFrame;
    
    // For portrait
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        return CGRectGetHeight(frame);
    }
    // For landscape
    else {
        return CGRectGetWidth(frame);
    }
}
