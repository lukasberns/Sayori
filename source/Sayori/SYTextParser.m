/*
SYTextParser.m

Author: Makoto Kinoshita, Hajime Nakamura, Mitsuru Nakada

Copyright 2010-2013 HMDT. All rights reserved.
*/

#import "SYCssContext.h"
#import "SYTextParser.h"

#define SY_TEXT_INLINESTYLE_BUFFER_MAX  10000
#define SY_TEXT_BLOCKSTYLE_BUFFER_MAX   10000

void _parseNode(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYCssContext* cssContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
#if TARGET_OS_IPHONE
        HMXMLNode* node
#elif TARGET_OS_MAC
        NSXMLNode* node
#endif
        );

//--------------------------------------------------------------//
#pragma mark -- Tokenize --
//--------------------------------------------------------------//

#if 0
static BOOL _isNumeric(
        unichar uc) 
{
    if ('0' <= uc && uc <= '9') {
        return YES;
    }
    
    return NO;
}
#endif

static BOOL _isAlphaNumeric(
        unichar uc) 
{
    if ('0' <= uc && uc <= '9') {
        return YES;
    }
    else if ('A' <= uc && uc <= 'Z') {
        return YES;
    }
    else if ('a' <= uc && uc <= 'z') {
        return YES;
    }
    else if (0x00C0 /* À */ <= uc && uc <= 0x02AF /* ʯ */) {// Latin extentions
        return YES;
    }
    else if (0x0400 /* Ѐ */ <= uc && uc <= 0x0527 /* ԧ */) {// Cyrillic alphabets
        return YES;
    }
    else if (0x0370 /* Ͱ */ <= uc && uc <= 0x03ff /* Ͽ */) {// Greek alphabets
        return YES;
    }
    
    return NO;
}

static BOOL _isSpaceOrNewLine(
        unichar uc)
{
    return uc == ' ' || uc == '\n' || uc == '\r' || uc == '\t';
}

static BOOL _isTabOrNewLine(
        unichar uc)
{
    return uc == '\n' || uc == '\r' || uc == '\t';
}

#if 0
static BOOL _isBeginParentheses(
        unichar uc)
{
    return uc == '(' || 
            uc == 0x3010 || // '【'
            uc == 0x3016 || // '〖'
            uc == 0x300a; // '《'
}

static BOOL _isEndParentheses(
        unichar uc)
{
    return uc == ')' || 
            uc == 0x3011 || // '】'
            uc == 0x3017 || // '〗'
            uc == 0x300b; // '》'
}
#endif

static BOOL _isNonLetter(
        unichar uc)
{
    // For ! " # $ % & ' ( )
    if ('!' <= uc && uc <= ')') {
        return YES;
    }
    
    // For  : ; < = > ?
    else if (':' <= uc && uc <= '?') {
        return YES;
    }
    
    return NO;
}

static BOOL _isPrefixLetter(
        unichar uc)
{
    return uc == '\'' || 
            uc == '"' || 
            uc == 0xa5; // '¥'
}

static BOOL _isSuffixLetter(
        unichar uc)
{
    return uc == '$' || 
            uc == '+' || 
            uc == '-' || 
            uc == '%' || 
            uc == 0xb0 || // '°'
            uc == 0xb1; // '±'
}

static BOOL _isPunctuation(
        unichar uc)
{
    return uc == '.' || 
            uc == ',' || 
            uc == '-' || 
            uc == ':' || 
            uc == ';' ||
            uc == '/' ||
            uc == '=' ||
            uc == '[' ||
            uc == ']' ||
            uc == 0xff1d || // '＝'
            uc == 0x00d7 || // '×'
            uc == 0x2212 || // '-'
            uc == 0x2015 || // '―'
            uc == 0x221a;   // '√'
}

static unsigned int _nextToken(
        const unichar* buffer, NSUInteger length)
{
    // Check length
    if (length == 0) {
        return 0;
    }
    
    // Search token
    BOOL            alphaNumeric = NO;
    BOOL            punctuation = NO;
    BOOL            highSurrogate = NO;
    const unichar*  tmp;
    tmp = buffer;
    while (tmp - buffer < length) {
        // Get char
        unichar c;
        c = *tmp++;
        
        // For space or new line
        if (_isSpaceOrNewLine(c)) {
            // Roll back pointer
            if (tmp > buffer + 1) {
                tmp--;
            }
            
            break;
        }
        
        // For puctuation
        if (punctuation) {
            // Puncutuation again or numeric
            if (_isPunctuation(c) || _isAlphaNumeric(c)) {
                continue;
            }
            
            // Roll back pointer
            if (tmp > buffer) {
                tmp--;
            }
            
            break;
        }
        if (_isPunctuation(c) && alphaNumeric) {
            // Set flag
            punctuation = YES;
            
            continue;
        }
        
        // For alpha numeric
        if (_isAlphaNumeric(c)) {
            // Set flag
            alphaNumeric = YES;
            
            continue;
        }
        
        // For prefix letter
        if (_isPrefixLetter(c)) {
            continue;
        }
        
        // For suffix letter
        if (_isSuffixLetter(c) && alphaNumeric) {
            continue;
        }
        
        // For non letter
        if (_isNonLetter(c)) {
            // For '(' or ')'
            if (c == '(' || c == ')') {
                // Roll back pointer
                if (tmp > buffer + 1) {
                    tmp--;
                }
            }
            
            break;
        }
        
        // Check flag for non alpha numeric
        if (alphaNumeric) {
            // Roll back pointer
            if (tmp > buffer) {
                tmp--;
            }
            
            break;
        }
        
        // For EM DASH
        if (c == 0x2014) {
            // For single
            if (tmp - buffer == 1) {
                continue;
            }
            
            // For double
            if (tmp - buffer == 2) {
                // Check first char
                if (*(tmp - 1) == 0x2014) {
                    // Double dash
                    break;
                }
            }
            
            // Not double dash
            tmp--;
            
            break;
        }
        
        // For HORIZONTAL ELLIPSIS
        if (c == 0x2026) {
            // For single
            if (tmp - buffer == 1) {
                continue;
            }
            
            // For double
            if (tmp - buffer == 2) {
                // Check first char
                if (*(tmp - 1) == 0x2026) {
                    // Double dash
                    break;
                }
            }
            
            // Not double dash
            tmp--;
            
            break;
        }
        
        // For surrogate pair: low
        if (highSurrogate) {
            // Clear flag
            highSurrogate = NO;
            
            if (0xdc00 <=  c && c <= 0xdfff) {
#ifdef DEBUG_SURROGATE_PAIR
                NSLog(@"surrogate pair: low|0x%x", c);
#endif
                break;
            }
            else {
                NSLog(@"[CAUTION] Invalid low surrogate value: 0x%x", c);
            }
        }
        
        // For surrogate pair: high
        if (0xd800 <= c && c <= 0xdbff) {
            
#ifdef DEBUG_SURROGATE_PAIR
            NSLog(@"surrogate pair: high|0x%x", c);
#endif
            
            // Set flag
            highSurrogate = YES;
            continue;
        }
        
        // For other
        break;
    }
    
    return (unsigned int)(tmp - buffer);
}

