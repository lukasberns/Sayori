/*
HMXMLRPCStreamDecoder.h

Author: Makoto Kinsohita

Copyright 2009 HMDT. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

#define BUFFER_MAX_SIZE 4096

@interface HMXMLRPCStreamDecoder : NSObject
{
    xmlParserCtxtPtr    _parserContext;
    NSURLConnection*    _connection;
    NSError*            _error;
    
    id                  _decodedObject;
    NSMutableArray*     _collectionStack;
    int                 _valueCount;
    BOOL                _isName;
    NSString*           _name;
    char                _buffer[BUFFER_MAX_SIZE];
    char*               _tmp;
    
    NSDateFormatter*    _dateFormatter;
    NSArray*            _formats;
    
    id                  _delegate;
}

// Property
@property (nonatomic, readonly) id decodedObject;
@property (nonatomic, retain) NSError* error;

// Initialize
- (id)initWithRequest:(NSURLRequest*)request delegate:(id)delegate;

// Cancel
- (void)cancel;

@end

@interface NSObject (HMXMLRPCStreamDecoderDelegate)

- (void)xmlRPCStreamDecoderDidFinishDecoding:(HMXMLRPCStreamDecoder*)decoder;

@end
