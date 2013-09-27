/*
SYLabel.m

Author: Makoto Kinoshita

Copyright 2013 HMDT. All rights reserved.
*/

#import "SYFontManager.h"
#import "SYLabel.h"
#import "SYTextLayout.h"
#import "SYTextParser.h"
#import "SYTextRun.h"

int  SYLabelSelectionView = 1024;

enum {
    _borderLeft, 
    _borderTop, 
    _borderRight, 
    _borderBottom, 
};

#if TARGET_OS_IPHONE
@interface SYLabelInnerView : UIView
#elif TARGET_OS_MAC
@interface SYLabelInnerView : NSView
#endif

// Property
@property (nonatomic,weak) SYLabel* label;

@end

@implementation SYLabelInnerView
{
}

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    // Configure itself
#if TARGET_OS_IPHONE
    self.backgroundColor = [UIColor clearColor];
#endif
    
    return self;
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (BOOL)isFlipped
{
    return YES;
}

#if TARGET_OS_IPHONE
- (void)layoutSubviews
{
    // Invoke super
    [super layoutSubviews];
	
    // Set needs display
    [self setNeedsDisplay];
}
#endif

- (BOOL)_exceededNextRunWithRunContext:(SYTextRunContext*)runContext 
        run:(SYTextRun*)run 
        inlineStyle:(SYTextInlineStyle*)inlineStyle 
        bounds:(CGRect)bounds
{
    // Check next run exceeds bounds
    SYTextRun*  nextRun;
    BOOL        exceeded = NO;
    nextRun = SYTextRunContextNextRun(runContext, run);
    while (nextRun) {
        // For block end
        if (nextRun->type == SYRunTypeBlockEnd) {
            break;
        }
        
        // For text run
        if (nextRun->type == SYRunTypeText) {
            // For empty rect
            if (CGRectGetMinX(nextRun->rect) == 0 && CGRectGetMinY(nextRun->rect) == 0 && 
                CGRectGetWidth(nextRun->rect) == 0 && CGRectGetHeight(nextRun->rect) == 0)
            {
                exceeded = YES;
            }
            else if (CGRectGetWidth(nextRun->rect) == 0 || CGRectGetHeight(nextRun->rect) == 0)
            {
                exceeded = NO;
            }
            // For not empty
            else {
                // Check with dirty rect
                if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                    exceeded = CGRectGetMaxY(nextRun->rect) > CGRectGetMaxY(bounds);
                }
                else if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                    exceeded = CGRectGetMinX(nextRun->rect) < CGRectGetMinX(bounds);
                }
            }
            
            break;
        }
        
        // Get next run
        nextRun = SYTextRunContextNextRun(runContext, nextRun);
    }
    
    return exceeded;
}

- (void)_drawBlockBorderWithBorder:(SYTextBorder*)border 
        runRect:(CGRect)runRect 
        blockStyle:(SYTextBlockStyle*)blockStyle 
        location:(int)location
        context:(CGContextRef)context
{
    // Set line width
    CGContextSetLineWidth(context, border->width);
    
    // Set line pattern
    if (border->style == SYStyleBorderStyleDotted) {
        CGFloat lengths[2] = { border->width, border->width };
        CGContextSetLineDash(context, 0, lengths, 2);
    }
    else {
        CGContextSetLineDash(context, 0, NULL, 0);
    }
    
    // Set border color
    SYTextColor*    textColor;
#if TARGET_OS_IPHONE
    UIColor*        color;
#elif TARGET_OS_MAC
    NSColor*        color;
#endif
    textColor = &border->color;
    color = SYStyleColor(textColor);
    [color set];
    
    // Decide points
    float   extra;
    CGPoint points[2];
    extra = border->width * 0.5f;
    switch (location) {
    // For left
    case _borderLeft: {
        points[0].x = CGRectGetMinX(runRect) + extra;
        points[0].y = CGRectGetMinY(runRect);// - extra;
        points[1].x = CGRectGetMinX(runRect) + extra;
        points[1].y = CGRectGetMaxY(runRect);// + extra;
        
        break;
    }
    // For top
    case _borderTop: {
        points[0].x = CGRectGetMinX(runRect);// - extra;
        points[0].y = CGRectGetMinY(runRect) + extra;
        points[1].x = CGRectGetMaxX(runRect);// + extra;
        points[1].y = CGRectGetMinY(runRect) + extra;
        
        break;
    }
    // For right
    case _borderRight: {
        points[0].x = CGRectGetMaxX(runRect) - extra;
        points[0].y = CGRectGetMinY(runRect);// - extra;
        points[1].x = CGRectGetMaxX(runRect) - extra;
        points[1].y = CGRectGetMaxY(runRect);// + extra;
        
        break;
    }
    // For bottom
    case _borderBottom: {
        points[0].x = CGRectGetMinX(runRect);// - extra;
        points[0].y = CGRectGetMaxY(runRect) - extra;
        points[1].x = CGRectGetMaxX(runRect);// + extra;
        points[1].y = CGRectGetMaxY(runRect) - extra;
        
        break;
    }
    }
    
    // Draw line
    CGContextStrokeLineSegments(context, points, 2);
}

- (void)_drawBlockBorderWithRun:(SYTextRun*)run 
        context:(CGContextRef)context
{
    // Get block style
    SYTextBlockStyle*   blockStyle;
    blockStyle = run->blockStyle;
    
    // For left border
    if (blockStyle->borderLeft.width > 0) {
        [self _drawBlockBorderWithBorder:&blockStyle->borderLeft 
                runRect:run->rect 
                blockStyle:blockStyle 
                location:_borderLeft 
                context:context];
    }
    // For top border
    if (blockStyle->borderTop.width > 0) {
        [self _drawBlockBorderWithBorder:&blockStyle->borderTop 
                runRect:run->rect 
                blockStyle:blockStyle 
                location:_borderTop 
                context:context];
    }
    // For right border
    if (blockStyle->borderRight.width > 0) {
        [self _drawBlockBorderWithBorder:&blockStyle->borderRight 
                runRect:run->rect 
                blockStyle:blockStyle 
                location:_borderRight 
                context:context];
    }
    // For bottom border
    if (blockStyle->borderBottom.width > 0) {
        [self _drawBlockBorderWithBorder:&blockStyle->borderBottom 
                runRect:run->rect 
                blockStyle:blockStyle 
                location:_borderBottom 
                context:context];
    }
}

