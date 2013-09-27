/*
 HMXMLRPCEncoder.m
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import "HMXMLRPC.h"
#import "HMXMLRPCEncoder.h"


@interface HMXMLRPCEncoder (Private)
- (NSString*)replaceTarget:(NSString*)target withValue:(NSString*)value iNSString:(NSString*)string;
- (NSString*)escapeValue:(NSString*)value;
- (NSString*)valueTag:(NSString*)tag value:(NSString*)value;
@end

#pragma mark -


@implementation HMXMLRPCEncoder

//--------------------------------------------------------------//
#pragma mark -- Private --
//--------------------------------------------------------------//

- (NSString*)replaceTarget:(NSString*)target withValue:(NSString*)value iNSString:(NSString*)string
{
	return [[string componentsSeparatedByString:target] componentsJoinedByString:value];
}

- (NSString*)escapeValue:(NSString*)value
{
	value = [self replaceTarget:@"&" withValue:@"&amp;" iNSString:value];
	value = [self replaceTarget:@"<" withValue:@"&lt;" iNSString:value];
	
	return value;
}

- (NSString*)valueTag:(NSString*)tag value:(NSString*)value
{
	return [NSString stringWithFormat:@"<value><%@>%@</%@></value>", tag, [self escapeValue:value], tag];
}

//--------------------------------------------------------------//
#pragma mark -- Encoding --
//--------------------------------------------------------------//

+ (NSString*)encodeParameters:(NSArray*)parameters method:(NSString*)method
{
	// Check arguments
	if (!method) {
		return nil;
	}
	
	// Create encodedString...
	NSMutableString *encodedString;
	encodedString = [NSMutableString string];
	
	// Append XML declaration
	[encodedString appendString:@"<?xml version=\"1.0\"?>"];
	
	// Append methodCall tag
	[encodedString appendString:@"<methodCall>"];
	
	// Append method
	[encodedString appendFormat:@"<methodName>%@</methodName>", method];
	
	// Append parameters
	if ([parameters count]) {
		HMXMLRPCEncoder *encoder;
		encoder = [[[self class] alloc] init];
		[encodedString appendString:@"<params>"];
		for (id parameter in parameters) {
			[encodedString appendString:@"<param>"];
			[encodedString appendString:[encoder encodeObject:parameter]];
			[encodedString appendString:@"</param>"];
		}
		[encodedString appendString: @"</params>"];
		[encoder release];
	}
	
	// Append /methodCall tag
	[encodedString appendString:@"</methodCall>"];
	
	return encodedString;
}

- (NSString*)encodeObject:(id)object
{
	// Check object
	if (!object) {
		return nil;
	}
	
	// Alternate by class
	if ([object isKindOfClass:[NSArray class]]) {
		return [self encodeArray:object];
	}
	else if ([object isKindOfClass:[NSDictionary class]]) {
		return [self encodeDictionary:object];
	}
	else if (((CFBooleanRef)object == kCFBooleanTrue) || ((CFBooleanRef)object == kCFBooleanFalse)) {
		return [self encodeBoolean:(CFBooleanRef)object];
	}
	else if ([object isKindOfClass:[NSNumber class]]) {
		return [self encodeNumber:object];
	}
	else if ([object isKindOfClass:[NSString class]]) {
		return [self encodeString:object];
	}
	else if ([object isKindOfClass:[NSDate class]]) {
		return [self encodeDate:object];
	}
	else if ([object isKindOfClass:[NSData class]]) {
		return [self encodeData:object];
	}
	else {
		return [self encodeString:object];
	}
}

- (NSString*)encodeArray:(NSArray*)array
{
	// Create encodedString...
	NSMutableString *encodedString;
	encodedString = [NSMutableString string];
	
	// Append starting tags
	[encodedString appendString:@"<value><array><data>"];
	
	// Append encoded elements
	for (id object in array) {
		[encodedString appendString:[self encodeObject:object]];
	}
	
	// Append ending tags
	[encodedString appendString:@"</data></array></value>"];
	
	return encodedString;
}

- (NSString*)encodeDictionary:(NSDictionary*)dictionary
{
	// Create encodedString...
	NSMutableString * encodedString;
	encodedString = [NSMutableString string];
	
	// Append starting tags
	[encodedString appendString:@"<value><struct>"];
	
	// Append encoded elements
	for (NSString *key in dictionary) {
		[encodedString appendString:@"<member>"];
		[encodedString appendFormat:@"<name>%@</name>", key];
		[encodedString appendString:[self encodeObject:[dictionary objectForKey:key]]];
		[encodedString appendString:@"</member>"];
	}
	
	// Append ending tags
	[encodedString appendString:@"</struct></value>"];
	
	return encodedString;
}

- (NSString*)encodeBoolean:(CFBooleanRef)boolean
{
	if (boolean == kCFBooleanTrue) {
		return [self valueTag:@"boolean" value:@"1"];
	} else {
		return [self valueTag:@"boolean" value:@"0"];
	}
}

- (NSString*)encodeNumber:(NSNumber*)number
{
	return [self valueTag:@"i4" value:[number stringValue]];
}

- (NSString*)encodeString:(NSString*)string
{
	return [self valueTag:@"string" value:string];
}

- (NSString*)encodeDate:(NSDate*)date
{
	// Create dateFormatter
	NSDateFormatter *dateFormatter;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter autorelease];
	[dateFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	// Create encodedString
	NSString *encodedString;
	encodedString = [dateFormatter stringFromDate:date];
	encodedString = [self valueTag:@"dateTime.iso8601" value:encodedString];
	
	return encodedString;
}

- (NSString*)encodeData:(NSData*)data
{
	// Create encodedString
	NSString *encodedString;
	encodedString = HMBase64StringFromData(data, [data length]);
	encodedString = [self valueTag:@"base64" value:encodedString];
	
	return encodedString;
}

@end
