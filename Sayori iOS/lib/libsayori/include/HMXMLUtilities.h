/*
HMXMLUtilities.h

Author: Makoto Kinoshita

Copyright 2008 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <libxml/xmlmemory.h>

extern NSString*    HMXMLParsingErrorDomain;

@interface HMXMLUtilities : NSObject
{
}

// Utilities
+ (NSString*)stringWithXMLChar:(const xmlChar*)chars;
+ (NSError*)errorWithXMLError:(xmlError*)xError;
+ (NSError*)errorWithString:(NSString*)errorStr;

@end

NSString* HMXMLEncodeXmlEntityRef(
        NSString* string);
NSString* HMXMLDecodeXmlEntityRef(
        NSString* string);
NSString* HMXMLEncodeUrlString(
        NSString* string, NSStringEncoding encoding);
NSString* HMXMLEncodeUrlStringForBase64(
        NSString* string, NSStringEncoding encoding);
NSString* HMXMLDecodeUrlString(
        NSString* string, NSStringEncoding encoding);
NSDictionary* HMXMLParameterWithQuery(
        NSString* query);
