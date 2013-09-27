/*
NSIndexPathAddition.h

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@interface NSIndexPath (UIKitAddition)

// Property
@property(nonatomic, readonly) NSInteger section;
@property(nonatomic, readonly) NSInteger row;
@property(nonatomic, readonly) NSInteger item;

// Initialize
+ (NSIndexPath*)indexPathForRow:(NSInteger)row inSection:(NSInteger)section;
+ (NSIndexPath*)indexPathForItem:(NSInteger)item inSection:(NSInteger)section;

@end