- (void)_drawInlineBorderWithBorder:(SYTextBorder*)border 
        runRects:(NSArray*)runRects 
        inlineStyle:(SYTextInlineStyle*)inlineStyle 
        location:(int)location
        context:(CGContextRef)context
{
    // Set line width
    CGContextSetLineWidth(context, border->width);
    
    // Set line pattern
    if (border->style == SYStyleBorderStyleDotted) {
        CGFloat lengths[2] = { border->width, border->width };
        CGContextSetLineDash(context, 0, lengths, 2);
    }
    else {
        CGContextSetLineDash(context, 0, NULL, 0);
    }
    
    // Set border color
    SYTextColor*    textColor;
#if TARGET_OS_IPHONE
    UIColor*        color;
#elif TARGET_OS_MAC
    NSColor*        color;
#endif
    textColor = &border->color;
    color = SYStyleColor(textColor);
    [color set];
    
    // Draw border
    CGPoint points[2];
    points[0].x = MAXFLOAT;
    points[0].y = MAXFLOAT;
    for (NSValue* rectValue in runRects) {
        // Get rect
        CGRect  rect;
#if TARGET_OS_IPHONE
        rect = [rectValue CGRectValue];
#elif TARGET_OS_MAC
        rect = NSRectToCGRect([rectValue rectValue]);
#endif
        
        // For left
        if (location == _borderLeft) {
            // Not implemented yet
        }
        
        // For top
        else if (location == _borderTop) {
            // For max
            if (points[0].x == MAXFLOAT) {
                // Set points
                points[0].x = roundf(CGRectGetMinX(rect));
                points[0].y = roundf(CGRectGetMinY(rect)) - border->width * 0.5f;
                points[1].x = roundf(CGRectGetMaxX(rect));
                points[1].y = roundf(CGRectGetMinY(rect)) - border->width * 0.5f;
                
                // For not last
                if (rectValue != [runRects lastObject]) {
                    continue;
                }
            }
            
            // For same Y
            if (points[0].y == roundf(CGRectGetMinY(rect)) - border->width * 0.5f) {
                // Set end point
                points[1].x = roundf(CGRectGetMaxX(rect));
                points[1].y = roundf(CGRectGetMinY(rect)) - border->width * 0.5f;
                
                // For not last
                if (rectValue != [runRects lastObject]) {
                    continue;
                }
            }
            
            // Draw line
            CGContextStrokeLineSegments(context, points, 2);
            
            // Set begin point
            points[0].x = roundf(CGRectGetMinX(rect));
            points[0].y = roundf(CGRectGetMinY(rect)) - border->width * 0.5f;
        }
        
        // For right
        else if (location == _borderRight) {
            // Not implemented yet
        }
        
        // For bottom
        else if (location == _borderBottom) {
            // For max
            if (points[0].x == MAXFLOAT) {
                // Set points
                if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                    points[0].x = roundf(CGRectGetMinX(rect));
                    points[0].y = roundf(CGRectGetMaxY(rect)) - border->width * 0.5f;
                    points[1].x = roundf(CGRectGetMaxX(rect));
                    points[1].y = roundf(CGRectGetMaxY(rect)) - border->width * 0.5f;
                }
                else if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                    points[0].x = roundf(CGRectGetMinX(rect)) + border->width * 0.5f;
                    points[0].y = roundf(CGRectGetMinY(rect));
                    points[1].x = roundf(CGRectGetMinX(rect)) + border->width * 0.5f;
                    points[1].y = roundf(CGRectGetMaxY(rect));
                }
                
                // For not last
                if (rectValue != [runRects lastObject]) {
                    continue;
                }
            }
            
            BOOL    sameLine = NO;
            
            // For same Y
            if (inlineStyle->writingMode == SYStyleWritingModeLrTb && 
                points[0].y == roundf(CGRectGetMaxY(rect)) - border->width * 0.5f)
            {
                // Set end point
                points[1].x = roundf(CGRectGetMaxX(rect));
                points[1].y = roundf(CGRectGetMaxY(rect)) - border->width * 0.5f;
                
                // For not last
                if (rectValue != [runRects lastObject]) {
                    continue;
                }
                
                // Set flag
                sameLine = YES;
            }
            // For same X
            if (inlineStyle->writingMode == SYStyleWritingModeTbRl && 
                points[0].x == roundf(CGRectGetMinX(rect)) + border->width * 0.5f)
            {
                // Set end point
                points[1].x = roundf(CGRectGetMinX(rect)) + border->width * 0.5f;
                points[1].y = roundf(CGRectGetMaxY(rect));
                
                // For not last
                if (rectValue != [runRects lastObject]) {
                    continue;
                }
                
                // Set flag
                sameLine = YES;
            }
            
            // Draw line
            CGContextStrokeLineSegments(context, points, 2);
            
            // Set next points
            if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                points[0].x = roundf(CGRectGetMinX(rect));
                points[0].y = roundf(CGRectGetMaxY(rect)) - border->width * 0.5f;
                
                // For not same line
                if (!sameLine) {
                    // For last
                    if (rectValue == [runRects lastObject]) {
                        // Draw line
                        points[1].x = roundf(CGRectGetMaxX(rect));
                        points[1].y = roundf(CGRectGetMaxY(rect)) - border->width * 0.5f;
                        
                        CGContextStrokeLineSegments(context, points, 2);
                    }
                }
            }
            else if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                points[0].x = roundf(CGRectGetMinX(rect)) + border->width * 0.5f;
                points[0].y = roundf(CGRectGetMinY(rect));
                
                // For not same line
                if (!sameLine) {
                    // For last
                    if (rectValue == [runRects lastObject]) {
                        // Draw line
                        points[1].x = roundf(CGRectGetMinX(rect)) + border->width * 0.5f;
                        points[1].y = roundf(CGRectGetMaxY(rect));
                        
                        CGContextStrokeLineSegments(context, points, 2);
                    }
                }
            }
        }
    }
}

- (void)_drawInlineBorderBetweenBeginRun:(SYTextRun*)beginRun endRun:(SYTextRun*)endRun 
        context:(CGContextRef)context
{
    // Get inline style
    SYTextInlineStyle*  inlineStyle;
    inlineStyle = beginRun->inlineStyle;
    
    // Get run rects
    NSArray*    runRects;
    runRects = [_label runRectsBetweenBeginRun:beginRun endRun:endRun containsLineHeight:NO];
    
    // For left border
    if (inlineStyle->borderLeft.width > 0) {
        [self _drawInlineBorderWithBorder:&inlineStyle->borderLeft 
                runRects:runRects inlineStyle:inlineStyle location:_borderLeft context:context];
    }
    // For top border
    if (inlineStyle->borderTop.width > 0) {
        [self _drawInlineBorderWithBorder:&inlineStyle->borderTop 
                runRects:runRects inlineStyle:inlineStyle location:_borderTop context:context];
    }
    // For right border
    if (inlineStyle->borderTop.width > 0) {
        [self _drawInlineBorderWithBorder:&inlineStyle->borderRight 
                runRects:runRects inlineStyle:inlineStyle location:_borderRight context:context];
    }
    // For bottom border
    if (inlineStyle->borderBottom.width > 0) {
        [self _drawInlineBorderWithBorder:&inlineStyle->borderBottom 
                runRects:runRects inlineStyle:inlineStyle location:_borderBottom context:context];
    }
}