//--------------------------------------------------------------//
#pragma mark -- Conversion --
//--------------------------------------------------------------//

NSString* _convertNumericToKanji(
        NSString* text)
{
    // Initialize kanij number
    static NSArray* _kanjiNumber = nil;
    if (!_kanjiNumber) {
        _kanjiNumber = @[
            @"〇", @"一", @"二", @"三", @"四", 
            @"五", @"六", @"七", @"八", @"九", 
        ];
    }

    // Convert given text
    NSMutableString* kanjiStr = [NSMutableString string];
    for (int i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];

        // For number
        if (c >= 48 /* 0 */ && c <= 57 /* 9 */) {
            [kanjiStr appendString:_kanjiNumber[c-48]];
        }
        
        // For dot
        else if (c == 46) {
            [kanjiStr appendString:@"・"];
        }
        
        // Other
        else {// Do not convert. push original character
            [kanjiStr appendString:[NSString stringWithCharacters:&c length:1]];
        }
    }

    return kanjiStr;
}

//--------------------------------------------------------------//
#pragma mark -- Parse --
//--------------------------------------------------------------//

SYTextRun* _createRun(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
        int runType, 
        unichar* character, 
        NSUInteger length)
{
    // Allocate run
    SYTextRun*  run;
    run = SYTextRunContextAllocateRun(runContext);
    
    // Set run type
    run->type = runType;
    
    // Set text length
    run->textLength = length;
    
    // Set text
    if (run->textLength <= SY_RUN_TEXTBUFFER_MAX) {
        // Set text
        memcpy(run->textBuffer, character, sizeof(unichar) * length);
        
        // Set text buffer as text
        run->text = run->textBuffer;
    }
    else {
        // Allocate text buffer
        unichar*    textBuffer;
        textBuffer = malloc(sizeof(unichar) * run->textLength);
        
        // Set text
        memcpy(textBuffer, character, sizeof(unichar) * length);
        
        // Set external text buffer as text
        run->text = textBuffer;
    }
    
    // Set style
    run->inlineStyle = inlineStyle;
    run->blockStyle = blockStyle;
    
    // Make glyph NULL
    run->glyphs = NULL;
    
    return run;
}

void _createRuns(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
        int runType, 
        NSString* text, 
        SYTextRun** outRuns, 
        unsigned int* outRunsLength)
{
    // Get characters
    unsigned int    length;
    unichar*        characters;
    unichar*        tmp;
    length = (unsigned int)[text length];
    characters = malloc(sizeof(unichar) * length);
    [text getCharacters:characters range:NSMakeRange(0, [text length])];
    tmp = characters;
    
    // Parse tokens
    unsigned int    count = 0;
    while (tmp - characters < length) {
        // Get next token
        unsigned int    tokenLength;
        tokenLength = _nextToken(tmp, characters + length - tmp);
        if (tokenLength == 0) {
            break;
        }
        
        // For space or new line
        if (tokenLength == 1 && _isTabOrNewLine(*tmp)) {
            goto nextToken;
        }
        
        // Create token run
        SYTextRun*  run;
        run = _createRun(parser, runContext, inlineStyle, blockStyle, runType, tmp, tokenLength);
        
        // Increment count
        count++;
        
        // Set out runs
        if (tmp == characters) {
            if (outRuns) {
                *outRuns = run;
            }
        }
        
nextToken:
        // Increase tmp
        tmp += tokenLength;
    }
    
    // Set out runs length
    if (outRunsLength) {
        *outRunsLength = count;
    }
    
    // Free buffer
    free(characters), characters = NULL;
}

