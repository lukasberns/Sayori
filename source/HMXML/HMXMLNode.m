/*
HMXMLNode.m

Author: Makoto Kinoshita, MIURA Kazki

Copyright 2008 HMDT. All rights reserved.
*/

#import <libxml/xpathInternals.h>
#import "HMXMLNode.h"
#import "HMXMLElement.h"
#import "HMXMLUtilities.h"

static NSArray* _childElementsOf(xmlNodePtr xNode, HMXMLNode* contextNode)
{
    NSMutableArray* childElements;
    childElements = [NSMutableArray array];
    
    // Get children
    xmlNodePtr  childrenHeadPtr;
    childrenHeadPtr = xNode->children;
    if (!childrenHeadPtr) {
        return childElements;
    }
    
    // Collect children
    xmlNode*    currentNode;
    currentNode = childrenHeadPtr;
    while (currentNode) {
        // For element
        if (currentNode->type == XML_ELEMENT_NODE) {
            HMXMLElement*   childElement;
            childElement = [HMXMLElement elementWithXMLNode:currentNode];
            if (childElement) {
                [childElements addObject:childElement];
            }
        }
        // For text node
        else if (currentNode->type == XML_TEXT_NODE) {
            HMXMLNode*  childNode;
            childNode = [HMXMLNode nodeWithXMLNode:currentNode];
            if (childNode) {
                [childElements addObject:childNode];
            }
        }
        
        currentNode = currentNode->next;
    }
    
    return childElements;
}

@implementation HMXMLNode

// Property
@synthesize xNode = _xNode;
@synthesize xmlDocument = _xDocument;
@synthesize rootElement = _rootElement;

@synthesize name = _name;
@synthesize namespacePrefix = _namespacePrefix;
@synthesize qualifiedName = _qualifiedName;
@synthesize children = _children;
@synthesize childCount = _childCount;
@synthesize firstChild = _firstChild;
@synthesize lastChild = _lastChild;

@synthesize parent = _parent;
@synthesize nextNode = _nextNode;
@synthesize nextSibling = _nextSibling;
@synthesize previousNode = _previousNode;
@synthesize previousSibling = _previousSibling;

@synthesize XMLString = _XMLString;
@synthesize stringValue = _stringValue;

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (HMXMLNode*)nodeWithXMLNode:(xmlNode*)xNode
{
    // Check node type
    if (xNode->type != XML_TEXT_NODE && 
        xNode->type != XML_CDATA_SECTION_NODE)
    {
        return nil;
    }
    
    // Create XML node
    HMXMLNode *node = [[HMXMLNode alloc] init];
    [node autorelease];
    node.xNode = xNode;
    
    return node;
}

+ (HMXMLNode*)nodeWithName:(NSString*)name
{
    // Create x node
    xmlNode*    xNode;
    xNode = xmlNewNode(NULL, (xmlChar*)[name UTF8String]);
    
    // Create node
    HMXMLNode*  node;
    node = [[HMXMLNode alloc] init];
    [node autorelease];
    node.xNode = xNode;
    
    return node;
}

- (id)init
{
    // Super
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Initialize self
    _xNode = nil;
    _xpathContext = nil;
    _xDocument = nil;
    
    return self;
}

- (NSString*)description
{
    return [self XMLString];
}

