/*
SRXMLReader.h

Author: Makoto Kinoshita

Copyright 2008 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>

@class HMXMLDocument;

@interface HMXMLReader : NSObject
{
}

// Initialize
+ (HMXMLDocument*)parseXMLFileAtURL:(NSURL*)URL parseError:(NSError**)error;
+ (HMXMLDocument*)parseXMLFileAtURL:(NSURL*)URL encoding:(NSStringEncoding)encoding parseError:(NSError**)error;
+ (HMXMLDocument*)parseXMLString:(NSString*)XMLString parseError:(NSError**)error;
+ (HMXMLDocument*)parseXMLData:(NSData*)XMLData parseError:(NSError**)error;
+ (HMXMLDocument*)parseXML:(const char*)XMLString parseError:(NSError**)error;

@end