void _parseImgNode(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYCssContext* cssContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
#if TARGET_OS_IPHONE
        HMXMLNode* node
#elif TARGET_OS_MAC
        NSXMLNode* node
#endif
        )
{
#if 0
    // Allocate run for inline begin
    SYTextRun*  inlineBeginRun;
    inlineBeginRun = SYTextRunContextAllocateRun(runContext);
    inlineBeginRun->type = SYRunTypeInlineBegin;
    *(inlineBeginRun->inlineStyle) = *inlineStyle;
    inlineBeginRun->inlineStyle->floatMode = SYStyleFloatLeft;
    inlineBeginRun->blockStyle = blockStyle;
#endif
    
    // Allocate run for image
    SYTextRun*  imageRun;
    imageRun = SYTextRunContextAllocateRun(runContext);
    imageRun->type = SYRunTypeImage;
    imageRun->inlineStyle = inlineStyle;
    imageRun->blockStyle = blockStyle;
    
    // Get width
    NSString*   widthStr;
#if TARGET_OS_IPHONE
    widthStr = [(HMXMLElement*)node attributeForName:@"width"];
#elif TARGET_OS_MAC
    widthStr = [[(NSXMLElement*)node attributeForName:@"width"] stringValue];
#endif
    
    // Set width
    imageRun->rect.size.width = 256.0f;
    
    // Set height
    imageRun->rect.size.height = 256.0f;
    
#if 0
    // Allocate run for inline end
    SYTextRun*  inlineEndRun;
    inlineEndRun = SYTextRunContextAllocateRun(runContext);
    inlineEndRun->type = SYRunTypeInlineEnd;
    inlineEndRun->inlineStyle = inlineBeginRun->inlineStyle;
    inlineBeginRun->blockStyle = inlineBeginRun->blockStyle;
#endif
}

void _parseRubyNode(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYCssContext* cssContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
#if TARGET_OS_IPHONE
        HMXMLNode* node
#elif TARGET_OS_MAC
        NSXMLNode* node
#endif
        )
{
    // Get child node
    SYTextRun*  rbInlineBeginRun = NULL;
    SYTextRun*  rbInlineEndRun = NULL;
    SYTextRun*  rtInlineBeginRun = NULL;
    SYTextRun*  rtInlineEndRun = NULL;
#if TARGET_OS_IPHONE
    for (HMXMLNode* childNode in [node children])
#elif TARGET_OS_MAC
    for (NSXMLNode* childNode in [node children])
#endif
    {
        // Get node name
        const char*     name;
        name = [[childNode name] cStringUsingEncoding:NSASCIIStringEncoding];
        if (!name) {
            return;
        }
        
        // For rb
        if (strcmp(name, "rb") == 0) {
            // Allocate run for ruby begin
            SYTextRun*  rubyBegin;
            rubyBegin = SYTextRunContextAllocateRun(runContext);
            rubyBegin->type = SYRunTypeRubyBegin;
            rubyBegin->inlineStyle = inlineStyle;
            
            // Allocate run for inline begin
            SYTextInlineStyle* rbInlineStyle = malloc(sizeof(SYTextInlineStyle));
            *rbInlineStyle = *inlineStyle;
            rbInlineBeginRun = SYTextRunContextAllocateRun(runContext);
            rbInlineBeginRun->type = SYRunTypeInlineBegin;
            rbInlineBeginRun->inlineStyle = rbInlineStyle;
//            if (rbInlineBeginRun->inlineStyle->linkUrl) {
//                CFRetain((__bridge CFTypeRef)rbInlineBeginRun->inlineStyle->linkUrl);
//            }
            rbInlineStyle->linkUrl = NULL;
            
            // Clear border
            rbInlineStyle->borderTop.value = 0;
            rbInlineStyle->borderRight.value = 0;
            rbInlineStyle->borderBottom.value = 0;
            rbInlineStyle->borderLeft.value = 0;
            
            // Get text
            NSString*   text;
            text = [childNode stringValue];
            
            // Create runs
//            _createRuns(
//                    parser, runContext, rbInlineStyle, blockStyle,
//                    SYRunTypeText, text, NULL, NULL);
#if TARGET_OS_IPHONE
            for (HMXMLNode* n in childNode.children) {
                _parseNode(parser, runContext, cssContext, rbInlineStyle, blockStyle, n);
            }
#elif TARGET_OS_MAC
            for (NSXMLNode* n in childNode.children) {
                _parseNode(parser, runContext, cssContext, rbInlineStyle, blockStyle, n);
            }
#endif
            
            // Allocate run for inline end
            rbInlineEndRun = SYTextRunContextAllocateRun(runContext);
            rbInlineEndRun->type = SYRunTypeInlineEnd;
            rbInlineEndRun->inlineStyle = rbInlineStyle;
            
            // Allocate run for ruby end
            SYTextRun*  rubyEnd;
            rubyEnd = SYTextRunContextAllocateRun(runContext);
            rubyEnd->type = SYRunTypeRubyEnd;
            rubyEnd->inlineStyle = inlineStyle;
        }
        
        // For rt
        if (strcmp(name, "rt") == 0) {
            // Allocate run for inline begin
            SYTextInlineStyle* rtInlineStyle = malloc(sizeof(SYTextInlineStyle));
            *rtInlineStyle = *inlineStyle;
            rtInlineBeginRun = SYTextRunContextAllocateRun(runContext);
            rtInlineBeginRun->type = SYRunTypeRubyInlineBegin;
            rtInlineBeginRun->inlineStyle = rtInlineStyle;
            if (rtInlineBeginRun->inlineStyle->linkUrl) {
                CFRetain((__bridge CFTypeRef)rtInlineBeginRun->inlineStyle->linkUrl);
            }
            
            // Determine ruby font size
            float baseFontSize;// It doesn't mean parser.baseFontSize. No one updates / uses parser.baseFontSize..
            baseFontSize = runContext->runPool->runs->inlineStyle->fontSize;
            rtInlineBeginRun->inlineStyle->fontSize = baseFontSize * 0.5f;// Ruby font size is fixed
            
            // Get text
            NSString*   text;
            text = [childNode stringValue];
            
            // Create runs
            _createRuns(
                    parser, runContext, rtInlineStyle, blockStyle,
                    SYRunTypeRubyText, text, NULL, NULL);
            
            // Allocate run for inline end
            rtInlineEndRun = SYTextRunContextAllocateRun(runContext);
            rtInlineEndRun->type = SYRunTypeRubyInlineEnd;
            rtInlineEndRun->inlineStyle = malloc(sizeof(SYTextInlineStyle));
            memset(rtInlineEndRun->inlineStyle, 0, sizeof(SYTextInlineStyle));
        }
        
        // For rp
        if (strcmp(name, "rp") == 0) {
        }
    }
    
    // Set base run
    if (rtInlineBeginRun && rtInlineEndRun) {
        rtInlineBeginRun->inlineStyle->baseRun = rbInlineBeginRun;
        rtInlineEndRun->inlineStyle->baseRun = rbInlineEndRun;
    }
}

