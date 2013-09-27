/*
NSIndexPathAddition.m

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import "NSIndexPathAddition.h"

@implementation NSIndexPath (UIKitAddition)

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (NSIndexPath*)indexPathForRow:(NSInteger)row inSection:(NSInteger)section
{
    // Create index path
    NSUInteger  indexes[2] = { section, row };
    return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

+ (NSIndexPath*)indexPathForItem:(NSInteger)item inSection:(NSInteger)section
{
    // Create index path
    NSUInteger  indexes[2] = { section, item };
    return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//

- (NSInteger)section
{
    return [self indexAtPosition:0];
}

- (NSInteger)row
{
    return [self indexAtPosition:1];
}

- (NSInteger)item
{
    return [self indexAtPosition:1];
}

@end
