/*
HMXMLUtilities.m

Author: Makoto Kinoshita

Copyright 2008 HMDT. All rights reserved.
*/

#import "HMXMLUtilities.h"

NSString*   HMXMLParsingErrorDomain = @"HMXMLParsingErrorDomain";

@implementation HMXMLUtilities

//--------------------------------------------------------------//
#pragma mark -- Utilities --
//--------------------------------------------------------------//

+ (NSString*)stringWithXMLChar:(const xmlChar*)chars
{
    // Check length
    if (strlen((const char*)chars) == 0) {
        return nil;
    }
    
    // Create string
    return [NSString stringWithCString:(const char*)chars encoding:NSUTF8StringEncoding];
}

+ (NSError*)errorWithXMLError:(xmlError*)xError
{
    // Get message
    char*       message;
    NSString*   messageStr;
    message = xError->message;
    messageStr = [NSString stringWithCString:message encoding:NSUTF8StringEncoding];
    
    // Create error info
    NSDictionary*   errorInfo;
    errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
            messageStr, NSLocalizedFailureReasonErrorKey, nil];
    
    // Create error
    NSError*    error;
    error = [NSError errorWithDomain:HMXMLParsingErrorDomain code:0 userInfo:errorInfo];
    
    return error;
}

+ (NSError*)errorWithString:(NSString*)errorStr
{
    // Check argument
    if (!errorStr) {
        return nil;
	}
	
    // Create error info
    NSDictionary*   errorInfo;
    errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
            errorStr, NSLocalizedFailureReasonErrorKey, nil];
    
    // Create error
    NSError*    error;
    error = [NSError errorWithDomain:HMXMLParsingErrorDomain code:0 userInfo:errorInfo];
    
    return error;
}

@end

NSString* HMXMLEncodeXmlEntityRef(
        NSString* string)
{
    // Check string
    if(!string) {
        return nil;
    }
    if([string length] == 0) {
        return nil;
    }

    // Encode HTML string
    NSString*   encodedString;
    encodedString = string;
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];    
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"'"  withString:@"&apos;"];

    // Return encoded string
    return encodedString;
}

NSString* HMXMLDecodeXmlEntityRef(
        NSString* string)
{
    // Check string
    if(!string) {
        return nil;
    }
    if([string length] == 0) {
        return nil;
    }

    // Decode HTML string
    NSString*   decodedString;
    decodedString = string;
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"'"  withString:@"&apos;"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];    
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];

    // Return decoded string
    return decodedString;
}

NSString* HMXMLEncodeUrlString(
        NSString* string, NSStringEncoding encoding)
{
    // Check string
    if(!string) {
        return nil;
    }
    if([string length] == 0) {
        return nil;
    }
    
    // Return encoded url string
    return (NSString*)CFURLCreateStringByAddingPercentEscapes(
           NULL,
           (CFStringRef)string,
           (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
           NULL,
           CFStringConvertNSStringEncodingToEncoding(encoding));
}

NSString* HMXMLEncodeUrlStringForBase64(
        NSString* string, NSStringEncoding encoding)
{
    // Check string
    if(!string) {
        return nil;
    }
    if([string length] == 0) {
        return nil;
    }
    
    // Return encoded url string
    return (NSString*)CFURLCreateStringByAddingPercentEscapes(
           kCFAllocatorDefault,
           (CFStringRef)string,
           (CFStringRef)@":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`",
           NULL,
           CFStringConvertNSStringEncodingToEncoding(encoding));
}

NSString* HMXMLDecodeUrlString(
        NSString* string, NSStringEncoding encoding)
{
    // Check string
    if(!string) {
        return nil;
    }
    if([string length] == 0) {
        return nil;
    }
    
    // Return decoded url string
    return (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
           NULL,
           (CFStringRef)string,
           CFSTR(""),
           CFStringConvertNSStringEncodingToEncoding(encoding));
}

NSDictionary* HMXMLParameterWithQuery(
        NSString* query)
{
    // Create parameter dictionary
    NSMutableDictionary*    paramDict;
    paramDict = [NSMutableDictionary dictionary];
    
    // Separate by '&'
    NSArray*    params;
    params = [query componentsSeparatedByString:@"&"];
    for (NSString* param in params) {
        // Separate by '='
        NSArray*    components;
        components = [param componentsSeparatedByString:@"="];
        if ([components count] == 2) {
            // Decode key and value
            NSString*   key;
            NSString*   value;
            key = [components objectAtIndex:0];
            key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            value = [components objectAtIndex:1];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            // Add key and value
            [paramDict setObject:value forKey:key];
        }
    }
    
    return paramDict;
}
