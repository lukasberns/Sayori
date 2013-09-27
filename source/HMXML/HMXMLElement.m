/*
HMXMLElement.m

Author: Makoto Kinoshita

Copyright 2008 HMDT. All rights reserved.
*/

#import <libxml/globals.h>
#import <libxml/xmlerror.h>
#import <libxml/parserInternals.h>
#import <libxml/xmlmemory.h>
#import <libxml/parser.h>
#import "HMXMLElement.h"
#import "HMXMLUtilities.h"

@interface HMXMLElement (private)

// Initialize
- (HMXMLElement*)initWithXMLNode:(xmlNode*)xNode;

// XPath
- (NSArray *)_nodesForXPath:(NSString *)XPath error:(NSError **)outError;
@end

@implementation HMXMLElement

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (HMXMLElement*)elementWithXMLNode:(xmlNode*)xNode
{
    // Check node type
    if (xNode->type != XML_ELEMENT_NODE) {
        return nil;
    }
    
    // Create XML element
    HMXMLElement*   element;
    element = [[HMXMLElement alloc] initWithXMLNode:xNode];
    [element autorelease];
    
    return element;
}

+ (HMXMLElement*)elementWithName:(NSString*)name attributes:(NSDictionary*)attributes
{
    // Create x node
    xmlNode*    xNode;
    xNode = xmlNewNode(NULL, (xmlChar*)[name UTF8String]);
    
    // Add attributes
    for (NSString* key in [attributes keyEnumerator]) {
        // Get value
        NSString*   value;
        value = [attributes valueForKey:key];
        
        // Set prop
        xmlSetProp(
                xNode, (const xmlChar*)[key UTF8String], (const xmlChar*)[value UTF8String]);
    }
    
    // Create element
    HMXMLElement*   element;
    element = [[HMXMLElement alloc] init];
    [element autorelease];
    element.xNode = xNode;
    
    return element;
}

- (HMXMLElement*)initWithXMLNode:(xmlNode*)xNode
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Initialize instance variables
    self.xNode = xNode;
    self.xmlDocument = xNode->doc;
    
    return self;
}

- (NSString*)description
{
    return [self XMLString];
}

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//

- (NSString*)XMLString
{
    // Create XML string
    NSMutableString*    string;
    string = [NSMutableString string];
    
    // Namespace
    if (self.namespacePrefix) {
        [string appendFormat:@"<%@", [self qualifiedName]];
    }
    else {
        [string appendFormat:@"<%@", self.name];
    }
    
    // Attributes
    if (self.attributes && [[self.attributes allKeys] count] > 0) {
        [string appendFormat:@" %@", [self attributesString]];
    }
    
    // End tag
    [string appendString:@">"];
    
    // Add child
    for (HMXMLElement* child in self.children) {
        [string appendString:[child XMLString]];
    }
    
    // Close tag
    if (self.namespacePrefix) {
        [string appendFormat:@"</%@>", [self qualifiedName]];
    }
    else {
        [string appendFormat:@"</%@>", self.name];
    }
    
    return string;
}

- (NSDictionary*)attributes
{
    // Check node type
    if (_xNode->type != XML_ELEMENT_NODE) {
        return nil;
    }
    
    NSMutableDictionary*    elementAttrs;
    elementAttrs = [NSMutableDictionary dictionary];
    
    // Collect attributes
    xmlAttr*    attrs;
    attrs = _xNode->properties;
    while (attrs) {
        // Get attribute name and value
        const xmlChar*  attrName;
        xmlChar*        attrValue;
        attrName = attrs->name;
        attrValue = xmlGetProp(_xNode, attrName);
        
        // Create string
        NSString*   attrNameStr;
        NSString*   attrValueStr;
        attrNameStr = [HMXMLUtilities stringWithXMLChar:attrName];
        attrValueStr = [HMXMLUtilities stringWithXMLChar:attrValue];
        xmlFree(attrValue);
        
        if (attrNameStr && attrValueStr) {
            [elementAttrs setValue:attrValueStr forKey:attrNameStr];
        }
        
        attrs = attrs->next;
    }
    
	return elementAttrs;
}

- (void)setAttributes:(NSDictionary*)attributes
{
    // Check node type
    if (_xNode->type != XML_ELEMENT_NODE) {
        return;
    }
    
    // Get attributes
    for (NSString* key in [attributes keyEnumerator]) {
        // Get value
        NSString*   value;
        value = [attributes objectForKey:key];
        
        // Set attribute name and value
        const xmlChar*  attrName;
        xmlChar*        attrValue;
        attrName = (xmlChar*)[key UTF8String];
        attrValue = (xmlChar*)[value UTF8String];
        xmlSetProp(_xNode, attrName, attrValue);
    }
}

- (NSString*)attributesString
{
    // Append attributes
    NSMutableString*    string;
    string = [NSMutableString string];
    for (NSString* attribute in self.attributes) {
        [string appendFormat:@"%@=\"%@\"", attribute, [self.attributes valueForKey:attribute]];
    }
    
    return string;
}

//--------------------------------------------------------------//
#pragma mark -- Navigation --
//--------------------------------------------------------------//

- (NSString*)attributeForName:(NSString*)attributeName
{
    return [self.attributes objectForKey:attributeName];
}

- (NSArray*)elementsWithAttributeNamed:(NSString*)attributeName attributeValue:(NSString*)attributeValue
{
    // Create XPath
    NSString*   xpath;
    xpath = [NSString stringWithFormat:@"//*[@%@='%@']", attributeName, attributeValue];
    
    // Query XPath
    return [self nodesForXPath:xpath prepareNamespaces:nil error:nil];
}

- (void)dealloc
{
    [super dealloc];
}

@end
