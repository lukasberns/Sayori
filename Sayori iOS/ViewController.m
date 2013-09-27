//
//  ViewController.m
//  Sayori iOS
//
//  Created by Makoto Kinoshita on 2013/09/27.
//  Copyright (c) 2013年 HMDT CO., LTD. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    // Invoke super
    [super viewDidLoad];
    
    // Create SYLabel
    SYLabel*    label;
    label = [[SYLabel alloc] initWithFrame:self.view.bounds];
    label.html = @"<xhtml><body><p class=\"hello\">Hello Sayori!</p></body></xhtml>";
    label.cssString = @"p.hello { font-size: 24px; margin: 20px; }";
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Add label
    [self.view addSubview:label];
}

@end