- (void)drawRect:(CGRect)dirtyRect
{
#ifdef DEBUG
//NSLog(@"%s, %@, dirtyRect %@", __PRETTY_FUNCTION__, _label.html, NSStringFromCGRect(dirtyRect));
#endif
    
    // Get run context
    SYTextRunContext*   runContext;
    runContext = _label.runContext;
    if (!runContext) {
        return;
    }
    
    // Get CG context
    CGContextRef    context;
#if TARGET_OS_IPHONE
    context = UIGraphicsGetCurrentContext();
#elif TARGET_OS_MAC
    context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    if (!context) {
        return;
    }
    
    // Get bounds
    CGRect  bounds;
    bounds = self.bounds;
    
    // Reset text matrix
    CGContextSetTextMatrix(
            context, CGAffineTransformScale(CGAffineTransformIdentity, 1, -1));
    
    // Create run stack
    SYTextRunStack* inlineRunStack;
    inlineRunStack = SYTextRunStackCreate();
    
    // Create font manager
    SYFontManager*  fontManager;
    fontManager = [[SYFontManager alloc] init];
    
    // Draw runs
    SYTextRun*  run;
    BOOL        needsToUpdateFont = NO;
    CGFontRef   cgFont = NULL;
    CTFontRef   ctFont = NULL;
    SYTextRunContextBeginIteration(runContext);
    run = SYTextRunContextIterateNext(runContext);
    while (run) {
//NSLog(@"runId %d, type %d, text %@, runRect %@", run->runId, run->type, SYTextRunStringWithRun(run), NSStringFromCGRect(run->rect));
        // For block begin
        if (run->type == SYRunTypeBlockBegin) {
            // For not clear background color
            if (run->blockStyle->backgroundColor.colorAlpha > 0) {
                // Get background color
#if TARGET_OS_IPHONE
                UIColor*    backgroundColor;
#elif TARGET_OS_MAC
                NSColor*    backgroundColor;
#endif
                backgroundColor = SYStyleColor(&run->blockStyle->backgroundColor);
                [backgroundColor set];
                
                // Fill background
#if TARGET_OS_IPHONE
                UIRectFill(run->rect);
#elif TARGET_OS_MAC
                NSRectFill(NSRectFromCGRect(run->rect));
#endif
            }
            
            // Draw border
            [self _drawBlockBorderWithRun:run context:context];
            
#if 0
// Set border color
#if TARGET_OS_IPHONE
//[[UIColor blueColor] set];
#elif TARGET_OS_MAC
[[NSColor blueColor] set];
#endif
            
// Draw border
#if TARGET_OS_IPHONE
//UIRectFrame(CGRectIntegral(run->rect));
//UIRectFrame(run->rect);
#elif TARGET_OS_MAC
NSFrameRect(NSIntegralRect(run->rect));
#endif
#endif
            
            // Go next run
            goto nextRun;
        }
        
        // For inline begin
        else if (run->type == SYRunTypeInlineBegin || run->type == SYRunTypeRubyInlineBegin) {
            // Push inline begin run
            SYTextRunStackPush(inlineRunStack, run);
            
#if 1
            // Set flag
            needsToUpdateFont = YES;
#else
            // Compare with old one
            if (!inlineStyle || 
                inlineStyle->fontSize != run->inlineStyle->fontSize || 
                inlineStyle->fontFamily != run->inlineStyle->fontFamily || 
                inlineStyle->fontWeight != run->inlineStyle->fontWeight)
            {
                // Set flag
                needsToUpdateFont = YES;
            }
#endif
            
            // Go next run
            goto nextRun;
        }
        
        // For inline end
        else if (run->type == SYRunTypeInlineEnd || run->type == SYRunTypeRubyInlineEnd) {
            // Pop inline begin run
            SYTextRun*  poppedRun;
            poppedRun = SYTextRunStackPop(inlineRunStack);
            
#if 1
            // Set flag
            needsToUpdateFont = YES;
#else
            // Compare with old one
            if (!inlineStyle || !poppedInlineStyle || 
                inlineStyle->fontSize != poppedInlineStyle->fontSize || 
                inlineStyle->fontFamily != poppedInlineStyle->fontFamily || 
                inlineStyle->fontWeight != poppedInlineStyle->fontWeight)
            {
                // Set flag
                needsToUpdateFont = YES;
            }
#endif
            
            // Get inline style
            SYTextInlineStyle*  inlineStyle;
            inlineStyle = poppedRun->inlineStyle;
            
            // Draw border
            if (inlineStyle->borderLeft.width > 0 || 
                inlineStyle->borderTop.width > 0 || 
                inlineStyle->borderRight.width > 0 || 
                inlineStyle->borderBottom.width > 0)
            {
                // Find begin and end text run
                SYTextRun*  endRun = run;
                SYTextRun*  tmpRun = NULL;
                SYTextRun*  tmpPrevRun = NULL;
                BOOL        done;
                tmpRun = poppedRun;
                done = NO;
                while (tmpRun) {
                    // For exceeded
                    if ([self _exceededNextRunWithRunContext:runContext 
                            run:tmpRun inlineStyle:inlineStyle bounds:bounds])
                    {
                        // Set end run
                        if (tmpPrevRun) {
                            endRun = tmpPrevRun;
                            
                            break;
                        }
                    }
                    
                    // Get next run
                    if (done) {
                        break;
                    }
                    tmpPrevRun = tmpRun;
                    tmpRun = SYTextRunContextNextRun(runContext, tmpRun);
                    done = tmpRun->runId >= run->runId;
                }
                
                // Draw border
                if (endRun->runId > poppedRun->runId) {
                    [self _drawInlineBorderBetweenBeginRun:poppedRun endRun:endRun context:context];
                }
            }
            
            // Go next run
            goto nextRun;
        }
        
        // For image
        else if (run->type == SYRunTypeImage) {
// Draw image bounds
#if TARGET_OS_IPHONE
//UIRectFrame(CGRectIntegral(run->rect));
#elif TARGET_OS_MAC
//NSFrameRect(CGRectIntegral(run->rect));
#endif
            
            // Go next run
            goto nextRun;
        }
        
        // For other
        else if (run->type != SYRunTypeText && run->type != SYRunTypeRubyText) {
            // Go next run
            goto nextRun;
        }
        
        // Get current inline style
        SYTextInlineStyle*  inlineStyle;
        inlineStyle = SYTextRunStackTop(inlineRunStack)->inlineStyle;
        
        // Check run rect
        CGRect  rect;
        rect = run->rect;
        
        if (CGRectGetWidth(rect) == 0 || CGRectGetHeight(rect) == 0) {
            goto nextRun;
        }
        
        if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
            if (CGRectGetMaxY(rect) < CGRectGetMinY(bounds)) {
                // Go next run
                goto nextRun;
            }
            if (CGRectGetMaxY(rect) > CGRectGetMaxY(bounds)) {
                break;
            }
        }
        else if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
            if (CGRectGetMaxX(rect) > CGRectGetMaxX(bounds)) {
                // Go next run
                goto nextRun;
            }
            if (CGRectGetMinX(rect) < CGRectGetMinX(bounds)) {
                break;
            }
        }
        
        // Get CGFont
        if (needsToUpdateFont) {
            // Get CGFont
            cgFont = [fontManager cgFontWithStyle:inlineStyle character:*(run->text)];
            
            // Set font and font size
            CGContextSetFont(context, cgFont);
            CGContextSetFontSize(context, inlineStyle->fontSize);
            
            // Get CTFont for outline
            if (_label.outlineWidth > 0) {
                ctFont = [fontManager ctFontWithStyle:inlineStyle character:*(run->text)];
            }
            
            // Set text color
#if TARGET_OS_IPHONE
            UIColor*    color;
            color = [UIColor colorWithRed:inlineStyle->color.colorRed / 255.0f 
                    green:inlineStyle->color.colorGreen / 255.0f 
                    blue:inlineStyle->color.colorBlue / 255.0f
                    alpha:inlineStyle->color.colorAlpha / 255.0f];
            [color set];
#elif TARGET_OS_MAC
            [[NSColor blackColor] set];
#endif
            
            // Clear flag
            needsToUpdateFont = NO;
        }
        
        // Decide x and y
        float   x, y;
        x = CGRectGetMinX(rect);
        if (run->punctuation != SYPunctuationWhole) {
            // For horizontal
            if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                if (run->punctuation == SYPunctuationSecondHalf) {
                    x -= CGRectGetWidth(rect) * 1.0f;
                }
                else if (run->punctuation == SYPunctuationQuater) {
                    x -= CGRectGetWidth(rect) * 0.50f;
                }
            }
        }
        y = CGRectGetMaxY(rect) - inlineStyle->descent;
        if (run->punctuation != SYPunctuationWhole) {
            // For vertical
            if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                if (run->punctuation == SYPunctuationFirstHalf) {
                    y += CGRectGetHeight(rect) * 1.0f;
                }
                else if (run->punctuation == SYPunctuationQuater) {
                    y += CGRectGetHeight(rect) * 0.50f;
                }
            }
        }
        
        // Check next run exceeds dirty rect
        BOOL    exceeded;
        SYTextRun* nextTextRun = NULL;
        exceeded = [self _exceededNextRunWithRunContext:runContext 
                run:run inlineStyle:inlineStyle bounds:bounds];
        // If next run has half width glyph, cannot draw truncation sign (...) properly.
        if ((nextTextRun = SYTextRunContextNextTextRun(runContext, run))) {
            if ([self _exceededNextRunWithRunContext:runContext run:nextTextRun inlineStyle:inlineStyle bounds:bounds] &&
                nextTextRun->punctuation != SYPunctuationWhole)
            {
                exceeded = YES;
            }
        }
        
        // Draw glyph for horizontal
        if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
            // Decide glyphs
            CGGlyph*    glyphs;
            int         glyphLength;
            glyphs = run->glyphs;
            glyphLength = run->glyphLength;
            
            // For ellipsis
            if (exceeded && run->type == SYRunTypeText) {
                static CGGlyph  _ellipsisGlyph = 124;
                glyphs = &_ellipsisGlyph;
                glyphLength = 1;
            }
            
            // For outline
            if (_label.outlineWidth > 0) {
                // Set x for outline
                float   ox;
                ox = x;
                
                int i;
                for (i = 0; i < glyphLength; i++) {
                    // Get path
                    CGAffineTransform   transform;
                    CGPathRef           path;
                    transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
                    path = CTFontCreatePathForGlyph(ctFont, *(glyphs + i), &transform);
                    {
                        // Save graphics state
                        CGContextSaveGState(context);
                        
                        // Add path
                        //if (inlineStyle->fontSize < )
                        CGContextTranslateCTM(context, ox, y);
                        CGContextAddPath(context, path);
                        
                        // Configure stroke
                        CGContextSetLineJoin(context, kCGLineJoinRound);
                        CGContextSetLineWidth(context, _label.outlineWidth);
                        
                        // Stroke outline
                        [_label.outlineColor set];
                        CGContextStrokePath(context);
                        
                        // Restore graphics state
                        CGContextRestoreGState(context);
                        
                        // Increase x
                        ox += (run->advances + i)->width;
                    }
                    
                    // Release path
                    CGPathRelease(path), path = NULL;
                }
            }
            
            // Draw glyph
            CGContextShowGlyphsAtPoint(context, x, y, glyphs, glyphLength);
        }
        // Draw glyph for vertical
        else if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
            // Decide glyphs
            CGGlyph*    glyphs;
            int         glyphLength;
            glyphs = run->glyphs;
            glyphLength = run->glyphLength;
            
            // For ellipsis
            static CGGlyph  _ellipsisGlyph = 7897;
            if (exceeded && run->type == SYRunTypeText) {
                glyphs = &_ellipsisGlyph;
                glyphLength = 1;
            }
            
            // For tate chu yoko
            if (SYTextLayoutIsTateChuYoko(run, inlineStyle)) {
                // Draw first glyph
                CGContextShowGlyphsAtPoint(context, x, y, glyphs, 1);
                
                // Draw second glyph
                x += CGRectGetWidth(run->rect) * 0.5f;
                CGContextShowGlyphsAtPoint(context, x, y, glyphs + 1, 1);
            }
            // For other
            else {
                // For 90 clockwise rotation
                if (exceeded && run->type == SYRunTypeText) {
                    y += (inlineStyle->ascent + inlineStyle->descent) - CGRectGetHeight(run->rect);
                }
                else {
                    y += (inlineStyle->ascent + inlineStyle->descent) - run->advances[run->glyphLength - 1].width;
                }
                
                // Draw glyphs in reverse
                int i;
                BOOL rotate;
                for (i = glyphLength - 1; i >= 0; i--) {
                    // Rotate if needed
                    rotate = (run->rotateFlags != NULL && run->rotateFlags[i]);
                    if (glyphs == &_ellipsisGlyph) rotate = NO;// Do not rotate truncate sign
                    if (rotate) {
                        // Get advance for glyph
                        float glyphAdvance = run->advances[i].width;
                        
                        // Rotate context
                        CGContextSaveGState(context);
                        CGContextRotateCTM(context, M_PI_2);
                        CGContextTranslateCTM(context, -(x-y), -(x+y));
                        CGContextTranslateCTM(context, -glyphAdvance, glyphAdvance - CGRectGetWidth(rect));
                    }
                    
                    // Draw glyph
                    CGContextShowGlyphsAtPoint(context, x, y, glyphs + i, 1);

                    if (rotate) {
                        CGContextRestoreGState(context);
                    }
                    
                    // Decrease y with advance
                    if (i > 0) {
                        y -= run->advances[i - 1].width;
                    }
                }
            }
        }
        
        if (exceeded && run->type == SYRunTypeText) {
            break;
        }
        
        // Add bounds
        //[inlineBounds addObject:[NSValue valueWithCGRect:run->rect]];
        
