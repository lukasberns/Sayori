/*
SYTextRun.h

Author: Makoto Kinoshita

Copyright 2010-2011 HMDT. All rights reserved.
*/

#import <objc/runtime.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "HMXML.h"
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif
#import "SYTextStyle.h"

#define SY_RUN_TEXTBUFFER_MAX   4

enum {
    SYRunTypeText = 0, 
    SYRunTypeBlockBegin = 1, 
    SYRunTypeBlockEnd = 2, 
    SYRunTypeInlineBegin = 3, 
    SYRunTypeInlineEnd = 4, 
    SYRunTypeNewLine = 5, 
    SYRunTypeAnchor = 6, 
    SYRunTypeImage = 7, 
    SYRunTypeRubyBegin = 8, 
    SYRunTypeRubyEnd = 9, 
    SYRunTypeRubyText = 10, 
    SYRunTypeRubyInlineBegin = 11, 
    SYRunTypeRubyInlineEnd = 12, 
    SYRunTypeTableBegin = 13, 
    SYRunTypeTableEnd = 14, 
    SYRunTypeTrBegin = 15, 
    SYRunTypeTrEnd = 16, 
    SYRunTypeTdBegin = 17, 
    SYRunTypeTdEnd = 18, 
};

enum {
    SYPunctuationWhole = 0, 
    SYPunctuationFirstHalf, 
    SYPunctuationSecondHalf, 
    SYPunctuationQuater, 
};

typedef struct {
    unsigned int        runId;
    unsigned char       type;
    
    unsigned char       textLength;
    unichar*            text;
    unichar             textBuffer[SY_RUN_TEXTBUFFER_MAX];
    unsigned char       glyphLength;
    CGGlyph*            glyphs;
    CGGlyph             glyphBuffer[SY_RUN_TEXTBUFFER_MAX];
    CGSize*             advances;
    CGSize              advanceBuffer[SY_RUN_TEXTBUFFER_MAX];
    CGRect              rect;
    unsigned char       punctuation     :2;
    unsigned char       numberOfColumnBreaks :6; // 6bit: 0 -> 31
    BOOL*               rotateFlags;
    
    SYTextInlineStyle*  inlineStyle;
    SYTextBlockStyle*   blockStyle;
    
    void*               prevRun;
    void*               nextRun;
} SYTextRun;

#define SY_RUNPOOL_MAX  512 //8192
#define SY_RUNSTACK_MAX 256

typedef struct {
    SYTextRun   runs[SY_RUNPOOL_MAX];
    void*       prevPool;
    void*       nextPool;
} SYTextRunPool;

typedef struct {
    unsigned int    runCount;
    SYTextRunPool*  runPool;
    SYTextRunPool*  currentRunPool;
    SYTextRun*      currentRun;
    unsigned int    currentIndex;
} SYTextRunContext;

typedef struct {
    SYTextRun*  runs[SY_RUNSTACK_MAX];
    SYTextRun** currentRun;
} SYTextRunStack;

// Functions
SYTextRunContext* SYTextRunContextCreate();
void SYTextRunContextRelease(
        SYTextRunContext* runContext);
SYTextRun* SYTextRunContextAllocateRun(
        SYTextRunContext* runContext);
SYTextRun* SYTextRunContextPrevRun(
        SYTextRunContext* runContext, 
        SYTextRun* run);
SYTextRun* SYTextRunContextNextRun(
        SYTextRunContext* runContext, 
        SYTextRun* run);
SYTextRun* SYTextRunContextPrevTextRun(// Prev text run in the same block
        SYTextRunContext* runContext,
        SYTextRun* run);
SYTextRun* SYTextRunContextNextTextRun(// Next text run in the same bolck
        SYTextRunContext* runContext,
        SYTextRun* run);
void SYTextRunContextBeginIteration(
        SYTextRunContext* runContext);
SYTextRun* SYTextRunContextIteratePrev(
        SYTextRunContext* runContext);
SYTextRun* SYTextRunContextIterateNext(
        SYTextRunContext* runContext);
NSString* SYTextRunStringWithRun(
        SYTextRun* run);
NSString* SYTextRunContextStringBetweenRun(
        SYTextRunContext* runContext, 
        SYTextRun* beginRun, 
        SYTextRun* endRun);

SYTextRunStack* SYTextRunStackCreate();
void SYTextRunStackRelease(
        SYTextRunStack* runStack);
void SYTextRunStackPush(
        SYTextRunStack* runStack, 
        SYTextRun* run);
SYTextRun* SYTextRunStackPop(
        SYTextRunStack* runStack);
SYTextRun* SYTextRunStackTop(
        SYTextRunStack* runStack);
