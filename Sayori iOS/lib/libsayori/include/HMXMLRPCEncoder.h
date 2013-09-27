/*
 HMXMLRPCEncoder.h
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>


@interface HMXMLRPCEncoder : NSObject
{
}

// Encoding
+ (NSString*)encodeParameters:(NSArray*)parameters method:(NSString*)method;
//
- (NSString*)encodeObject:(id)object;
- (NSString*)encodeArray:(NSArray*)array;
- (NSString*)encodeDictionary:(NSDictionary*)dictionary;
- (NSString*)encodeBoolean:(CFBooleanRef)boolean;
- (NSString*)encodeNumber:(NSNumber*)number;
- (NSString*)encodeString:(NSString*)string;
- (NSString*)encodeDate:(NSDate*)date;
- (NSString*)encodeData:(NSData*)data;

@end
