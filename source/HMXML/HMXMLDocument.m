/*
HMXMLDocument.h

Author: Makoto Kinoshita, MIURA Kazki

Copyright 2008 HMDT. All rights reserved.
*/

#import "HMXMLDocument.h"
#import "HMXMLElement.h"
#import "HMXMLReader.h"

@implementation HMXMLDocument

// Property
@synthesize xmlDocument = _xDocument;
@synthesize rootElement = _rootElement;

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (HMXMLDocument*)documentWithXMLDocument:(xmlDocPtr)xDocument
{
    // Create XML document
    HMXMLDocument*  document;
    document = [[HMXMLDocument alloc] init];
    [document autorelease];
    document.xmlDocument = xDocument;
    
    // Set root element
    xmlNode*        xRootElement;
    HMXMLElement*   rootElement;
    xRootElement = xmlDocGetRootElement(xDocument);
    rootElement = [HMXMLElement elementWithXMLNode:xRootElement];
    document.rootElement = rootElement;
	
    return document;
}

+ (HMXMLDocument*)documentWithXMLString:(NSString*)string error:(NSError**)error
{
    return [HMXMLReader parseXMLString:string parseError:error];
}

+ (HMXMLDocument*)documentWithXMLData:(NSData*)data error:(NSError**)error
{
    return [HMXMLReader parseXMLData:data parseError:error];
}

+ (HMXMLDocument*)documentWithContentsOfURL:(NSURL*)url error:(NSError**)error
{
    return [HMXMLReader parseXMLFileAtURL:url parseError:error];
}

+ (HMXMLDocument*)documentWithContentsOfURL:(NSURL*)url encoding:(NSStringEncoding)encoding error:(NSError**)error
{
    return [HMXMLReader parseXMLFileAtURL:url encoding:encoding parseError:error];
}

- (void)dealloc
{
    if (self.xmlDocument) {
        xmlFreeDoc(self.xmlDocument);
    }
    [_rootElement release], _rootElement = nil;

    [super dealloc];
}

@end
