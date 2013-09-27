/*
HMXMLRPCStreamDecoder.m

Author: Makoto Kinsohita

Copyright 2009 HMDT. All rights reserved.
*/

#import "HMXMLRPCStreamDecoder.h"

@interface HMXMLRPCStreamDecoder (private)

- (void)startElementLocalName:(const xmlChar*)localname 
        prefix:(const xmlChar*)prefix 
        URI:(const xmlChar*)URI 
        nb_namespaces:(int)nb_namespaces 
        namespaces:(const xmlChar**)namespaces 
        nb_attributes:(int)nb_attributes 
        nb_defaulted:(int)nb_defaulted 
        attributes:(const xmlChar**)attributes;
- (void)endElementLocalName:(const xmlChar*)localname 
        prefix:(const xmlChar*)prefix URI:(const xmlChar*)URI;
- (void)charactersFound:(const xmlChar*)ch 
        len:(int)len;

@end

static void startElementHandler(
        void* ctx, 
        const xmlChar* localname, 
        const xmlChar* prefix, 
        const xmlChar* URI, 
        int nb_namespaces, 
        const xmlChar** namespaces, 
        int nb_attributes, 
        int nb_defaulted, 
        const xmlChar** attributes)
{
    [(HMXMLRPCStreamDecoder*)ctx 
            startElementLocalName:localname 
            prefix:prefix URI:URI 
            nb_namespaces:nb_namespaces 
            namespaces:namespaces 
            nb_attributes:nb_attributes 
            nb_defaulted:nb_defaulted 
            attributes:attributes];
}

static void	endElementHandler(
        void* ctx, 
        const xmlChar* localname, 
        const xmlChar* prefix, 
        const xmlChar* URI)
{
    [(HMXMLRPCStreamDecoder*)ctx 
            endElementLocalName:localname 
            prefix:prefix 
            URI:URI];
}

static void	charactersFoundHandler(
        void* ctx, 
        const xmlChar* ch, 
        int len)
{
    [(HMXMLRPCStreamDecoder*)ctx 
            charactersFound:ch len:len];
}

static xmlSAXHandler _saxHandlerStruct = {
    NULL,            /* internalSubset */
    NULL,            /* isStandalone   */
    NULL,            /* hasInternalSubset */
    NULL,            /* hasExternalSubset */
    NULL,            /* resolveEntity */
    NULL,            /* getEntity */
    NULL,            /* entityDecl */
    NULL,            /* notationDecl */
    NULL,            /* attributeDecl */
    NULL,            /* elementDecl */
    NULL,            /* unparsedEntityDecl */
    NULL,            /* setDocumentLocator */
    NULL,            /* startDocument */
    NULL,            /* endDocument */
    NULL,            /* startElement*/
    NULL,            /* endElement */
    NULL,            /* reference */
    charactersFoundHandler, /* characters */
    NULL,            /* ignorableWhitespace */
    NULL,            /* processingInstruction */
    NULL,            /* comment */
    NULL,            /* warning */
    NULL,            /* error */
    NULL,            /* fatalError //: unused error() get all the errors */
    NULL,            /* getParameterEntity */
    NULL,            /* cdataBlock */
    NULL,            /* externalSubset */
    XML_SAX2_MAGIC,  /* initialized */
    NULL,            /* private */
    startElementHandler,    /* startElementNs */
    endElementHandler,      /* endElementNs */
    NULL,            /* serror */
};

@implementation HMXMLRPCStreamDecoder

// Property
@synthesize decodedObject = _decodedObject;
@synthesize error = _error;

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (id)initWithRequest:(NSURLRequest*)request delegate:(id)delegate
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Initialize instance variables
    _collectionStack = [[NSMutableArray array] retain];
    _delegate = delegate;
    
    // Create XML parser
    _parserContext = xmlCreatePushParserCtxt(&_saxHandlerStruct, self, NULL, 0, NULL);
    
    // Create date formater
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Create date formats
    _formats = [[NSArray arrayWithObjects:
            @"yyyyMMdd'T'HH:mm:ss",
            @"yyyy-MM-dd'T'HH:mm:ss'Z'",
            nil] retain];
    
    // Start download
    _connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
    
    return self;
}