// Draw character bounds
#if TARGET_OS_IPHONE
//NSLog(@"text %@, rect %@", SYTextRunStringWithRun(run), NSStringFromCGRect(run->rect));
//[[UIColor blueColor] set];
//UIRectFrame(CGRectIntegral(run->rect));
#elif TARGET_OS_MAC
//NSFrameRect(CGRectIntegral(run->rect));
#endif
        
        nextRun: {
            // Get next run
            run = SYTextRunContextIterateNext(runContext);
        }
    }
    
    // Free run stack
    SYTextRunStackRelease(inlineRunStack), inlineRunStack = NULL;
    
// Draw floating rects
#if 0
[[UIColor redColor] set];
for (NSValue* floatRectValue in _label.floatRects) {
    CGRect  floatRect;
    floatRect = [floatRectValue CGRectValue];
    floatRect = CGRectInset(floatRect, -1.0f, -1.0f);
    UIRectFrame(floatRect);
}
#endif
}

@end

#pragma mark -

@implementation SYLabel
{
    NSData*             _htmlData;
    NSData*             _cssData;
    int                 _numberOfLines;
    int                 _writingMode;
    float               _outlineWidth;
#if TARGET_OS_IPHONE
    UIColor*            _outlineColor;
#elif TARGET_OS_MAC
    NSColor*            _outlineColor;
#endif
    float               _rowHeightForVertical;
    float               _rowMarginForVertical;
    NSArray*            _floatRects;
    BOOL                _ignoreBlock;
#if TARGET_OS_IPHONE
    UIColor*            _linkHighlightColor;
    UIColor*            _selectedBackgroundColor;
#elif TARGET_OS_MAC
    NSColor*            _linkHighlightColor;
    NSColor*            _selectedBackgroundColor;
#endif
    
    SYTextParser*       _parser;
    SYTextLayout*       _layout;
    CGSize              _parsedSize;
    
    BOOL                _selectable;
    CGPoint             _panBeganPoint;
    SYTextRun*          _panBeganRun;
    SYTextRun*          _beginSelectedRun;
    SYTextRun*          _endSelectedRun;
    
    SYLabelInnerView*   _innerView;
    NSMutableArray*     _selectedViews;
    NSMutableArray*     _highlightedViews;
    
    id __weak           _delegate;
}

// Property
@synthesize numberOfLines = _numberOfLines;
@synthesize writingMode = _writingMode;
@synthesize outlineWidth = _outlineWidth;
@synthesize outlineColor = _outlineColor;
@synthesize linkHighlightColor = _linkHighlightColor;
@synthesize selectedBackgroundColor = _selectedBackgroundColor;
@synthesize rowHeightForVertical = _rowHeightForVertical;
@synthesize rowMarginForVertical = _rowMarginForVertical;
@synthesize floatRects = _floatRects;
@synthesize ignoreBlock = _ignoreBlock;
@synthesize selectable = _selectable;
@synthesize beginSelectedRun = _beginSelectedRun;
@synthesize endSelectedRun = _endSelectedRun;
@synthesize delegate = _delegate;

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (void)_init
{
    // Configure itself
#if TARGET_OS_IPHONE
    self.backgroundColor = [UIColor clearColor];
#endif
    
    // Initialize instance variables
	_parser = [[SYTextParser alloc] init];
    _layout = [[SYTextLayout alloc] init];
    _parsedSize = CGSizeZero;
    _selectedViews = [NSMutableArray array];
    _highlightedViews = [NSMutableArray array];
    _writingMode = SYStyleWritingModeLrTb;
    _selectable = YES;
    
    // Create inner view
    _innerView = [[SYLabelInnerView alloc] initWithFrame:self.frame];
    _innerView.label = self;
    [self addSubview:_innerView];
    
#if TARGET_OS_IPHONE
    // Add long press gesture recognizer
    UILongPressGestureRecognizer*   longPressRecognizer;
    longPressRecognizer = [[UILongPressGestureRecognizer alloc] 
            initWithTarget:self action:@selector(longPressAction:)];
    longPressRecognizer.delegate = self;
    [self addGestureRecognizer:longPressRecognizer];
#endif
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
	// Common init
    [self _init];
	
	return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    
	// Common init
    [self _init];
    
	return self;
}

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//

- (NSString*)html
{
    // Check HTML data
    if (!_htmlData) {
        return nil;
    }
    
    // Create string from data
    return [[NSString alloc] initWithData:_htmlData encoding:NSUTF8StringEncoding];
}

- (void)setHtml:(NSString*)html
{
    // Set HTML data
    _htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    
#if TARGET_OS_IPHONE
    // Set needs layout
    [self setNeedsLayout];
#endif
}

