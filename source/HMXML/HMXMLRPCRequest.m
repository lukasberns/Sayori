/*
 HMXMLRPCRequest.m
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import "HMXMLRPCRequest.h"
#import "HMXMLRPCEncoder.h"


@implementation HMXMLRPCRequest

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (void)dealloc
{
	// Clean up
	[_hostURL release], _hostURL = nil;
	[_userAgent release], _userAgent = nil;
	[_method release], _method = nil;
	[_parameters release], _parameters = nil;
	
	// Super
	[super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Properties --
//--------------------------------------------------------------//
@synthesize hostURL = _hostURL;
@synthesize userAgent = _userAgent;
@synthesize method = _method;
@synthesize parameters = _parameters;

//--------------------------------------------------------------//
#pragma mark -- Request Management --
//--------------------------------------------------------------//

- (void)setHostURLString:(NSString*)URLString
{
	// Set hostURL
	[self setHostURL:[NSURL URLWithString:URLString]];
}

//--------------------------------------------------------------//
#pragma mark -- Build --
//--------------------------------------------------------------//

- (NSString*)bodyXMLString
{
	// Get elements
	NSString *method;
	NSArray *parameters;
	method = [self method];
	parameters = [self parameters];
	if (!method) {
		return nil;
	}
	
	// Get body XML
	NSString *bodyXMLString;
	bodyXMLString = [HMXMLRPCEncoder encodeParameters:parameters method:method];
	
	return bodyXMLString;
}

- (NSMutableURLRequest*)mutableURLRequest
{
	// Get elements
	NSURL *hostURL;
	NSString *userAgent;
	NSString *method;
	NSArray *parameters;
	method = [self method];
	parameters = [self parameters];
	hostURL = [self hostURL];
	userAgent = [self userAgent];
	if (!hostURL || !method) {
		return nil;
	}
	
	// Create URL request...
	NSMutableURLRequest *request;
	request = [NSMutableURLRequest requestWithURL:hostURL];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	if (userAgent) {
		[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	}
	
	// Get body data
	NSData *bodyData;
	bodyData = [[HMXMLRPCEncoder encodeParameters:parameters method:method] dataUsingEncoding:NSUTF8StringEncoding];
	if (!bodyData) {
		return nil;
	}
	
	// Set Content-Length
	NSNumber *contentLength;
	contentLength = [NSNumber numberWithUnsignedLongLong:[bodyData length]];
	[request setValue:[contentLength stringValue] forHTTPHeaderField:@"Content-Length"];
	
	// Set body data
	[request setHTTPBody:bodyData];
	
	return request;
}

@end