void _parseTdNode(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYCssContext* cssContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
#if TARGET_OS_IPHONE
        HMXMLNode* node
#elif TARGET_OS_MAC
        NSXMLNode* node
#endif
        )
{
    // Allocate run for td begin
    SYTextRun*  tdBeginRun;
    tdBeginRun = SYTextRunContextAllocateRun(runContext);
    tdBeginRun->type = SYRunTypeTdBegin;
    
    // Allocate run for block and inline begin
    SYTextRun*  blockBeginRun = NULL;
    SYTextRun*  inlineBeginRun = NULL;
    blockBeginRun = SYTextRunContextAllocateRun(runContext);
    blockBeginRun->type = SYRunTypeBlockBegin;
    blockBeginRun->blockStyle = malloc(sizeof(SYTextBlockStyle));
    if (blockStyle) {
        *(blockBeginRun->blockStyle) = *blockStyle;
    }
    
    inlineBeginRun = SYTextRunContextAllocateRun(runContext);
    inlineBeginRun->type = SYRunTypeInlineBegin;
    inlineBeginRun->inlineStyle = malloc(sizeof(SYTextInlineStyle));
    if (inlineStyle) {
        *(inlineBeginRun->inlineStyle) = *inlineStyle;
        if (inlineBeginRun->inlineStyle->linkUrl) {
            CFRetain((__bridge CFTypeRef)inlineBeginRun->inlineStyle->linkUrl);
        }
    }
    else {
        memset(inlineBeginRun->inlineStyle, 0, sizeof(SYTextInlineStyle));
        //inlineBeginRun->inlineStyle->linkUrl = nil;
    }
    inlineBeginRun->blockStyle = blockBeginRun->blockStyle;
    
    blockBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    tdBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    tdBeginRun->blockStyle = inlineBeginRun->blockStyle;
    
    // Select CSS style from cache
    SYTextInlineStyle*  inl;
    SYTextBlockStyle*   blk;
    inl = tdBeginRun->inlineStyle;
    blk = tdBeginRun->blockStyle;
    if (![parser.css cachedInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode]) {
        // Select CSS style
        SYCssContextSelectStyle(
                cssContext, node, parser.writingMode, inl, blk);
        
        // Cache CSS style
        [parser.css cacheInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode];
    }
    
    // Get child node
#if TARGET_OS_IPHONE
    for (HMXMLNode* childNode in [node children])
#elif TARGET_OS_MAC
    for (NSXMLNode* childNode in [node children])
#endif
    {
        // Parse node
        _parseNode(
                parser, runContext, cssContext, 
                tdBeginRun->inlineStyle, tdBeginRun->blockStyle, 
                childNode);
    }
    
    // Allocate run for block and inline end
    SYTextRun*  blockEndRun = NULL;
    SYTextRun*  inlineEndRun = NULL;
    inlineEndRun = SYTextRunContextAllocateRun(runContext);
    inlineEndRun->type = SYRunTypeInlineEnd;
    inlineEndRun->inlineStyle = inlineBeginRun->inlineStyle;
    inlineEndRun->blockStyle = inlineBeginRun->blockStyle;
    
    blockEndRun = SYTextRunContextAllocateRun(runContext);
    blockEndRun->type = SYRunTypeBlockEnd;
    blockEndRun->blockStyle = blockBeginRun->blockStyle;
    blockEndRun->inlineStyle = inlineEndRun->inlineStyle;
    
    // Allocate run for td end
    SYTextRun*  tdEndRun;
    tdEndRun = SYTextRunContextAllocateRun(runContext);
    tdEndRun->type = SYRunTypeTdEnd;
    tdEndRun->inlineStyle = tdBeginRun->inlineStyle;
    tdEndRun->blockStyle = tdBeginRun->blockStyle;
}