- (NSString*)cssString
{
    // Check CSS data
    if (!_cssData) {
        return nil;
    }
    
    // Create string from data
    return [[NSString alloc] initWithData:_cssData encoding:NSUTF8StringEncoding];
}

- (void)setCssString:(NSString*)cssString
{
    // Set CSS data
    _cssData = [cssString dataUsingEncoding:NSUTF8StringEncoding];
    
#if TARGET_OS_IPHONE
    // Set needs layout
    [self setNeedsLayout];
#endif
}

- (void)setCss:(SYCss*)css
{
    // Set CSS
    _css = css;
    
#if TARGET_OS_IPHONE
    // Set needs layout
    [self setNeedsLayout];
#endif
}

- (NSString*)text
{
    // Get run context
    SYTextRunContext*   runContext;
    runContext = self.runContext;
    if (!runContext) {
        return nil;
    }
    
    // Get text
    NSMutableString*    buffer;
    SYTextRun*          run;
    buffer = [NSMutableString string];
    SYTextRunContextBeginIteration(runContext);
    run = SYTextRunContextIterateNext(runContext);
    while (run) {
        // For text run
        if (run->type == SYRunTypeText) {
            // Add text to buffer
            NSString*   string;
            string = SYTextRunStringWithRun(run);
            if ([string length] > 0) {
                [buffer appendString:string];
            }
        }
        
        // Get next run
        run = SYTextRunContextIterateNext(runContext);
    }
    
    return buffer;
}

- (SYTextRunContext*)runContext
{
    return [self _parsedParserWithSize:self.bounds.size].runContext;
}

- (CGRect)selectedRect
{
    // Get unioned selected rect
    CGRect  selectedRect = CGRectZero;
#if TARGET_OS_IPHONE
    for (UIView* selectedView in _selectedViews)
#elif TARGET_OS_MAC
    for (NSView* selectedView in _selectedViews)
#endif
    {
        // Get frame
        CGRect  rect;
        rect = selectedView.frame;
        
        // Union rect
        if (CGRectIsEmpty(selectedRect)) {
            selectedRect = rect;
        }
        else {
            selectedRect = CGRectUnion(rect, selectedRect);
        }
    }
    
    return selectedRect;
}

- (NSString*)selectedText
{
    // Check begin and end select run
    if (!_beginSelectedRun || !_endSelectedRun) {
        return nil;
    }
    
    // Get text between runs
    return [self textBetweenBeginRun:_beginSelectedRun endRun:_endSelectedRun];
}

- (SYTextParser*)_parsedParserWithSize:(CGSize)size
{
    // Check needs to parse
    BOOL    needsToParse = NO;
    if (_parser.htmlData != _htmlData) {
        _parser.htmlData = _htmlData;
        needsToParse = YES;
    }
    if (_css) {
        if (_parser.css != _css) {
            _parser.css = _css;
            needsToParse = YES;
        }
    }
    if (_cssData) {
        if (_parser.cssData != _cssData) {
            _parser.cssData = _cssData;
            needsToParse = YES;
        }
    }
    if (_parser.numberOfLines != _numberOfLines) {
        _parser.numberOfLines = _numberOfLines;
        needsToParse = YES;
    }
    if (_parser.writingMode != _writingMode) {
        _parser.writingMode = _writingMode;
        needsToParse = YES;
    }
    if (_parser.rowHeightForVertical != _rowHeightForVertical) {
        _parser.rowHeightForVertical = _rowHeightForVertical;
        needsToParse = YES;
    }
    if (_parser.rowMarginForVertical != _rowMarginForVertical) {
        _parser.rowMarginForVertical = _rowMarginForVertical;
        needsToParse = YES;
    }
    if (_parser.hangingIndent != _hangingIndent) {
        _parser.hangingIndent = _hangingIndent;
        needsToParse = YES;
    }
    if (_parser.floatRects != _floatRects) {
        _parser.floatRects = _floatRects;
        needsToParse = YES;
    }
    if (_parser.ignoreBlock != _ignoreBlock) {
        _parser.ignoreBlock = _ignoreBlock;
        needsToParse = YES;
    }
    
    // Parse
    if (needsToParse) {
        [_parser parse];
    }
    
    // Check needs to layout
    BOOL    needsToLayout = needsToParse;
    if (CGSizeEqualToSize(size, CGSizeZero) || !CGSizeEqualToSize(_layout.pageSize, size)) {
        _layout.pageSize = size;
        needsToLayout = YES;
    }
    
    // Layout
    if (needsToLayout) {
        [_layout layoutWithParser:_parser];
    }
    
    return _parser;
}

//--------------------------------------------------------------//
#pragma mark -- Run --
//--------------------------------------------------------------//

- (SYTextRun*)runAtPoint:(CGPoint)point
{
    // Get run context
    SYTextRunContext*   runContext;
    runContext = self.runContext;
    if (!runContext) {
        return nil;
    }
    
    // Get bounds
    CGRect  bounds;
    bounds = self.bounds;
    
    // Check top boundary
    BOOL    beyondTop = NO;
    if (_writingMode == SYStyleWritingModeLrTb) {
        beyondTop = point.y < 0;
    }
    else if (_writingMode == SYStyleWritingModeTbRl) {
        if (point.y >= 0 && point.y <= CGRectGetHeight(bounds)) {
            beyondTop = point.x > CGRectGetWidth(bounds);
        }
        else {
            beyondTop = point.y < 0;
        }
    }
    if (beyondTop) {
        // Get top run
        SYTextRun*  run;
        SYTextRun*  topRun = nil;
        SYTextRunContextBeginIteration(runContext);
        run = SYTextRunContextIterateNext(runContext);
        while (run) {
            // For text
            if (run->type == SYRunTypeText) {
                // Get run rect
                CGRect  runRect;
                runRect = run->rect;
                if (CGRectGetWidth(runRect) == 0 || CGRectGetHeight(runRect) == 0) {
                    goto nextRunBoundaryTop;
                }
                
                // Set top run
                topRun = run;
                
                break;
            }
            
            nextRunBoundaryTop: {
                // Get text run
                run = SYTextRunContextIterateNext(runContext);
            }
        }
        
        return topRun;
    }
    
    // Check bottom boundary
    BOOL    beyondBottom = NO;
    if (_writingMode == SYStyleWritingModeLrTb) {
        beyondBottom = point.y > CGRectGetHeight(self.bounds);
    }
    else if (_writingMode == SYStyleWritingModeTbRl) {
        if (point.y >= 0 && point.y <= CGRectGetHeight(bounds)) {
            beyondBottom = point.x < 0;
        }
        else {
            beyondBottom = point.y > CGRectGetHeight(bounds);
        }
    }
    if (beyondBottom) {
        // Get last run
        SYTextRun*  run;
        SYTextRun*  lastRun = nil;
        SYTextRunContextBeginIteration(runContext);
        run = SYTextRunContextIterateNext(runContext);
        while (run) {
            // For text
            if (run->type == SYRunTypeText) {
                // Get run rect
                CGRect  runRect;
                runRect = run->rect;
                if (CGRectGetWidth(runRect) == 0 || CGRectGetHeight(runRect) == 0) {
                    goto nextRunBoundaryBottom;
                }
                
                // Set last run
                lastRun = run;
            }
            
            nextRunBoundaryBottom: {
                // Get text run
                run = SYTextRunContextIterateNext(runContext);
            }
        }
        
        return lastRun;
    }
    
    // Find run under point
    SYTextRun*  run;
    SYTextRun*  minRun = nil;
    SYTextRun*  topRun = nil;
    SYTextRun*  lastRun = nil;
    float       minDistance = MAXFLOAT;
    SYTextRunContextBeginIteration(runContext);
    run = SYTextRunContextIterateNext(runContext);
    while (run) {
        // For text
        if (run->type == SYRunTypeText) {
            // Get run rect
            CGRect  runRect;
            runRect = run->rect;
            if (CGRectGetWidth(runRect) == 0 || CGRectGetHeight(runRect) == 0) {
                goto nextRun;
            }
            
            // Check contains
            if (CGRectContainsPoint(CGRectInset(runRect, -4.0f, -4.0f), point)) {
                return run;
            }
            
            // Set top and last run
            if (!topRun) {
                topRun = run;
            }
            lastRun = run;
            
            // Calc distance
            float   dx, dy, distance;
            dx = CGRectGetMidX(runRect) - point.x;
            dy = CGRectGetMidY(runRect) - point.y;
            distance = dx * dx + dy * dy;
            if (distance < minDistance) {
                // Set min run and distance
                minRun = run;
                minDistance = distance;
            }
        }
        
        nextRun: {
            // Get next run
            run = SYTextRunContextIterateNext(runContext);
        }
    }
    
    // Use min run
    if (minRun) {
        return minRun;
    }
    
    // Use last run
    return lastRun;
}

