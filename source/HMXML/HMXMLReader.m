/*
HMXMLReader.m

Author: Makoto Kinoshita, MIURA Kazki

Copyright 2008 HMDT. All rights reserved.
*/

#import "HMXMLReader.h"
#import "HMXMLDocument.h"
#import "HMXMLUtilities.h"

@implementation HMXMLReader

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (HMXMLDocument*)parseXMLFileAtURL:(NSURL*)URL parseError:(NSError**)error
{
    NSString*   string;
    string = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:NULL];
    if (!string) {
        return nil;
    }
    
    return [HMXMLReader parseXMLString:string parseError:error];
}

+ (HMXMLDocument*)parseXMLFileAtURL:(NSURL*)URL encoding:(NSStringEncoding)encoding parseError:(NSError**)error
{
    NSString*   string;
    string = [NSString stringWithContentsOfURL:URL encoding:encoding error:NULL];
    if (!string) {
        return nil;
    }
    
    const char* chars;
    chars = [string cStringUsingEncoding:encoding];
    
    return [HMXMLReader parseXML:chars parseError:error];
}

+ (HMXMLDocument*)parseXMLString:(NSString*)string parseError:(NSError**)error
{
    const char* chars;
    chars = [string cStringUsingEncoding:NSUTF8StringEncoding];
    
    return [HMXMLReader parseXML:chars parseError:error];
}

+ (HMXMLDocument*)parseXMLData:(NSData*)XMLData parseError:(NSError**)error
{
    // Filter
    if (!XMLData) {
        return nil;
    }
    
    // Convert XMLData to chars
    const char *chars = [XMLData bytes];
    if (!chars) {
        return nil;
    }
    
    // Create parser context
    xmlParserCtxtPtr    parserCtxt;
    parserCtxt = xmlNewParserCtxt();
    
    // Read from memory
    xmlDocPtr   xDocument;
    xDocument = xmlCtxtReadMemory(parserCtxt, chars, [XMLData length], NULL, NULL, 0);
    if (!xDocument) {
        // Get error
        if (error) {
            xmlError*   xError;
            xError = xmlCtxtGetLastError(parserCtxt);
            *error = [HMXMLUtilities errorWithXMLError:xError];
        }
        
        // Free parserCtxt
        xmlFreeParserCtxt(parserCtxt);

        return nil;
    }
    
    // Check root element
    xmlNodePtr  xNode;
    xNode = xmlDocGetRootElement(xDocument);
    if (!xNode) {
        // Error
        xmlFreeDoc(xDocument);
        
        // Free parserCtxt
        xmlFreeParserCtxt(parserCtxt);
        
        return nil;
    }

    // Free parserCtxt
    xmlFreeParserCtxt(parserCtxt);
    
    return [HMXMLDocument documentWithXMLDocument:xDocument];
}

+ (HMXMLDocument*)parseXML:(const char*)chars parseError:(NSError**)error
{
    // Check argument
    if (!chars) {
        return nil;
    }
    
    // Create parser context
    xmlParserCtxtPtr    parserCtxt;
    parserCtxt = xmlNewParserCtxt();
    
    // Read from memory
    xmlDocPtr   xDocument;
    xDocument = xmlCtxtReadMemory(parserCtxt, chars, strlen(chars), NULL, NULL, 0);
    if (!xDocument) {
        // Get error
        if (error) {
            xmlError*   xError;
            xError = xmlCtxtGetLastError(parserCtxt);
            *error = [HMXMLUtilities errorWithXMLError:xError];
        }
        
        // Free parserCtxt
        xmlFreeParserCtxt(parserCtxt);
        
        return nil;
    }
    
    // Check root element
    xmlNodePtr  xNode;
    xNode = xmlDocGetRootElement(xDocument);
    if (!xNode) {
        // Error
        xmlFreeDoc(xDocument);
        
        // Free parserCtxt
        xmlFreeParserCtxt(parserCtxt);
        
        return nil;
    }
    
    // Free parserCtxt
    xmlFreeParserCtxt(parserCtxt);
    
    return [HMXMLDocument documentWithXMLDocument:xDocument];
}

@end