void _parseTrNode(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYCssContext* cssContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
#if TARGET_OS_IPHONE
        HMXMLNode* node
#elif TARGET_OS_MAC
        NSXMLNode* node
#endif
        )
{
    // Allocate run for tr begin
    SYTextRun*  trBeginRun;
    trBeginRun = SYTextRunContextAllocateRun(runContext);
    trBeginRun->type = SYRunTypeTrBegin;
    // Allocate run for block and inline begin
    SYTextRun*  blockBeginRun = NULL;
    SYTextRun*  inlineBeginRun = NULL;
    blockBeginRun = SYTextRunContextAllocateRun(runContext);
    blockBeginRun->type = SYRunTypeBlockBegin;
    blockBeginRun->blockStyle = malloc(sizeof(SYTextBlockStyle));
    if (blockStyle) {
        *(blockBeginRun->blockStyle) = *blockStyle;
    }
    
    inlineBeginRun = SYTextRunContextAllocateRun(runContext);
    inlineBeginRun->type = SYRunTypeInlineBegin;
    inlineBeginRun->inlineStyle = malloc(sizeof(SYTextInlineStyle));
    if (inlineStyle) {
        *(inlineBeginRun->inlineStyle) = *inlineStyle;
        if (inlineBeginRun->inlineStyle->linkUrl) {
            CFRetain((__bridge CFTypeRef)inlineBeginRun->inlineStyle->linkUrl);
        }
    }
    else {
        memset(inlineBeginRun->inlineStyle, 0, sizeof(SYTextInlineStyle));
        //inlineBeginRun->inlineStyle->linkUrl = nil;
    }
    inlineBeginRun->blockStyle = blockBeginRun->blockStyle;
    
    blockBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    trBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    trBeginRun->blockStyle = inlineBeginRun->blockStyle;
    
    // Select CSS style from cache
    SYTextInlineStyle*  inl;
    SYTextBlockStyle*   blk;
    inl = trBeginRun->inlineStyle;
    blk = trBeginRun->blockStyle;
    if (![parser.css cachedInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode]) {
        // Select CSS style
        SYCssContextSelectStyle(
                cssContext, node, parser.writingMode, inl, blk);
        
        // Cache CSS style
        [parser.css cacheInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode];
    }
    
    // Get child node
#if TARGET_OS_IPHONE
    for (HMXMLNode* childNode in [node children])
#elif TARGET_OS_MAC
    for (NSXMLNode* childNode in [node children])
#endif
    {
        // Get node name
        const char*     name;
        name = [[childNode name] cStringUsingEncoding:NSASCIIStringEncoding];
        if (!name) {
            return;
        }
        
        // For td
        if (strcmp(name, "td") == 0) {
            // Parse td node
            _parseTdNode(
                    parser, runContext, cssContext, 
                    trBeginRun->inlineStyle, trBeginRun->blockStyle, 
                    childNode);
        }
    }
    
    // Allocate run for block and inline end
    SYTextRun*  blockEndRun = NULL;
    SYTextRun*  inlineEndRun = NULL;
    inlineEndRun = SYTextRunContextAllocateRun(runContext);
    inlineEndRun->type = SYRunTypeInlineEnd;
    inlineEndRun->inlineStyle = inlineBeginRun->inlineStyle;
    inlineEndRun->blockStyle = inlineBeginRun->blockStyle;
    
    blockEndRun = SYTextRunContextAllocateRun(runContext);
    blockEndRun->type = SYRunTypeBlockEnd;
    blockEndRun->blockStyle = blockBeginRun->blockStyle;
    blockEndRun->inlineStyle = inlineEndRun->inlineStyle;
    
    // Allocate run for tr end
    SYTextRun*  trEndRun;
    trEndRun = SYTextRunContextAllocateRun(runContext);
    trEndRun->type = SYRunTypeTrEnd;
    trEndRun->inlineStyle = trBeginRun->inlineStyle;
    trEndRun->blockStyle = trBeginRun->blockStyle;
}

void _parseTableNode(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYCssContext* cssContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
#if TARGET_OS_IPHONE
        HMXMLNode* node
#elif TARGET_OS_MAC
        NSXMLNode* node
#endif
        )
{
    // Get table attributes
    int cellPadding;
    int cellSpacing;
#if 1
    cellPadding = 4.0f;
    cellSpacing = 1.0f;
#else
    cellPadding = [[(HMXMLElement*)node attributeForName:@"cellpadding"] intValue];
    cellSpacing = [[(HMXMLElement*)node attributeForName:@"cellspacing"] intValue];
#endif
    
    // Allocate run for table begin
    SYTextRun*  tableBeginRun;
    tableBeginRun = SYTextRunContextAllocateRun(runContext);
    tableBeginRun->type = SYRunTypeTableBegin;
    
    // Allocate run for block and inline begin
    SYTextRun*  blockBeginRun = NULL;
    SYTextRun*  inlineBeginRun = NULL;
    blockBeginRun = SYTextRunContextAllocateRun(runContext);
    blockBeginRun->type = SYRunTypeBlockBegin;
    blockBeginRun->blockStyle = malloc(sizeof(SYTextBlockStyle));
    if (blockStyle) {
        *(blockBeginRun->blockStyle) = *blockStyle;
    }
    
    inlineBeginRun = SYTextRunContextAllocateRun(runContext);
    inlineBeginRun->type = SYRunTypeInlineBegin;
    inlineBeginRun->inlineStyle = malloc(sizeof(SYTextInlineStyle));
    if (inlineStyle) {
        *(inlineBeginRun->inlineStyle) = *inlineStyle;
        if (inlineBeginRun->inlineStyle->linkUrl) {
            CFRetain((__bridge CFTypeRef)inlineBeginRun->inlineStyle->linkUrl);
        }
    }
    else {
        memset(inlineBeginRun->inlineStyle, 0, sizeof(SYTextInlineStyle));
        //inlineBeginRun->inlineStyle->linkUrl = nil;
    }
    inlineBeginRun->blockStyle = blockBeginRun->blockStyle;
    
    blockBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    tableBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    tableBeginRun->blockStyle = inlineBeginRun->blockStyle;
    tableBeginRun->blockStyle->tableCellPadding = cellPadding;
    tableBeginRun->blockStyle->tableCellSpacing = cellSpacing;
    
    // Select CSS style from cache
    SYTextInlineStyle*  inl;
    SYTextBlockStyle*   blk;
    inl = tableBeginRun->inlineStyle;
    blk = tableBeginRun->blockStyle;
    if (![parser.css cachedInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode]) {
        // Select CSS style
        SYCssContextSelectStyle(
                cssContext, node, parser.writingMode, inl, blk);
        
        // Cache CSS style
        [parser.css cacheInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode];
    }
    
    // Get child node
#if TARGET_OS_IPHONE
    for (HMXMLNode* childNode in [node children])
#elif TARGET_OS_MAC
    for (NSXMLNode* childNode in [node children])
#endif
    {
        // Get node name
        const char*     name;
        name = [[childNode name] cStringUsingEncoding:NSASCIIStringEncoding];
        if (!name) {
            return;
        }
        
        // For tr
        if (strcmp(name, "tr") == 0) {
            // Parse tr node
            _parseTrNode(parser, runContext, cssContext, inl, blk, childNode);
        }
    }
    
    // Allocate run for block and inline end
    SYTextRun*  blockEndRun = NULL;
    SYTextRun*  inlineEndRun = NULL;
    inlineEndRun = SYTextRunContextAllocateRun(runContext);
    inlineEndRun->type = SYRunTypeInlineEnd;
    inlineEndRun->inlineStyle = inlineBeginRun->inlineStyle;
    inlineEndRun->blockStyle = inlineBeginRun->blockStyle;
    
    blockEndRun = SYTextRunContextAllocateRun(runContext);
    blockEndRun->type = SYRunTypeBlockEnd;
    blockEndRun->blockStyle = blockBeginRun->blockStyle;
    blockEndRun->inlineStyle = inlineEndRun->inlineStyle;
    
    // Allocate run for table end
    SYTextRun*  tableEndRun;
    tableEndRun = SYTextRunContextAllocateRun(runContext);
    tableEndRun->type = SYRunTypeTableEnd;
    tableEndRun->inlineStyle = tableBeginRun->inlineStyle;
    tableEndRun->blockStyle = tableBeginRun->blockStyle;
}

