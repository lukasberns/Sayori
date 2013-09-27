/*
HMXMLDocument.h

Author: Makoto Kinoshita

Copyright 2008 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <libxml/xmlmemory.h>

@class HMXMLElement;
@class HMXMLNode;

@interface HMXMLDocument : NSObject
{
    xmlDoc*         _xDocument;
    HMXMLElement*   _rootElement;
}

// Property
@property (nonatomic) xmlDoc* xmlDocument;
@property (nonatomic, retain) HMXMLElement* rootElement;

// Initialize
+ (HMXMLDocument*)documentWithXMLDocument:(xmlDocPtr)xDocument;
+ (HMXMLDocument*)documentWithXMLString:(NSString*)string error:(NSError**)error;
+ (HMXMLDocument*)documentWithXMLData:(NSData*)data error:(NSError**)error;
+ (HMXMLDocument*)documentWithContentsOfURL:(NSURL*)url error:(NSError**)error;
+ (HMXMLDocument*)documentWithContentsOfURL:(NSURL*)url encoding:(NSStringEncoding)encoding error:(NSError**)error;

@end