- (NSString*)textBetweenBeginRun:(SYTextRun*)beginRun endRun:(SYTextRun*)endRun
{
    // Get run context
    SYTextRunContext*   runContext;
    runContext = self.runContext;
    if (!runContext) {
        return nil;
    }
    
    // Get text
    return SYTextRunContextStringBetweenRun(runContext, beginRun, endRun);
}

- (NSArray*)runRectsBetweenBeginRun:(SYTextRun*)beginRun endRun:(SYTextRun*)endRun 
        containsLineHeight:(BOOL)containsLineHeight
{
    // Get run context
    SYTextRunContext*   runContext;
    runContext = self.runContext;
    if (!runContext) {
        return nil;
    }
    
    // Get run rects
    NSMutableArray* runRects;
    SYTextRun*      tmpRun;
    runRects = [NSMutableArray array];
    tmpRun = beginRun;
    while (tmpRun) {
        // For text run
        if (tmpRun->type == SYRunTypeText) {
            // Get run rect
            CGRect  rect;
            rect = tmpRun->rect;
            
            // For line height
            if (containsLineHeight) {
                // For horizontal
                if (_writingMode == SYStyleWritingModeLrTb) {
                    float   extraHeight;
                    extraHeight = CGRectGetHeight(rect) * (tmpRun->inlineStyle->lineHeight - 1.0f);
                    rect.origin.y -= extraHeight;
                    rect.size.height  += extraHeight;
                }
                // For vertical
                else if (_writingMode == SYStyleWritingModeTbRl) {
                    float   extraWidth;
                    extraWidth = CGRectGetWidth(rect) * (tmpRun->inlineStyle->lineHeight - 1.0f);
                    rect.size.width  += extraWidth;
                }
            }
            
            // Intersect with bounds
            rect = CGRectIntersection(rect, self.bounds);
            
            // Append run rect
            [runRects addObject:[NSValue valueWithCGRect:rect]];
        }
        
        // Check with end run
        if (tmpRun->runId >= endRun->runId) {
            break;
        }
        
        // Get next run
        tmpRun = SYTextRunContextNextRun(runContext, tmpRun);
    }
    
    return runRects;
}

- (void)selectTextBetweenPoint0:(CGPoint)point0 point1:(CGPoint)point1
{
    // Check selectable
    if (!_selectable) {
        return;
    }
    
    // Get run at point
    SYTextRun*  run0;
    SYTextRun*  run1;
    run0 = [self runAtPoint:point0];
    run1 = [self runAtPoint:point1];
    if (!run0 || !run1) {
        return;
    }
    
    // Clear selected run
    _beginSelectedRun = nil;
    _endSelectedRun = nil;
    
    // Remove old views
    [_selectedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_selectedViews removeAllObjects];
    
    // Decide begin run and end run
    SYTextRun*  beginRun;
    SYTextRun*  endRun;
    if (run0->runId < run1->runId) {
        beginRun = run0;
        endRun = run1;
    }
    else {
        beginRun = run1;
        endRun = run0;
    }
    
    // Set selected run
    _beginSelectedRun = beginRun;
    _endSelectedRun = endRun;
    
    // Get run rects between begin and end
    NSArray*    runRects;
    NSArray*    runRectsWithoutLineHeight;
    runRects = [self runRectsBetweenBeginRun:beginRun endRun:endRun containsLineHeight:YES];
    runRectsWithoutLineHeight = [self runRectsBetweenBeginRun:beginRun endRun:endRun containsLineHeight:NO];
    
    // Union rects
    NSMutableArray* unionRects;
    CGRect          prevRect = CGRectZero;
    CGRect          prevRectWithoutLineHeight = CGRectZero;
    int             i;
    unionRects = [NSMutableArray array];
    for (i = 0; i < [runRects count]; i++) {
        // Get run rect
        CGRect  rect;
        rect = [[runRects objectAtIndex:i] CGRectValue];
        if (CGRectGetWidth(rect) == 0 || CGRectGetHeight(rect) == 0) {
            continue;
        }
        
        // Get run rect without line height
        CGRect  rectWithoutLineHeight;
        rectWithoutLineHeight = [[runRectsWithoutLineHeight objectAtIndex:i] CGRectValue];
        if (CGRectGetWidth(rectWithoutLineHeight) == 0 || CGRectGetHeight(rectWithoutLineHeight) == 0) {
            continue;
        }
        
        // For prev rect is zero
        if (CGRectIsEmpty(prevRect)) {
            // Set rect
            prevRect = rect;
            prevRectWithoutLineHeight = rectWithoutLineHeight;
        }
        // For other
        else {
            // Check Y axis
            float   prevMinY, prevMaxY, minY, maxY;
            float   prevMinX, prevMaxX, minX, maxX;
            prevMinY = CGRectGetMinY(prevRectWithoutLineHeight);
            prevMaxY = CGRectGetMaxY(prevRectWithoutLineHeight);
            minY = CGRectGetMinY(rectWithoutLineHeight);
            maxY = CGRectGetMaxY(rectWithoutLineHeight);
            prevMinX = CGRectGetMinX(prevRectWithoutLineHeight);
            prevMaxX = CGRectGetMaxX(prevRectWithoutLineHeight);
            minX = CGRectGetMinX(rectWithoutLineHeight);
            maxX = CGRectGetMaxX(rectWithoutLineHeight);
            if ((_writingMode == SYStyleWritingModeLrTb && prevMinY < maxY && minY < prevMaxY) || 
                (_writingMode == SYStyleWritingModeTbRl && prevMinX < maxX && minX < prevMaxX))
            {
                // Union rects
                prevRect = CGRectUnion(prevRect, rect);
                prevRectWithoutLineHeight = CGRectUnion(prevRectWithoutLineHeight, rectWithoutLineHeight);
            }
            else {
                // Add prev rect
                [unionRects addObject:[NSValue valueWithCGRect:prevRect]];
                
                // Set prev rect
                prevRect = rect;
                prevRectWithoutLineHeight = rectWithoutLineHeight;
            }
        }
    }
    
    // Add last prev rect
    if (!CGRectIsEmpty(prevRect)) {
        [unionRects addObject:[NSValue valueWithCGRect:prevRect]];
    }
    
    // Create selected views
    for (NSValue* rectValue in unionRects) {
#if TARGET_OS_IPHONE
        // Create selected view
        UIView* view;
        view = [[UIView alloc] initWithFrame:[rectValue CGRectValue]];
        view.backgroundColor = _selectedBackgroundColor;
        view.tag = SYLabelSelectionView;
        
        // Add selected view
        [self addSubview:view];
        [self insertSubview:view belowSubview:_innerView];
        
        [_selectedViews addObject:view];
#endif
    }
}

- (void)deselectText
{
    // Remove selected run
    _beginSelectedRun = nil;
    _endSelectedRun = nil;
    
    // Remove selected views
    [_selectedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_selectedViews removeAllObjects];
}

//--------------------------------------------------------------//
#pragma mark -- Geometry --
//--------------------------------------------------------------//

- (CGSize)sizeThatFits:(CGSize)size
{
    // Get size
    CGSize  fitSize;
    fitSize = [self sizeWithConstrainedToSize:CGSizeZero];
    
    return fitSize;
}