void _parseNode(
        SYTextParser* parser, 
        SYTextRunContext* runContext, 
        SYCssContext* cssContext, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle, 
#if TARGET_OS_IPHONE
        HMXMLNode* node
#elif TARGET_OS_MAC
        NSXMLNode* node
#endif
        )
{
    // Get kind
#if TARGET_OS_IPHONE
    int             kind;
#elif TARGET_OS_MAC
    NSXMLNodeKind   kind;
#endif
    kind = [node kind];
    
    // For text kind
#if TARGET_OS_IPHONE
    if (kind == HMXMLTextKind)
#elif TARGET_OS_MAC
    if (kind == NSXMLTextKind)
#endif
    {
        // Check run context
        if (runContext->runCount == 0) {
            // Text run requires block begin
            return;
        }
        
        // Get text
        NSString*   text;
        text = [node stringValue];
        
        // Get parent node
#if TARGET_OS_IPHONE
        HMXMLNode*  parentNode;
#elif TARGET_OS_MAC
        NSXMLNode*  parentNode;
#endif
        parentNode = [node parent];
        
        // Create runs
        SYTextRun*      run;
        unsigned int    runLength;
        _createRuns(
                parser, runContext, inlineStyle, blockStyle, 
                SYRunTypeText, text, &run, &runLength);
        
        return;
    }
    
    // Get element name
    NSString*   name;
    name = [node name];
    if (!name) {
        return;
    }
    
    // Get identifier
    NSString*   identifier = nil;
#if TARGET_OS_IPHONE
    if ([node isKindOfClass:[HMXMLElement class]]) {
        identifier = [(HMXMLElement*)node attributeForName:@"id"];
    }
#elif TARGET_OS_MAC
    if ([node isKindOfClass:[NSXMLElement class]]) {
        identifier = [[(NSXMLElement*)node attributeForName:@"id"] stringValue];
    }
#endif
    
    // For br
    if ([name isEqualToString:@"br"]) {
        // For ignore block mode
        if (parser.ignoreBlock) {
            // Just ignore
            return;
        }
        
        // Allocate run for new line
        SYTextRun*  newLineRun;
        newLineRun = SYTextRunContextAllocateRun(runContext);
        newLineRun->type = SYRunTypeNewLine;
        newLineRun->inlineStyle = inlineStyle;
        newLineRun->blockStyle = blockStyle;
        
        return;
    }
    
    // For img
    if ([name isEqualToString:@"img"]) {
        // Parse img node
        _parseImgNode(parser, runContext, cssContext, inlineStyle, blockStyle, node);
        
        return;
    }
    
    // For ruby
    if ([name isEqualToString:@"ruby"]) {
        // Parse ruby node
        _parseRubyNode(parser, runContext, cssContext, inlineStyle, blockStyle, node);
        
        
        return;
    }
    
    // For table
    if ([name isEqualToString:@"table"]) {
        // For ignore block mode
        if (parser.ignoreBlock) {
            // Just ignore
            return;
        }
        
        // Parse table node
        _parseTableNode(parser, runContext, cssContext, inlineStyle, blockStyle, node);
        
        return;
    }
    
    // Decide block or inline element
    static NSSet*   _blockElements = nil;
    static NSSet*   _inlineElements = nil;
    if (!_blockElements) {
        // Create block elements
        _blockElements = [NSSet setWithObjects:
            @"blockquote", 
            @"body", 
            @"div", 
            @"h1", 
            @"h2", 
            @"h3", 
            @"h4", 
            @"h5", 
            @"h6", 
            @"li", 
            @"p", 
            @"pre", 
            @"ul", 
            nil];
        
        // Create inline elements
        _inlineElements = [NSSet setWithObjects:
            @"a", 
            @"b", 
            @"big",
            @"br", 
            @"cite", 
            @"code", 
            @"em", 
            @"font", 
            @"i", 
            @"q", 
            @"s", 
            @"small", 
            @"span", 
            @"strike", 
            @"strong", 
            @"sub", 
            @"sup", 
            @"tt", 
            @"u",
            nil];
    }
    
    // Decide element type
    BOOL    isBlockElement;
    BOOL    isInlineElement;
    isBlockElement = [_blockElements containsObject:name];
    isInlineElement = [_inlineElements containsObject:name];
    
    // Ignore block
    if (parser.ignoreBlock) {
        if (![name isEqualToString:@"body"] && isBlockElement) {
            isBlockElement = NO;
            isInlineElement = YES;
        }
    }
    
#ifdef CACHE_AND_NO_COPY
    // Get cached CSS style
    SYTextInlineStyle*  inl = NULL;
    SYTextBlockStyle*   blk = NULL;
    if (![parser.css cachedInlinStyle:&inl 
            blockStyle:isBlockElement ? &blk : NULL 
            forNode:node])
    {
        // Allocate buffer for style
        inl = malloc(sizeof(SYTextInlineStyle));
        if (inlineStyle) {
            *inl = *inlineStyle;
        }
        else {
            memset(inl, 0, sizeof(SYTextInlineStyle));
        }
        
        if (isBlockElement) {
            blk = malloc(sizeof(SYTextBlockStyle));
            if (blockStyle) {
                *blk = *blockStyle;
            }
            else {
                memset(blk, 0, sizeof(SYTextBlockStyle));
            }
        }
        
        // Select CSS style
        SYCssContextSelectStyle(
                cssContext, 
                node, 
                parser.writingMode, 
                inl, 
                isBlockElement ? blk : NULL);
        
        // Cache CSS style
        [parser.css cacheInlinStyle:inl 
                blockStyle:isBlockElement ? blk : NULL 
                forNode:node];
    }
    else {
    }
    
    // Allocate run for begin
    SYTextRun*  blockBeginRun = NULL;
    SYTextRun*  inlineBeginRun = NULL;
    if (isBlockElement) {
        blockBeginRun = SYTextRunContextAllocateRun(runContext);
        blockBeginRun->type = SYRunTypeBlockBegin;
        blockBeginRun->blockStyle = blk;
        
        inlineBeginRun = SYTextRunContextAllocateRun(runContext);
        inlineBeginRun->type = SYRunTypeInlineBegin;
        inlineBeginRun->inlineStyle = inl;
        
        blockBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    }
    else if (isInlineElement) {
        inlineBeginRun = SYTextRunContextAllocateRun(runContext);
        inlineBeginRun->type = SYRunTypeInlineBegin;
        inlineBeginRun->inlineStyle = inl;
    }
#else
    // Allocate run for begin
    SYTextRun*  blockBeginRun = NULL;
    SYTextRun*  inlineBeginRun = NULL;
    if (isBlockElement) {
        blockBeginRun = SYTextRunContextAllocateRun(runContext);
        blockBeginRun->type = SYRunTypeBlockBegin;
        blockBeginRun->blockStyle = malloc(sizeof(SYTextBlockStyle));
        if (blockStyle) {
            *(blockBeginRun->blockStyle) = *blockStyle;
        }
        
        inlineBeginRun = SYTextRunContextAllocateRun(runContext);
        inlineBeginRun->type = SYRunTypeInlineBegin;
        inlineBeginRun->inlineStyle = malloc(sizeof(SYTextInlineStyle));
        if (inlineStyle) {
            *(inlineBeginRun->inlineStyle) = *inlineStyle;
            if (inlineBeginRun->inlineStyle->linkUrl) {
                CFRetain((__bridge CFTypeRef)inlineBeginRun->inlineStyle->linkUrl);
            }
        }
        else {
            memset(inlineBeginRun->inlineStyle, 0, sizeof(SYTextInlineStyle));
            //inlineBeginRun->inlineStyle->linkUrl = nil;
        }
        
        blockBeginRun->inlineStyle = inlineBeginRun->inlineStyle;
    }
    else if (isInlineElement) {
        inlineBeginRun = SYTextRunContextAllocateRun(runContext);
        inlineBeginRun->type = SYRunTypeInlineBegin;
        inlineBeginRun->inlineStyle = malloc(sizeof(SYTextInlineStyle));
        if (inlineStyle) {
            *(inlineBeginRun->inlineStyle) = *inlineStyle;
            if (inlineBeginRun->inlineStyle->linkUrl) {
                CFRetain((__bridge CFTypeRef)inlineBeginRun->inlineStyle->linkUrl);
            }
        }
        else {
            memset(inlineBeginRun->inlineStyle, 0, sizeof(SYTextInlineStyle));
            //inlineBeginRun->inlineStyle->linkUrl = nil;
        }
    }
    
    // Select CSS style
    if (blockBeginRun || inlineBeginRun) {
        // Select CSS style from cache
        SYTextInlineStyle*  inl;
        SYTextBlockStyle*   blk;
        inl = inlineBeginRun ? inlineBeginRun->inlineStyle : NULL;
        blk = blockBeginRun ? blockBeginRun->blockStyle : NULL;
        if (![parser.css cachedInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode]) {
            // Select CSS style
            SYCssContextSelectStyle(
                    cssContext, 
                    node, 
                    parser.writingMode, 
                    inlineBeginRun ? inlineBeginRun->inlineStyle : NULL, 
                    blockBeginRun ? blockBeginRun->blockStyle : NULL);
            
            // Cache CSS style
            [parser.css cacheInlinStyle:inl blockStyle:blk forNode:node writingMode:parser.writingMode];
        }
    }
#endif
    
    // For a
    if ([name isEqualToString:@"a"]) {
        // Set link
        NSString*   link;
        NSURL*      url;
#if TARGET_OS_IPHONE
        link = [(HMXMLElement*)node attributeForName:@"href"];
#elif TARGET_OS_MAC
        link = [[(NSXMLElement*)node attributeForName:@"href"] stringValue];
#endif
        url = [NSURL URLWithString:link];
        if (url) {
            // Retain URL by CFRetain
            CFRetain((__bridge CFTypeRef)url);
            
            // Set link
            inlineBeginRun->inlineStyle->linkUrl = url;
        }
    }
    
    // For span
    if ([name isEqualToString:@"span"]) {
        // Get type
        NSString*   type;
#if TARGET_OS_IPHONE
        type = [(HMXMLElement*)node attributeForName:@"type"];
#elif TARGET_OS_MAC
        type = [[(NSXMLElement*)node attributeForName:@"type"] stringValue];
#endif
        
        // For 原綴
        if ([type isEqualToString:@"原綴"]) {
            // Set original spelling
            inlineBeginRun->inlineStyle->originalSpelling = YES;
        }
    }
    
    // Get child nodes
    NSArray*    childNodes;
    childNodes = node.children;
    for (int i = 0; i < [childNodes count]; i++) {
        // Get child node
#if TARGET_OS_IPHONE
        HMXMLNode*  childNode;
#elif TARGET_OS_MAC
        NSXMLNode*  childNode;
#endif
        childNode = [childNodes objectAtIndex:i];
        
        // Parse child node
        SYTextInlineStyle*  inlStyle;
        SYTextBlockStyle*   blkStyle;
        inlStyle = inlineStyle;
        if (inlineBeginRun) {
            inlStyle = inlineBeginRun->inlineStyle;
        }
        blkStyle = blockStyle;
        if (blockBeginRun) {
            blkStyle = blockBeginRun->blockStyle;
        }
        _parseNode(parser, runContext, cssContext, inlStyle, blkStyle, childNode);
    }
    
    // Allocate run for end
    SYTextRun*  blockEndRun = NULL;
    SYTextRun*  inlineEndRun = NULL;
    if (isBlockElement) {
        inlineEndRun = SYTextRunContextAllocateRun(runContext);
        inlineEndRun->type = SYRunTypeInlineEnd;
        inlineEndRun->inlineStyle = inlineBeginRun->inlineStyle;
        
        blockEndRun = SYTextRunContextAllocateRun(runContext);
        blockEndRun->type = SYRunTypeBlockEnd;
        blockEndRun->blockStyle = blockBeginRun->blockStyle;
        blockEndRun->inlineStyle = inlineEndRun->inlineStyle;
    }
    else if (isInlineElement) {
        inlineEndRun = SYTextRunContextAllocateRun(runContext);
        inlineEndRun->type = SYRunTypeInlineEnd;
        inlineEndRun->inlineStyle = inlineBeginRun->inlineStyle;
    }
}

