/*
 HMXMLRPCDecoder.h
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "HMXML.h"
#import "HMXMLRPC.h"


@interface HMXMLRPCDecoder : NSObject
{
}

// Decoding
+ (id)decodeRootElement:(HMXMLElement*)element;
//
- (id)decodeObjectElement:(HMXMLElement*)element;
- (NSArray*)decodeArrayElement:(HMXMLElement*)element;
- (NSDictionary*)decodeDictionaryElement:(HMXMLElement*)element;
- (NSNumber*)decodeNumberElement:(HMXMLElement*)element isDouble:(BOOL)flag;
- (CFBooleanRef)decodeBoolElement:(HMXMLElement*)element;
- (NSString*)decodeStringElement:(HMXMLElement*)element;
- (NSDate*)decodeDateElement:(HMXMLElement*)element;
- (NSData*)decodeDataElement:(HMXMLElement*)element;

@end