+ (CGSize)sizeWithConstrainedToSize:(CGSize)size 
        html:(NSString*)html css:(SYCss*)css
{
    return [self sizeWithConstrainedToSize:size html:html css:css 
            numberOfLines:0 writingMode:SYStyleWritingModeLrTb 
            rowHeightForVertical:0 rowMarginForVertical:0 floatRects:nil ignoreBlock:NO];
}

+ (CGSize)sizeWithConstrainedToSize:(CGSize)size 
        html:(NSString*)html 
        css:(SYCss*)css 
        numberOfLines:(int)numberOfLines 
        writingMode:(int)writingMode 
        rowHeightForVertical:(float)rowHeightForVertical 
        rowMarginForVertical:(float)rowMarginForVertical 
        floatRects:(NSArray*)floatRects 
        ignoreBlock:(BOOL)ignoreBlock
{
    // Parse HTML
    SYTextParser*   parser;
    parser = [[SYTextParser alloc] init];
    parser.htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    parser.css = css;
    parser.numberOfLines = numberOfLines;
    parser.writingMode = writingMode;
    parser.rowHeightForVertical = rowHeightForVertical;
    parser.rowMarginForVertical = rowMarginForVertical;
    parser.floatRects = floatRects;
    parser.ignoreBlock = ignoreBlock;
    [parser parse];
    
    // Layout
    SYTextLayout*   layout;
    layout = [[SYTextLayout alloc] init];
    layout.pageSize = size;
    [layout layoutWithParser:parser];
    
    // Get first block size
    SYTextRun*  run;
    run = parser.runContext->runPool->runs;
    return run->rect.size;
}

- (CGSize)sizeWithConstrainedToSize:(CGSize)size
{
    // Get first block size
    SYTextRun*  run;
    run = [self _parsedParserWithSize:size].runContext->runPool->runs;
    return run->rect.size;
}

//--------------------------------------------------------------//
#pragma mark -- Action --
//--------------------------------------------------------------//

- (BOOL)singleTapAction:(CGPoint)point jumped:(BOOL)jumped
{
    BOOL    isTapedLink = NO;
    
    // Get run context
    SYTextRunContext*   runContext;
    runContext = self.runContext;
    if (!runContext) {
        return isTapedLink;
    }
    
    // Create run stack
    SYTextRunStack* inlineRunStack;
    inlineRunStack = SYTextRunStackCreate();
    
    // Find run under point
    SYTextRun*  run;
    SYTextRun*  linkedInlineRun = NULL;
    SYTextRunContextBeginIteration(runContext);
    run = SYTextRunContextIterateNext(runContext);
    while (run) {
        // For inline begin
        if (run->type == SYRunTypeInlineBegin) {
            // Push inline begin run
            SYTextRunStackPush(inlineRunStack, run);
            
            // Check link
            if (run->inlineStyle->linkUrl) {
                linkedInlineRun = run;
            }
            
            // Go next run
            goto nextRun;
        }
        
        // For inline end
        else if (run->type == SYRunTypeInlineEnd) {
            // Pop inline begin run
            SYTextRun*  poppedRun;
            poppedRun = SYTextRunStackPop(inlineRunStack);
            
            // Clear link
            if (linkedInlineRun == poppedRun) {
                linkedInlineRun = NULL;
            }
            
            // Go next run
            goto nextRun;
        }
        
        // For not text
        else if (run->type != SYRunTypeText) {
            // Go next run
            goto nextRun;
        }
        
        // Get run rect
        CGRect  runRect;
        runRect = run->rect;
        
        // Check contains
        if (CGRectContainsPoint(CGRectInset(runRect, -4.0f, -4.0f), point)) {
            // For linked
            if (linkedInlineRun) {
                // Get run rects for linked
                NSMutableArray* runRects;
                CGRect          currentRunRect = CGRectZero;
                SYTextRun*      tmpRun;
                SYTextRun*      endRun = NULL;
                runRects = [NSMutableArray array];
                tmpRun = SYTextRunContextNextRun(runContext, linkedInlineRun);
                while (tmpRun) {
                    // For inline end
                    if (tmpRun->type == SYRunTypeInlineEnd) {
                        if (tmpRun->inlineStyle == linkedInlineRun->inlineStyle) {
                            endRun = tmpRun;
                            
                            break;
                        }
                    }
                    
                    // For text run
                    if (tmpRun->type == SYRunTypeText) {
                        // Get run rect
                        CGRect  rect;
                        rect = CGRectInset(tmpRun->rect, -4.0f, -4.0f);
                        
                        // For empty
                        if (CGRectIsEmpty(currentRunRect)) {
                            // Set current rect
                            currentRunRect = rect;
                        }
                        // For intersect
                        else if (CGRectIntersectsRect(currentRunRect, rect)) {
                            // Get union
                            currentRunRect = CGRectUnion(currentRunRect, rect);
                        }
                        // For not intersect
                        else {
                            // Add current run rect
                            [runRects addObject:[NSValue valueWithCGRect:currentRunRect]];
                            
                            // Set current rect
                            currentRunRect = rect;
                        }
                    }
                    
                    // Get next run
                    tmpRun = SYTextRunContextNextRun(runContext, tmpRun);
                }
                
                // Ask to delegate
                if ([_delegate respondsToSelector:@selector(label:shouldSelectLink:beginRun:endRun:)]) {
                    NSURL*  url;
                    url = linkedInlineRun->inlineStyle->linkUrl;
                    if (![_delegate label:self shouldSelectLink:url beginRun:linkedInlineRun endRun:endRun]) {
                        break;
                    }
                }
                
                // Add last run rect
                if (!CGRectIsEmpty(currentRunRect)) {
                    [runRects addObject:[NSValue valueWithCGRect:currentRunRect]];
                }
                
                // Remove old highlighted views
                [_highlightedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [_highlightedViews removeAllObjects];

                // Highlight run rects
                __block CGRect  highlightedViewRect = CGRectZero;
                void (^pushHighlightedView)(CGRect) = ^void(CGRect frame){
#if TARGET_OS_IPHONE
                    // Create hightlighted view
                    UIView* v = [[UIView alloc] initWithFrame:frame];
                    v.backgroundColor = _linkHighlightColor; //[UIColor colorWithWhite:0.8 alpha:1.0f];
                    v.layer.cornerRadius = 4.0f;
                    
                    // Add highlight view
                    [self insertSubview:v belowSubview:_innerView];
                    [_highlightedViews addObject:v];
#endif
                };
                
                // Iterate run rects
                [runRects enumerateObjectsUsingBlock:^(NSValue* rectValue, NSUInteger idx, BOOL *stop) {
                    CGRect rect = rectValue.CGRectValue;
                    if (CGRectEqualToRect(rect, CGRectZero)) return;
                    
                    // Union rect
                    if (CGRectEqualToRect(highlightedViewRect, CGRectZero)) {
                        highlightedViewRect = rect;
                    }
                    else {
                        highlightedViewRect = CGRectUnion(rect, highlightedViewRect);
                    }
                    
                    // Create and push highlighted view if needed
                    if (rectValue == runRects.lastObject) {
                        pushHighlightedView(highlightedViewRect);
                        highlightedViewRect = CGRectZero;
                    }
                    else {
                        // Get next rect
                        CGRect nextRect = [runRects[idx+1] CGRectValue];
                        
                        float currentRectTop = 0.f, nextRectBottom = 0.f;
                        float currentRectBottom = 0.f, nextRectTop = 0.f;
                        // For horizontal
                        if (linkedInlineRun->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                            currentRectBottom = CGRectGetMaxY(highlightedViewRect);
                            nextRectTop = CGRectGetMinY(nextRect);
                        }
                        // For vertical
                        else if (linkedInlineRun->inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                            currentRectTop = CGRectGetMaxX(highlightedViewRect);
                            currentRectBottom = CGRectGetMinX(highlightedViewRect);
                            nextRectTop = CGRectGetMaxX(nextRect);
                            nextRectBottom = CGRectGetMinX(nextRect);
                            // change sign
                            currentRectTop *= -1.f;
                            currentRectBottom *= -1.f;
                            nextRectTop *= -1.f;
                            nextRectBottom *= -1.f;
                        }
                        
                        // Check that current rect and next rect is on the same line or not
                        if (currentRectBottom < nextRectTop ||
                            currentRectTop > nextRectBottom) {
                            pushHighlightedView(highlightedViewRect);
                            highlightedViewRect = CGRectZero;
                        }
                    }
                }];
                
                if (jumped) {
                    // Wait a moment
                    double delayInSeconds = 0.1f;
                    dispatch_time_t popTime = dispatch_time(
                            DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

                        // Remove highlight views
                        [_highlightedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        [_highlightedViews removeAllObjects];
                        
                        // Notify to delegate
                        if ([_delegate respondsToSelector:@selector(label:linkTapped:beginRun:endRun:)]) {
                            NSURL*  url;
                            url = linkedInlineRun->inlineStyle->linkUrl;
                            [_delegate label:self linkTapped:url beginRun:linkedInlineRun endRun:endRun];
                        }
                    });
                }
                
                // Rise flag
                isTapedLink = YES;
                
                return isTapedLink;
            }
        }
        
        nextRun: {
            // Get next run
            run = SYTextRunContextIterateNext(runContext);
        }
    }
    
    // Free run stack
    SYTextRunStackRelease(inlineRunStack), inlineRunStack = NULL;
    
    return isTapedLink;
}

#if TARGET_OS_IPHONE
- (IBAction)longPressAction:(UILongPressGestureRecognizer*)recognizer
{
    // Check selectable
    if (!_selectable) {
        return;
    }
    
    // For processed by delegate
    if ([_delegate respondsToSelector:@selector(label:longPressed:)]) {
        // Notify to delegate
        [_delegate label:self longPressed:recognizer];
        
        return;
    }
    
#if 0
    // Get point
    CGPoint point;
    point = [recognizer locationInView:self];
    
    // Switch by state
    switch (recognizer.state) {
    // For began
    case UIGestureRecognizerStateBegan: {
        // Set pan began point and run
        _panBeganPoint = point;
        _panBeganRun = [self runAtPoint:point];
        
        break;
    }
    // For changed
    case UIGestureRecognizerStateChanged: {
        // Check began run
        if (!_panBeganRun) {
            break;
        }
        
        // Get run at point
        SYTextRun*  changedRun;
        changedRun = [self runAtPoint:point];
        if (!changedRun) {
            break;
        }
        
        // Get run rects between began and changed
        SYTextRun*  beginRun;
        SYTextRun*  endRun;
        NSArray*    runRects;
        if (_panBeganRun->runId < changedRun->runId) {
            beginRun = _panBeganRun;
            endRun = changedRun;
        }
        else {
            beginRun = changedRun;
            endRun = _panBeganRun;
        }
        runRects = [self runRectsBetweenBeginRun:beginRun endRun:endRun containsLineHeight:YES];
        
        // Remove old views
        [_selectedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_selectedViews removeAllObjects];
        
        // Create selected views
        for (NSValue* rectValue in runRects) {
            // Create selected view
            UIView* view;
            view = [[UIView alloc] initWithFrame:[rectValue CGRectValue]];
            view.backgroundColor = 
                    [UIColor colorWithRed:182 / 255.0f green:214 / 255.0f blue:253 / 255.0f alpha:1.0f];
            
            // Add selected view
            [self addSubview:view];
            [self insertSubview:view belowSubview:_innerView];
        }
        
        break;
    }
    // For other
    default: {
        break;
    }
    }
#endif
}
#endif

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)_layoutSubviews
{
    // Get parsed parser for parse and layout
    SYTextParser*   parser;
    parser = [self _parsedParserWithSize:self.bounds.size];
    
    // Layout inner view
    _innerView.frame = self.bounds;
}

