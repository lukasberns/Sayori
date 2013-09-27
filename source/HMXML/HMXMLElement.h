/*
HMXMLElement.h

Author: Makoto Kinoshita

Copyright 2008 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <libxml/xmlmemory.h>
#import "HMXMLNode.h"

@interface HMXMLElement : HMXMLNode
{
}

// Property
@property (nonatomic, assign) NSDictionary* attributes;
@property (nonatomic, readonly) NSString* attributesString;

// Initialize
+ (HMXMLElement*)elementWithXMLNode:(xmlNode*)xNode;
+ (HMXMLElement*)elementWithName:(NSString*)name attributes:(NSDictionary*)attributes;

// Attributes operation
- (NSString*)attributeForName:(NSString*)attributeName;
//- (NSArray*)elementsWithAttributeNamed:(NSString*)attributeName;
- (NSArray*)elementsWithAttributeNamed:(NSString*)attributeName attributeValue:(NSString*)attributeValue;

@end