- (void)dealloc
{
    // Cancel connection
    [self cancel];
    
    // Release instance variables
    if (_parserContext) {
        xmlFreeParserCtxt(_parserContext), _parserContext = NULL;
    }
    [_error release], _error = nil;
    [_decodedObject release], _decodedObject = nil;
    [_collectionStack release], _collectionStack = nil;
    [_dateFormatter release], _dateFormatter = nil;
    [_formats release], _formats = nil;
    
    // Invoke super
    [super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Cancel --
//--------------------------------------------------------------//

- (void)cancel
{
    // Clear connection
    [_connection release], _connection = nil;
}

//--------------------------------------------------------------//
#pragma mark -- NSURLConnection delegate --
//--------------------------------------------------------------//

- (void)connection:(NSURLConnection*)connection 
        didReceiveResponse:(NSURLResponse*)response
{
    // Check status code
    if ([(NSHTTPURLResponse*)response statusCode] != 200) {
        // Error
        //NSLog(@"request failed, statusCode is %d", [(NSHTTPURLResponse*)response statusCode]);
    }
}

- (void)connection:(NSURLConnection*)connection
		didReceiveData:(NSData*)data
{
    // Add chunk data
    xmlParseChunk(_parserContext, (const char*)[data bytes], [data length], 0);
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    // Terminate chunk data
    xmlParseChunk(_parserContext, NULL, 0, 1);
    
    // Release XML parser
    if (_parserContext) {
        xmlFreeParserCtxt(_parserContext), _parserContext = NULL;
    }
    
    // Clear connection
    [_connection release], _connection = nil;
    
    // Notify to delegate
    if ([_delegate respondsToSelector:@selector(xmlRPCStreamDecoderDidFinishDecoding:)]) {
        [_delegate xmlRPCStreamDecoderDidFinishDecoding:self];
    }
}

- (void)connection:(NSURLConnection*)connection
		didFailWithError:(NSError*)error
{
    // Set error
    [_error release], _error = nil;
    _error = [error retain];
    
    // Release XML parser
    if (_parserContext) {
        xmlFreeParserCtxt(_parserContext), _parserContext = NULL;
    }
    
    // Clear connection
    [_connection release], _connection = nil;
    
    // Notify to delegate
    if ([_delegate respondsToSelector:@selector(xmlRPCStreamDecoderDidFinishDecoding:)]) {
        [_delegate xmlRPCStreamDecoderDidFinishDecoding:self];
    }
}

//--------------------------------------------------------------//
#pragma mark -- libxml handler --
//--------------------------------------------------------------//

- (void)startElementLocalName:(const xmlChar*)localname 
        prefix:(const xmlChar*)prefix 
        URI:(const xmlChar*)URI 
        nb_namespaces:(int)nb_namespaces 
        namespaces:(const xmlChar**)namespaces 
        nb_attributes:(int)nb_attributes 
        nb_defaulted:(int)nb_defaulted 
        attributes:(const xmlChar**)attributes
{
    // array
    if (strncmp((char*)localname, "array", sizeof("array")) == 0) {
        // Push array
        [_collectionStack addObject:[NSMutableArray array]];
        
        // For first one
        if (!_decodedObject && [_collectionStack count] == 1) {
            _decodedObject = [[_collectionStack lastObject] retain];
        }
        
        return;
    }
    
    // struct
    if (strncmp((char*)localname, "struct", sizeof("struct")) == 0) {
        // Push dictionary
        [_collectionStack addObject:[NSMutableDictionary dictionary]];
        
        // For first one
        if (!_decodedObject && [_collectionStack count] == 1) {
            _decodedObject = [[_collectionStack lastObject] retain];
        }
        
        return;
    }
    
    // value
    if (strncmp((char*)localname, "value", sizeof("value")) == 0) {
        // Increment flag
        _valueCount++;
        
        // Reset buffer
        _tmp = _buffer;
    }
    
    // name
    if (strncmp((char*)localname, "name", sizeof("name")) == 0) {
        // Set flag
        _isName = YES;
        
        // Reset buffer
        _tmp = _buffer;
    }
}

- (void)_addObject:(id)object
{
    // Get current collection
    id  collection;
    collection = [_collectionStack lastObject];
    
    // For array
    if ([collection isKindOfClass:[NSArray class]]) {
        [collection addObject:object];
    }
    
    // For dictionary
    else if ([collection isKindOfClass:[NSDictionary class]]) {
        if (_name) {
            [collection setObject:object forKey:_name];
            
            // Release name
            [_name release], _name = nil;
        }
    }
    
    // For other
    if (!collection) {
        // Add object
        [_collectionStack addObject:object];
    }
}

- (void)endElementLocalName:(const xmlChar*)localname 
        prefix:(const xmlChar*)prefix URI:(const xmlChar*)URI
{
    // array and struct
    if ((strncmp((char*)localname, "array", sizeof("array")) == 0) || 
        (strncmp((char*)localname, "struct", sizeof("struct")) == 0))
    {
        // Pop object and insert it
        id  object;
        object = [[_collectionStack lastObject] retain];
        [_collectionStack removeLastObject];
        [self _addObject:object];
        [object release];
        
        return;
    }
    
    // value
    if (strncmp((char*)localname, "value", sizeof("value")) == 0) {
        // Decrement flag
        _valueCount--;
        
        return;
    }
    
    // For name
    if (_isName) {
        // Terminate buffer
        *_tmp++ = 0;
        
        // Create string
        [_name release], _name = nil;
        _name = [[NSString stringWithCString:_buffer encoding:NSUTF8StringEncoding] retain];
        
        // Clear flag
        _isName = NO;
        
        return;
    }
    
    // For value
    if (_valueCount) {
        // Get current collection
//        id  collection;
//        collection = [_collectionStack lastObject];
        
        // Prepare for value
        id  value = nil;
        
        // i4 or int
        if ((strncmp((char*)localname, "i4", sizeof("i4")) == 0) || 
            (strncmp((char*)localname, "int", sizeof("int")) == 0))
        {
            // Terminate buffer
            *_tmp++ = 0;
            
            // Create number
            int intValue;
            intValue = atoi(_buffer);
            value = [NSNumber numberWithInt:intValue];
        }
        
        // boolean
        else if (strncmp((char*)localname, "boolean", sizeof("boolean")) == 0) {
            // Create number
            BOOL    boolValue;
            boolValue = *_buffer == '0' ? NO : YES;
            value = [NSNumber numberWithBool:boolValue];
        }
        
        // string
        else if (strncmp((char*)localname, "string", sizeof("string")) == 0) {
            // Terminate buffer
            *_tmp++ = 0;
            
            // Create string
            value = [NSString stringWithCString:_buffer encoding:NSUTF8StringEncoding];
        }
        
        // double
        else if (strncmp((char*)localname, "double", sizeof("double")) == 0) {
            // Terminate buffer
            *_tmp++ = 0;
            
            // Create number
            double  doubleValue;
            doubleValue = atof(_buffer);
            value = [NSNumber numberWithDouble:doubleValue];
        }
        
        // dateTime.iso8601
        else if (strncmp((char*)localname, "dateTime.iso8601", sizeof("dateTime.iso8601")) == 0) {
            // Terminate buffer
            *_tmp++ = 0;
            
            // Create string
            NSString*   dateString;
            dateString = [[NSString alloc] initWithCString:_buffer encoding:NSUTF8StringEncoding];
            
            // Get date from string
            for (NSString* format in _formats) {
                [_dateFormatter setDateFormat:format];
                value = [_dateFormatter dateFromString:dateString];
                if (value) {
                    break;
                }
            }
            
            // Release temp variables
            [dateString release], dateString = nil;
        }
        
        // Add value
        if (value) {
            [self _addObject:value];
            
            // For first one
            if (!_decodedObject && [_collectionStack count] == 1) {
                _decodedObject = [[_collectionStack lastObject] retain];
            }
        }
    }
}

- (void)charactersFound:(const xmlChar*)ch 
        len:(int)len
{
    // Append characters
    if (_valueCount) {
        // Check size
        if (_tmp + len > _buffer + BUFFER_MAX_SIZE) {
            //NSLog(@"HMXMLRPCStreamDecoder: Caution, beyond buffer max size");
            len = _buffer + BUFFER_MAX_SIZE - _tmp;
        }
        
        // Copy characters
        memcpy(_tmp, ch, len);
        _tmp += len;
    }
}

@end