#if TARGET_OS_IPHONE
- (void)layoutSubviews
{
    // Invoke super
    [super layoutSubviews];
    
    // Get parsed parser for parse and layout
    SYTextParser*   parser;
    parser = [self _parsedParserWithSize:self.bounds.size];
    
    // Layout inner view
    _innerView.frame = self.bounds;
    [_innerView setNeedsDisplay];
}
#elif TARGET_OS_MAC
- (BOOL)isFlipped
{
    return YES;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    // Invoke super
    [super resizeSubviewsWithOldSize:oldSize];
    
    // Layout subviews
    [self _layoutSubviews];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Layout subviews
    [self _layoutSubviews];
}
#endif

//--------------------------------------------------------------//
#pragma mark -- UIGestureRecognizerDelegate --
//--------------------------------------------------------------//

#if TARGET_OS_IPHONE
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    // Get point
    CGPoint point;
    point = [gestureRecognizer locationInView:self];
    
    // Get run context
    SYTextRunContext*   runContext;
    runContext = self.runContext;
    if (!runContext) {
        return NO;
    }
    
    // Create run stack
    SYTextRunStack* inlineRunStack;
    inlineRunStack = SYTextRunStackCreate();
    
    // Find run under point
    SYTextRun*  run;
    SYTextRun*  linkedInlineRun = NULL;
    SYTextRunContextBeginIteration(runContext);
    run = SYTextRunContextIterateNext(runContext);
    while (run) {
        // For inline begin
        if (run->type == SYRunTypeInlineBegin) {
            // Push inline begin run
            SYTextRunStackPush(inlineRunStack, run);
            
            // Check link
            if (run->inlineStyle->linkUrl) {
                linkedInlineRun = run;
            }
            
            // Go next run
            goto nextRun;
        }
        
        // For inline end
        else if (run->type == SYRunTypeInlineEnd) {
            // Pop inline begin run
            SYTextRun*  poppedRun;
            poppedRun = SYTextRunStackPop(inlineRunStack);
            
            // Clear link
            if (linkedInlineRun == poppedRun) {
                linkedInlineRun = NULL;
            }
            
            // Go next run
            goto nextRun;
        }
        
        // For not text
        else if (run->type != SYRunTypeText) {
            // Go next run
            goto nextRun;
        }
        
        // Get run rect
        CGRect  runRect;
        runRect = run->rect;
        
        // Check contains
        if (CGRectContainsPoint(CGRectInset(runRect, -4.0f, -4.0f), point)) {
            // For linked
            if (linkedInlineRun) {
                // Free run stack
                SYTextRunStackRelease(inlineRunStack), inlineRunStack = NULL;
                
                return YES;
            }
        }
        
    nextRun: {
        // Get next run
        run = SYTextRunContextIterateNext(runContext);
    }
        
    }
    
    // Free run stack
    SYTextRunStackRelease(inlineRunStack), inlineRunStack = NULL;
    
    return NO;
}
#endif

//--------------------------------------------------------------//
#pragma mark -- Touch handling --
//--------------------------------------------------------------//

#if TARGET_OS_IPHONE
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{   
    // Get point
    CGPoint point;
    point = [[touches anyObject] locationInView:self];
    
    // Do tap action
    if ([self singleTapAction:point jumped:NO] == YES) {
        // Taped to link
        return;
    }
    
    // If not taped link, invoke super
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    // Invoke super
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{   
    // Get point
    CGPoint point;
    point = [[touches anyObject] locationInView:self];
    
    // Culc highlighted view rect
    CGRect  rect = CGRectZero;
    for (UIView* v in _highlightedViews) {
        // For first view
        if (CGRectEqualToRect(rect, CGRectZero)) {
            rect = v.frame;
        }
        else {
            rect = CGRectUnion(rect, v.frame);
        }
    }
    
    // Check point contained in highlighted view rect
    if (CGRectContainsPoint(rect, point)) {
        // For contained, do tap action
        if ([self singleTapAction:point jumped:YES] == YES) {
            // Taped to link
            return;
        }
    }
    
    // Remove highlight views
    [_highlightedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_highlightedViews removeAllObjects];
    
    // Invoke super
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    // Remove old higlighted views
    [_highlightedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_highlightedViews removeAllObjects];
    
    // Invoke super
    [super touchesCancelled:touches withEvent:event];
}
#endif

@end
