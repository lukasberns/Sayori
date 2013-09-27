//
//  AppDelegate.m
//  Sayori OS X
//
//  Created by Makoto Kinoshita on 2013/09/27.
//  Copyright (c) 2013年 HMDT CO., LTD. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Create SYLabel
    SYLabel*    label;
    label = [[SYLabel alloc] initWithFrame:[self.window.contentView bounds]];
    label.html = @"<xhtml><body><p class=\"hello\">Hello Sayori!</p></body></xhtml>";
    label.cssString = @"p.class { font-size: 24px; }";
    label.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    // Add label
    [self.window.contentView addSubview:label];
}

@end