- (void)dealloc
{
    // Clena up
    if (_xpathContext) {
        xmlXPathFreeContext(_xpathContext), _xpathContext = nil;
    }
    _xNode = nil;
    _xDocument = nil;
    
    // Super
    [super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//

- (HMXMLElement*)rootElement
{
    // Get root element
    HMXMLElement*   rootElement = nil;
    HMXMLElement*   parentNode;
    parentNode = (HMXMLElement*)self;
    while (parentNode) {
        parentNode = [parentNode parent];
        rootElement = parentNode;
    }
    
    return rootElement;
}

- (int)kind
{
    switch (self.xNode->type) {
    case XML_ELEMENT_NODE: return HMXMLElementKind;
    case XML_ATTRIBUTE_NODE: return HMXMLAttributeKind;
    case XML_TEXT_NODE: return HMXMLTextKind;
    case XML_PI_NODE: return HMXMLProcessingInstructionKind;
    case XML_COMMENT_NODE: return HMXMLCommentKind;
    case XML_DOCUMENT_NODE: return HMXMLDocumentKind;
    case XML_DTD_NODE: return HMXMLDTDKind;
    case XML_ATTRIBUTE_DECL: return HMXMLAttributeDeclarationKind;
    case XML_ENTITY_DECL: return HMXMLEntityDeclarationKind;
    case XML_ELEMENT_DECL: return HMXMLElementDeclarationKind;
    
    case XML_CDATA_SECTION_NODE:
    case XML_ENTITY_REF_NODE:
    case XML_ENTITY_NODE:
    case XML_DOCUMENT_TYPE_NODE:
    case XML_DOCUMENT_FRAG_NODE:
    case XML_NOTATION_NODE:
    case XML_HTML_DOCUMENT_NODE:
    case XML_NAMESPACE_DECL:
    case XML_XINCLUDE_START:
    case XML_XINCLUDE_END: return HMXMLInvalidKind;
    default: break;
    }
    
    return HMXMLInvalidKind;
}

- (NSString*)name
{
    return [HMXMLUtilities stringWithXMLChar:self.xNode->name];
}

- (const xmlChar*)rawName
{
    return self.xNode->name;
}

- (NSString*)namespacePrefix
{
    // Check namespace
    if (!self.xNode->ns) {
        return nil;
    }
    
    // Create namespace
    return [HMXMLUtilities stringWithXMLChar:self.xNode->ns->prefix];
}

- (NSString*)qualifiedName
{
    return [NSString stringWithFormat:@"%@:%@", self.namespacePrefix, self.name];
}

- (NSArray*)children
{
    return _childElementsOf(self.xNode, self);
}

- (NSUInteger)childCount
{
    return [self.children count];
}

- (HMXMLElement*)firstChild
{
    // Check children
    if ([self.children count] == 0) {
        return nil;
    }
    
    // Get first child
    return [self.children objectAtIndex:0];
}

- (HMXMLElement*)lastChild
{
    // Check children
    if ([self.children count] == 0) {
        return nil;
    }
    
    // Get last child
    return [self.children lastObject];
}

- (HMXMLElement*)parent
{
    return [HMXMLElement elementWithXMLNode:self.xNode->parent];
}

- (HMXMLNode*)nextNode
{
    // Get next sibling
    HMXMLNode*  nextNode;
    nextNode = [self nextSibling];
    if (nextNode) {
        return nextNode;
    }
    
    // Get parent's next sibling
    xmlNode*    xNextNode;
    xNextNode = self.xNode->parent->next;
    
    return [HMXMLElement elementWithXMLNode:xNextNode];
}
    
- (HMXMLNode*)nextSibling
{
    // Get next sibling
    xmlNode*    xNextSibling;
    xNextSibling = self.xNode->next;
    if (!xNextSibling) {
        return nil;
    }
    
    // Create XML element or node
    if (xNextSibling->type == XML_ELEMENT_NODE) {
        return [HMXMLElement elementWithXMLNode:xNextSibling];
    }
    return [HMXMLNode nodeWithXMLNode:xNextSibling];
}

- (HMXMLNode*)previousNode
{
    // Get previous sibling
    HMXMLNode*  prevNode;
    prevNode = [self previousSibling];
    if (prevNode) {
        return prevNode;
    }
    
    // Get parent
    return [self parent];
}

- (HMXMLNode*)previousSibling
{
    // Get previous sibling
    xmlNode*    xPrevSibling;
    xPrevSibling = self.xNode->prev;
    if (!xPrevSibling) {
        return nil;
    }
    
    // Create XML element or node
    if (xPrevSibling->type == XML_ELEMENT_NODE) {
        return [HMXMLElement elementWithXMLNode:xPrevSibling];
    }
    return [HMXMLNode nodeWithXMLNode:xPrevSibling];
}

- (NSString*)XMLString
{
    return [NSString stringWithFormat:@"%@", self.stringValue];
}

- (NSString*)stringValue
{
    // Get node content
    xmlChar*    content;
    NSString*   stringValue;
    content = xmlNodeGetContent(self.xNode);
    stringValue = [HMXMLUtilities stringWithXMLChar:content];
    xmlFree(content);
    
    return stringValue;
}

- (xmlChar*)createRawStringValue
{
    // Get node content
    xmlChar*    content;
    content = xmlNodeGetContent(self.xNode);
    
    // Need to free
    return content;
}

//--------------------------------------------------------------//
#pragma mark -- Navigation --
//--------------------------------------------------------------//

- (HMXMLNode*)firstChildNamed:(NSString*)matchName
{
    // Get children named
    NSArray*    childrenNamed;
    childrenNamed = [self childrenNamed:matchName];
    if ([childrenNamed count] == 0) {
        return nil;
    }
    
    // Get first child
    return [childrenNamed objectAtIndex:0];
}

- (HMXMLNode*)firstDescendantNamed:(NSString*)matchName
{
    // Get descendants named
    NSArray*    descendantsNamed;
    descendantsNamed = [self descendantsNamed:matchName];
    if ([descendantsNamed count] == 0) {
        return nil;
    }
    
    // Get first descendatn
    return [descendantsNamed objectAtIndex:0];
}

- (NSArray*)childrenNamed:(NSString*)matchName
{
    // Create XPath
    NSString*   xpath;
    xpath = [NSString stringWithFormat:@"%@", matchName];
    
    // Query XPath
    return [self nodesForXPath:xpath prepareNamespaces:[NSArray arrayWithObject:matchName] error:nil];
}

- (NSArray*)descendantsNamed:(NSString*)matchName
{
    // Create XPath
    NSString*   xpath;
    xpath = [NSString stringWithFormat:@"//%@", matchName];
    
    // Query XPath
    return [self nodesForXPath:xpath prepareNamespaces:[NSArray arrayWithObject:matchName] error:nil];
}

- (NSArray*)elementsWithAttributeNamed:(NSString*)attributeName
{
    // Create XPath
    NSString*   xpath;
    xpath = [NSString stringWithFormat:@"//*[@%@]", attributeName];
    
    // Query XPath
    return [self nodesForXPath:xpath prepareNamespaces:nil error:nil];
}

- (HMXMLNode*)addNodeWithName:(NSString*)name content:(NSString*)content
{
    // Create new node
    xmlNode*    xNode;
    xNode = xmlNewChild(
            _xNode, NULL, (const xmlChar*)[name UTF8String], (const xmlChar*)[content UTF8String]);
    
    // For element
    if (xNode->type == XML_ELEMENT_NODE) {
        return [HMXMLElement elementWithXMLNode:xNode];
    }
    
    // For text
    if (xNode->type == XML_TEXT_NODE) {
        return [HMXMLElement elementWithXMLNode:xNode];
    }
    
    return nil;
}

- (HMXMLElement*)addElementWithName:(NSString*)name attributes:(NSDictionary*)attributes
{
    // Create new node
    xmlNode*    xNode;
    xNode = xmlNewChild(
            _xNode, NULL, (const xmlChar*)[name UTF8String], NULL);
    
    // Add attributes
    for (NSString* key in [attributes keyEnumerator]) {
        // Get value
        NSString*   value;
        value = [attributes valueForKey:key];
        
        // Set prop
        xmlSetProp(
                xNode, (const xmlChar*)[key UTF8String], (const xmlChar*)[value UTF8String]);
    }
    
    // For element
    if (xNode->type == XML_ELEMENT_NODE) {
        return [HMXMLElement elementWithXMLNode:xNode];
    }
    
    return nil;
}

- (void)addChildNode:(HMXMLNode*)node
{
    // Append node
    xmlAddChild(_xNode, node.xNode);
}

- (void)addPrevSiblingNode:(HMXMLNode*)node
{
    // Add prev sibling node
    xmlAddPrevSibling(_xNode, node.xNode);
}

- (void)addNextSiblingNode:(HMXMLNode*)node
{
    // Add next sibling node
    xmlAddNextSibling(_xNode, node.xNode);
}

//--------------------------------------------------------------//
#pragma mark -- XPath --
//--------------------------------------------------------------//

- (NSArray*)_nodesForXPath:(NSString*)XPath error:(NSError**)error
{
    // Get XML document and node
    xmlDocPtr   xDocument = self.xmlDocument;
    xmlNode*    xNode = self.xNode;
    
    // Convert XPath
    const xmlChar*  xpathChar;
    xpathChar = (const xmlChar*)[XPath UTF8String];
    if (!xpathChar) {
        if (error) {
            *error = [HMXMLUtilities errorWithString:
                    @"-[HMXMLElement _nodesForXPath:error:] was passed a nil XPath."];
        }
        return nil;
    }
	
    // Check XPath context
    if (!_xpathContext) {
        _xpathContext = xmlXPathNewContext(xDocument); 
    }
    if (!_xpathContext) {
        if (error) {
            *error = [HMXMLUtilities errorWithString:
                    @"-[HMXMLElement _nodesForXPath:error:] _xpathContext is nil or could not be created."];
        }
        return nil;
    }
	
    // Set node to XPath context
    _xpathContext->node = xNode;
    
    // Query XPath
    xmlXPathObjectPtr queryResults;
    queryResults = xmlXPathEvalExpression(xpathChar, _xpathContext);
    if (!queryResults) {
        if (error) {
            *error = [HMXMLUtilities errorWithString:
                    @"-[HMXMLElement _nodesForXPath:error:] xmlXPathEvalExpression failed."];
        }
        return nil;
    }
    
    // Create elements
    NSMutableArray* resultElements;
    NSUInteger      size, i;
    resultElements = [NSMutableArray array];
    size = (queryResults->nodesetval) ? queryResults->nodesetval->nodeNr : 0;
    for (i = 0; i < size; i++) {
        // Get next node
        xmlNode*    nextNode;
        nextNode = queryResults->nodesetval->nodeTab[i];
        if (!nextNode || nextNode->type != XML_ELEMENT_NODE) {
            continue;
        }
        
        // Create element
        HMXMLElement*   resultElement;
        resultElement = [HMXMLElement elementWithXMLNode:nextNode];
        [resultElements addObject:resultElement];
    }
    
	if(nil != _xpathContext){
		xmlXPathFreeContext(_xpathContext), _xpathContext = nil;
	}

    // Free queryResults
    xmlXPathFreeObject(queryResults);
    
    return resultElements;
}

- (HMXMLNode*)singleNodeForXPath:(NSString*)XPath error:(NSError**)error
{
    NSArray*    nodes;
    nodes = [self nodesForXPath:XPath error:error];
    if ([nodes count] == 0) {
        return nil;
    }
    
    return [nodes objectAtIndex:0];
}

- (NSArray*)nodesForXPath:(NSString*)XPath error:(NSError**)error
{
	return [self nodesForXPath:XPath prepareNamespaces:nil error:error];
}

- (NSArray*)nodesForXPath:(NSString*)XPath 
        prepareNamespaces:(NSArray*)nodeNames error:(NSError**)error
{
    // Create XPath context
    if (_xpathContext) {
        xmlXPathFreeContext(_xpathContext), _xpathContext = nil;
    }
    _xpathContext = xmlXPathNewContext(self.xmlDocument);
    
    // Check namespace nodes
    for (NSString* nodeName in nodeNames) {
        // Get colon range
        NSRange colonRange;
        colonRange = [nodeName rangeOfString:@":"];
        if (colonRange.location != NSNotFound) {
            // Get prefix
            NSString*       prefix;
            const xmlChar*  prefixChars;
            prefix = [nodeName substringToIndex:colonRange.location];
            prefixChars = (xmlChar*)[prefix cStringUsingEncoding:NSUTF8StringEncoding];
            
            // Register namespace
            if (xmlXPathRegisterNs(_xpathContext, prefixChars, (xmlChar*)"") != 0) {
                xmlXPathFreeContext(_xpathContext), _xpathContext = nil;
            }
        }
    }
	
	if(nil != _xpathContext){
		xmlXPathFreeContext(_xpathContext), _xpathContext = nil;
	}
    
    // Get nodes for XPath
    return [self _nodesForXPath:XPath error:error];
}

@end
