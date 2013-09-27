/*
 HMXMLRPCDecoder.m
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import "HMXMLRPCDecoder.h"


@interface HMXMLRPCDecoder (Private)
@end

#pragma mark -


@implementation HMXMLRPCDecoder

//--------------------------------------------------------------//
#pragma mark -- Decoding --
//--------------------------------------------------------------//

+ (id)decodeRootElement:(HMXMLElement*)rootElement
{
	// Check argument
	if (!rootElement) {
		return nil;
	}
	
	// Get element to decode
	HMXMLElement *elementToDecode;
	elementToDecode = (HMXMLElement*)[rootElement singleNodeForXPath:@"params/param/value" error:nil];
	if (!elementToDecode) {
		elementToDecode = (HMXMLElement*)[rootElement singleNodeForXPath:@"fault/value" error:nil];
	}
	if (!elementToDecode) {
		return nil;
	}
	
	// Decode the node
	id decodedObject;
	HMXMLRPCDecoder *decoder;
	decoder = [[[self class] alloc] init];
	decodedObject = [decoder decodeObjectElement:elementToDecode];
	[decoder release];
	
	return decodedObject;
}

- (id)decodeObjectElement:(HMXMLElement*)element
{
	// Get 1st child
	HMXMLElement *child;
	child = (HMXMLElement*)[element singleNodeForXPath:@"*" error:nil];
	if (!child) {
		return nil;
	}
	
	// Alternate by name of element
	NSString *name;
	name = [child name];
	if ([name isEqualToString:@"array"]) {
		return [self decodeArrayElement:child];
	}
	else if ([name isEqualToString:@"struct"]) {
		return [self decodeDictionaryElement:child];
	}
	else if ([name isEqualToString:@"int"] || [name isEqualToString:@"i4"]) {
		return [self decodeNumberElement:child isDouble:NO];
	}
	else if ([name isEqualToString:@"double"]) {
		return [self decodeNumberElement:child isDouble:YES];
	}
	else if ([name isEqualToString:@"boolean"]) {
		return (id)[self decodeBoolElement:child];
	}
	else if ([name isEqualToString:@"string"]) {
		return [self decodeStringElement:child];
	}
	else if ([name isEqualToString:@"dateTime.iso8601"]) {
		return [self decodeDateElement:child];
	}
	else if ([name isEqualToString:@"base64"]) {
		return [self decodeDataElement:child];
	}
	else {
		return [self decodeStringElement:child];
	}
	
	return nil;
}

- (NSArray*)decodeArrayElement:(HMXMLElement*)element
{
	// Get data element
	HMXMLElement *dataElement;
	dataElement = (HMXMLElement*)[element singleNodeForXPath:@"data" error:nil];
	if (!dataElement) {
		return nil;
	}
	
	// Create decodedArray
	NSMutableArray *decodedArray;
	decodedArray = [NSMutableArray array];
	
	// Append decodedObject to decodedArray
	for (HMXMLNode *child in [dataElement children]) {
		// Check name
		if (![[child name] isEqualToString:@"value"]) {
			continue;
		}
		
		// Decode element
		id decodedObject;
		decodedObject = [self decodeObjectElement:(HMXMLElement*)child];
		if (decodedObject) {
			[decodedArray addObject:decodedObject];
		}
	}
	
	return decodedArray;
}

- (NSDictionary*)decodeDictionaryElement:(HMXMLElement*)element
{
	// Create decodedDictionary
	NSMutableDictionary *decodedDictionary;
	decodedDictionary = [NSMutableDictionary dictionary];
	
	// Supply decodedDictionary
	NSArray *memberNodes;
	HMXMLElement *memberElement, *nameElement, *valueElement;
	NSString *key;
	id decodedObject;
	memberNodes = [element nodesForXPath:@"member" error:nil];
	for (HMXMLNode *memberNode in memberNodes) {
		// Get memberElement
		memberElement = (HMXMLElement*)memberNode;
		
		// Get key
		nameElement = (HMXMLElement*)[memberElement singleNodeForXPath:@"name" error:nil];
		if (!nameElement) {
			continue;
		}
		key = [nameElement stringValue];
		if (![key length]) {
			continue;
		}
		
		// Get decoded value
		valueElement = (HMXMLElement*)[memberElement singleNodeForXPath:@"value" error:nil];
		if (!valueElement) {
			continue;
		}
		decodedObject = [self decodeObjectElement:valueElement];
		if (!decodedObject) {
			continue;
		}
		
		// Supply decodedDictionary
		[decodedDictionary setObject:decodedObject forKey:key];
	}
	
	return decodedDictionary;
}

- (NSNumber*)decodeNumberElement:(HMXMLElement*)element isDouble:(BOOL)flag
{
	if (flag) {
		return [NSNumber numberWithDouble:[[element stringValue] doubleValue]];
	}
	else {
		return [NSNumber numberWithInt:[[element stringValue] intValue]];
	}
}

- (CFBooleanRef)decodeBoolElement:(HMXMLElement*)element
{
	if ([[element stringValue] isEqualToString:@"1"]) {
		return kCFBooleanTrue;
	}
	else {
		return kCFBooleanFalse;
	}
}

- (NSString*)decodeStringElement:(HMXMLElement*)element
{
	return [element stringValue];
}

- (NSDate*)decodeDateElement:(HMXMLElement*)element
{
	// Create dateFormatter
	NSDateFormatter *dateFormatter;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter autorelease];
	[dateFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	// Get date from string
	NSDate *date = nil;
	NSArray *formats;
	formats = [NSArray arrayWithObjects:
			@"yyyyMMdd'T'HH:mm:ss",
			@"yyyy-MM-dd'T'HH:mm:ss'Z'",
			nil];
	for (NSString *format in formats) {
		[dateFormatter setDateFormat:format];
		date = [dateFormatter dateFromString:[element stringValue]];
		if (date) {
			break;
		}
	}
	
	return date;
}

- (NSData*)decodeDataElement:(HMXMLElement*)element
{
	return HMDataFromBase64String([element stringValue]);
}

@end
