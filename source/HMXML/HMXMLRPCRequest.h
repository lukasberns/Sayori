/*
 HMXMLRPCRequest.h
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>

@class HMXMLRPCEncoder;


@interface HMXMLRPCRequest : NSObject
{
	NSURL *_hostURL;
	NSString *_userAgent;
	NSString *_method;
	NSArray *_parameters;
}

// Properties
@property(nonatomic, retain, readwrite) NSURL *hostURL;
@property (nonatomic, retain, readwrite) NSString *userAgent;
@property (nonatomic, retain, readwrite) NSString *method;
@property (nonatomic, retain, readwrite) NSArray *parameters;

// Request Management
- (void)setHostURLString:(NSString*)URLString;

// Build
- (NSString*)bodyXMLString;
- (NSMutableURLRequest*)mutableURLRequest;

@end