@implementation SYTextParser

// Property
@synthesize htmlData = _htmlData;
@synthesize cssData = _cssData;
@synthesize css = _css;
@synthesize baseFontSize = _baseFontSize;
@synthesize numberOfLines = _numberOfLines;
@synthesize writingMode = _writingMode;
@synthesize hangingIndent = _hangingIndent;
@synthesize rowHeightForVertical = _rowHeightForVertical;
@synthesize rowMarginForVertical = _rowMarginForVertical;
@synthesize floatRects = _floatRects;
@synthesize ignoreBlock = _ignoreBlock;
@synthesize runContext = _runContext;

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Initialize instance variables
    _baseFontSize = 17.0f;
    _writingMode = SYStyleWritingModeLrTb;
    
    return self;
}

- (void)dealloc
{
    // Release run context
    if (_runContext) {
        SYTextRunContextRelease(_runContext), _runContext = NULL;
    }
}

//--------------------------------------------------------------//
#pragma mark -- Parse --
//--------------------------------------------------------------//

- (BOOL)parse
{
    NSError*    error;
    
    // Check HTML data
    if (!_htmlData) {
        return YES;
    }
    
    // Parse XHTML
#if TARGET_OS_IPHONE
    HMXMLDocument*  document;
    document = [HMXMLDocument documentWithXMLData:_htmlData error:&error];
#elif TARGET_OS_MAC
    NSXMLDocument*  document;
    document = [[NSXMLDocument alloc] initWithData:_htmlData options:0 error:&error];
#endif
    if (!document) {
        NSLog(@"Failed to create XML document! | html data length=%lu | Error Description:%@", 
                (unsigned long)[_htmlData length], [error localizedDescription]);
        
#ifdef DEBUG_CREATE_XML_DOC
        NSLog(@"[NSThread callStackSymbols] %@", [NSThread callStackSymbols]);
        NSLog(@"_htmlData len=%d", [_htmlData length]);
        
        NSString* debugText;
        debugText = [[NSString alloc] initWithData:_htmlData encoding:NSUTF8StringEncoding];
        NSLog(@"html|len=%d|\"%@\"", [debugText length], debugText);
#endif
        
        return NO;
    }
    
    // Create run context
    if (_runContext) {
        SYTextRunContextRelease(_runContext), _runContext = NULL;
    }
    _runContext = SYTextRunContextCreate();
    
    // Get CSS context
    SYCssContext*   cssContext = NULL;
    BOOL            onThFly = NO;
    if (_css) {
        cssContext = _css.cssContext;
    }
    
    // Create CSS context
    if (!cssContext) {
        cssContext = SYCssContextCreate();
        SYCssContextSetBaseFontSize(cssContext, _baseFontSize);
        SYCssContextAddStylesheetData(cssContext, _cssData);
        
        onThFly = YES;
    }
    
    // Create default block style
    SYTextBlockStyle    blockStyle;
    memset(&blockStyle, 0, sizeof(blockStyle));
    
    // Create default inline style
    SYTextInlineStyle   inlineStyle;
    memset(&inlineStyle, 0, sizeof(inlineStyle));
    inlineStyle.fontSize = _baseFontSize;
    inlineStyle.color.colorAlpha = 1.0f;
    inlineStyle.lineHeight = 1.0;
    
    // Parse root element
    _parseNode(self, _runContext, cssContext, &inlineStyle, &blockStyle, [document rootElement]);
    
    // Relase CSS context
    if (onThFly) {
        SYCssContextRelease(cssContext);
    }
    
    return YES;
}

@end
