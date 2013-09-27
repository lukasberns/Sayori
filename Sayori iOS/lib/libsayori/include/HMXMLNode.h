/*
HMXMLNode.h

Author: Makoto Kinoshita

Copyright 2008 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <libxml/xmlmemory.h>
#import <libxml/xpath.h>

enum {
    HMXMLInvalidKind = 0,
    HMXMLDocumentKind,
    HMXMLElementKind,
    HMXMLAttributeKind,
    HMXMLNamespaceKind,
    HMXMLProcessingInstructionKind,
    HMXMLCommentKind,
    HMXMLTextKind,
    HMXMLDTDKind,
    HMXMLEntityDeclarationKind,
    HMXMLAttributeDeclarationKind,
    HMXMLElementDeclarationKind,
    HMXMLNotationDeclarationKind
};

@class HMXMLElement;

@interface HMXMLNode : NSObject
{
    xmlNode*            _xNode;
    xmlDoc*             _xDocument;
    xmlXPathContext*    _xpathContext;
    HMXMLElement*       _rootElement;
    NSString*           _name;
    NSString*           _namespacePrefix;
    NSString*           _qualifiedName;
    NSArray*            _children;
    NSUInteger          _childCount;
    HMXMLElement*       _firstChild;
    HMXMLElement*       _lastChild;
    HMXMLElement*       _parent;
    HMXMLNode*          _nextNode;
    HMXMLNode*          _nextSibling;
    HMXMLNode*          _previousNode;
    HMXMLNode*          _previousSibling;
    NSString*           _XMLString;
    NSString*           _stringValue;
}

// Property
@property (nonatomic, assign) xmlNode* xNode;
@property (nonatomic, assign) xmlDoc* xmlDocument;
@property (nonatomic, readonly) HMXMLElement* rootElement;

@property (nonatomic, readonly) int kind;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) const xmlChar* rawName;
@property (nonatomic, readonly) NSString* namespacePrefix;
@property (nonatomic, readonly) NSString* qualifiedName;
@property (nonatomic, readonly) NSArray* children;
@property (nonatomic, readonly) NSUInteger childCount;
@property (nonatomic, readonly) HMXMLElement* firstChild;
@property (nonatomic, readonly) HMXMLElement* lastChild;

@property (nonatomic, readonly) HMXMLElement* parent;
@property (nonatomic, readonly) HMXMLNode* nextNode;
@property (nonatomic, readonly) HMXMLNode* nextSibling;
@property (nonatomic, readonly) HMXMLNode* previousNode;
@property (nonatomic, readonly) HMXMLNode* previousSibling;

@property (nonatomic, readonly) NSString* XMLString;
@property (nonatomic, readonly) NSString* stringValue;

// Initialize
+ (HMXMLNode*)nodeWithXMLNode:(xmlNode*)xNode;
+ (HMXMLNode*)nodeWithName:(NSString*)name;

// Property
- (xmlChar*)createRawStringValue;

// Child node operation
- (HMXMLNode*)firstChildNamed:(NSString*)matchName;
- (HMXMLNode*)firstDescendantNamed:(NSString*)matchName;
- (NSArray*)childrenNamed:(NSString*)matchName;
- (NSArray*)descendantsNamed:(NSString*)matchName;
- (HMXMLNode*)addNodeWithName:(NSString*)name content:(NSString*)content;
- (HMXMLElement*)addElementWithName:(NSString*)name attributes:(NSDictionary*)attributes;
- (void)addChildNode:(HMXMLNode*)node;
- (void)addPrevSiblingNode:(HMXMLNode*)node;
- (void)addNextSiblingNode:(HMXMLNode*)node;

// XPath
- (HMXMLNode*)singleNodeForXPath:(NSString*)XPath error:(NSError**)error;
- (NSArray*)nodesForXPath:(NSString*)XPath error:(NSError**)error;
- (NSArray*)nodesForXPath:(NSString*)XPath 
        prepareNamespaces:(NSArray*)nodeNames error:(NSError**)error;
@end
