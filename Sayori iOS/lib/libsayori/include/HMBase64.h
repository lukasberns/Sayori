/*
 HMBase64.h
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>


// Functions
extern NSData* HMDataFromBase64String(
		NSString* string);

extern NSString* HMBase64StringFromData(
		NSData *data,
		NSInteger length);
