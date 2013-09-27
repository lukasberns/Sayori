/*
SYTextLayout.m

Author: Makoto Kinoshita, Hajime Nakamura

Copyright 2010-2013 HMDT. All rights reserved.
*/

#import "SYCssContext.h"
#import "SYFontManager.h"
#import "SYTextLayout.h"
#import "SYTextParser.h"
#import "SYTextSubstitutionGlyph.h"

void SYFontGetGlyphsForCharacters(
        CTFontRef font, const 
        UniChar characters[], 
        CGGlyph glyphs[], 
        CFIndex count)
{
    static  CGGlyph _hiraGlyphs[65535];
    static  BOOL    _glyphsInitialized = NO;
    if (!_glyphsInitialized) {
        memset(_hiraGlyphs, 0, sizeof(_hiraGlyphs));
        _glyphsInitialized = YES;
    }
    
    // Get glyph from unichar
    int i;
    for (i = 0; i < count; i++) {
        // Get unichar
        unichar c;
        c = characters[i];
        
        // Get glyph
        CGGlyph glyph;
        glyph = _hiraGlyphs[c];
        if (!glyph) {
            // Cache glyph
            CTFontGetGlyphsForCharacters(font, &c, &glyph, 1);
            _hiraGlyphs[c] = glyph;
        }
        
        // Set glyph
        glyphs[i] = glyph;
    }
}

double SYFontGetAdvancesForGlyphs (
       CTFontRef font,
       CTFontOrientation orientation,
       const CGGlyph glyphs[],
       CGSize advances[],
       CFIndex count)
{
    static  CGSize  _hiraAdvances[65535];
    static  BOOL    _advancesInitialized = NO;
    if (!_advancesInitialized) {
        memset(_hiraAdvances, 0, sizeof(_hiraAdvances));
        _advancesInitialized = YES;
    }
    
    // Get advances from glyph
    double  total  = 0;
    int     i;
    for (i = 0; i < count; i++) {
        // Get glyph
        CGGlyph glyph;
        glyph = glyphs[i];
        
        // Get advance
        if (_hiraAdvances[glyph].width == 0) {
            // Cache advance
            CTFontGetAdvancesForGlyphs(
                    font, orientation, glyphs, _hiraAdvances + glyph, 1);
        }
        
        // Set advances
        advances[i] = _hiraAdvances[glyph];
        
        // Add total
        total += advances[i].width;
    }
    
    return total;
}

static unichar _getFullWidthAlphaNumeric(
        unichar uc);
static CGGlyph _getHalfWidthNumericGlyph(
        unichar uc);
static BOOL _isHalfWidthNumericGlyph(
        CGGlyph glyph);
static BOOL _isRunFilledWithSpace(
        SYTextRun* run);
static void _initializeHalfWidePunctuationMarks();
static BOOL _isFirstHalfPunctuation(
        unichar uc);
static BOOL _isSecondHalfPunctuation(
        unichar uc);
#if 0
static BOOL _isQuarterPunctuation(
        unichar uc);
#endif

static int _getPunctuationType(
        unichar uc);
static BOOL _isNotInsertingAfterMarginCharacter(
        unichar uc);
static BOOL _isNotStartingLineCharacter(
        unichar uc);
static BOOL _isNotEndingLineCharacter(
        unichar uc);
static float _runAdvances(
        SYTextRunContext* runContext, 
        SYTextRun* run, 
        int writingMode);

static unichar*     _firstHalfPunctuationMarks;
static NSUInteger   _firstHalfPunctuationMarkCount = 0;
static unichar*     _secondHalfPunctuationMarks;
static NSUInteger   _secondHalfPunctuationMarkCount = 0;
static unichar*     _quarterPunctuationMarks;
static NSUInteger   _quarterPunctuationMarkCount = 0;

static unichar _getFullWidthAlphaNumeric(
        unichar uc)
{
    // Get full width alpha numeric
    static  unichar _fullZero = 0;
    static  unichar _fullCapitalA = 0;
    static  unichar _fullSmallA = 0;
    if (_fullZero == 0) {
        _fullZero = [@"０" characterAtIndex:0];
        _fullCapitalA = [@"Ａ" characterAtIndex:0];
        _fullSmallA = [@"ａ" characterAtIndex:0];
    }
    
    if ('0' <= uc && uc <= '9') {
        return _fullZero + uc - '0';
    }
    else if ('A' <= uc && uc <= 'Z') {
        return _fullCapitalA + uc - 'A';
    }
    else if ('a' <= uc && uc <= 'z') {
        return _fullSmallA + uc - 'a';
    }
    
    return 0;
}

static CGGlyph _getHalfWidthNumericGlyph(
        unichar uc)
{
    if ('0' <= uc && uc <= '9') {
        return 247 + uc - '0'; // 247 is half width zero in Adobe Japanese
    }
    
    return 0;
}

static BOOL _isHalfWidthNumericGlyph(
        CGGlyph glyph)
{
    return glyph >= 247 && glyph <= 256;
}

static BOOL _isRunFilledWithSpace(
        SYTextRun* run)
{
    if (!run || run->type != SYRunTypeText) return NO;
    
    // Get space characters
    static unichar _spaceChars[2];
    static int  _spaceCharsCount = 0;
    if (!_spaceCharsCount) {
        _spaceChars[_spaceCharsCount++] = ' ';
        _spaceChars[_spaceCharsCount++] = [@"　" characterAtIndex:0];
    }
    
    // Compare
    for (unichar* uc = run->text; uc < run->text + run->textLength; uc++) {
        for (int i = 0; i < _spaceCharsCount; i++) {
            if (*uc == _spaceChars[i]) return YES;
        }
    }
    
    return NO;
}

static void _initializeHalfWidePunctuationMarks()
{
    // Initialize static variables
    if (!_firstHalfPunctuationMarks) {
        // Create string for half wide punctuation marks
        NSString*   firstHalfPunctuationMarks;
        NSString*   secondHalfPunctuationMarks;
        NSString*   quarterPunctuationMarks;
        firstHalfPunctuationMarks = @"、。）］｝〕〉》」』】〙〗〟｠";
        secondHalfPunctuationMarks = @"（［｛〔〈《「『【〘〖〝｟";
        quarterPunctuationMarks = @"・：；◦";
        
        // Get characters
        _firstHalfPunctuationMarkCount = [firstHalfPunctuationMarks length];
        _firstHalfPunctuationMarks = malloc(sizeof(unichar) * _firstHalfPunctuationMarkCount);
        [firstHalfPunctuationMarks getCharacters:_firstHalfPunctuationMarks 
                range:NSMakeRange(0, _firstHalfPunctuationMarkCount)];
        
        _secondHalfPunctuationMarkCount = [secondHalfPunctuationMarks length];
        _secondHalfPunctuationMarks = malloc(sizeof(unichar) * _secondHalfPunctuationMarkCount);
        [secondHalfPunctuationMarks getCharacters:_secondHalfPunctuationMarks 
                range:NSMakeRange(0, _secondHalfPunctuationMarkCount)];
        
        _quarterPunctuationMarkCount = [quarterPunctuationMarks length];
        _quarterPunctuationMarks = malloc(sizeof(unichar) * _quarterPunctuationMarkCount);
        [quarterPunctuationMarks getCharacters:_quarterPunctuationMarks 
                range:NSMakeRange(0, _quarterPunctuationMarkCount)];
    }
}

static BOOL _isFirstHalfPunctuation(
        unichar uc)
{
    unichar*    tmp;
    
    // Initialize
    _initializeHalfWidePunctuationMarks();
    
    // For first half
    tmp = _firstHalfPunctuationMarks;
    while (tmp - _firstHalfPunctuationMarks < _firstHalfPunctuationMarkCount) {
        if (*tmp == uc) {
            return YES;
        }
        tmp++;
    }
    
    return NO;
}

static BOOL _isSecondHalfPunctuation(
        unichar uc)
{
    unichar*    tmp;
    
    // Initialize
    _initializeHalfWidePunctuationMarks();
    
    // For second half
    tmp = _secondHalfPunctuationMarks;
    while (tmp - _secondHalfPunctuationMarks < _secondHalfPunctuationMarkCount) {
        if (*tmp == uc) {
            return YES;
        }
        tmp++;
    }
    
    return NO;
}

#if 0
static BOOL _isQuarterPunctuation(
        unichar uc)
{
    unichar*    tmp;
    
    // Initialize
    _initializeHalfWidePunctuationMarks();
    
    // For quater
    tmp = _quarterPunctuationMarks;
    while (tmp - _quarterPunctuationMarks < _quarterPunctuationMarkCount) {
        if (*tmp == uc) {
            return YES;
        }
        tmp++;
    }
    
    return NO;
}
#endif

static int _getPunctuationType(
        unichar uc)
{
    unichar*    tmp;
    
    // Initialize
    _initializeHalfWidePunctuationMarks();
    
    // For first half
    tmp = _firstHalfPunctuationMarks;
    while (tmp - _firstHalfPunctuationMarks < _firstHalfPunctuationMarkCount) {
        if (*tmp == uc) {
            return SYPunctuationFirstHalf;
        }
        tmp++;
    }
    
    // For second half
    tmp = _secondHalfPunctuationMarks;
    while (tmp - _secondHalfPunctuationMarks < _secondHalfPunctuationMarkCount) {
        if (*tmp == uc) {
            return SYPunctuationSecondHalf;
        }
        tmp++;
    }
    
    // For quarter
    tmp = _quarterPunctuationMarks;
    while (tmp - _quarterPunctuationMarks < _quarterPunctuationMarkCount) {
        if (*tmp == uc) {
            return SYPunctuationQuater;
        }
        tmp++;
    }
    
    return SYPunctuationWhole;
}

static BOOL _isNotInsertingAfterMarginCharacter(
        unichar uc)
{
    // Initialize static variables
    static unichar* _notInsertingAfterMarginCharacters = NULL;
    static NSUInteger _notInsertingAfterMarginCharactersCount = 0;
    if (!_notInsertingAfterMarginCharacters) {
        NSString*   notInsertingAfterMarginCharacters;
        notInsertingAfterMarginCharacters = @"〳〴";
        
        _notInsertingAfterMarginCharactersCount = notInsertingAfterMarginCharacters.length;
        _notInsertingAfterMarginCharacters = malloc(sizeof(unichar) * _notInsertingAfterMarginCharactersCount);
        [notInsertingAfterMarginCharacters getCharacters:_notInsertingAfterMarginCharacters range:NSMakeRange(0, _notInsertingAfterMarginCharactersCount)];
    }
    
    for (unichar* tmp = _notInsertingAfterMarginCharacters; tmp - _notInsertingAfterMarginCharacters < _notInsertingAfterMarginCharactersCount; tmp++) {
        if (uc == *tmp) return YES;
    }

    return NO;
}

static BOOL _isNotStartingLineCharacter(
        unichar uc)
{
    // Initialize static variables
    static unichar*     _notStartingLineCharacters;
    static NSUInteger   _notStartingLineCharactersCount = 0;
    if (!_notStartingLineCharacters) {
        // Create string for not starting line characters
        NSString*   notStartingLineCharacters;
        notStartingLineCharacters = @",.?:;!)）]］｝、〕〉》」』】〙〗〟’”｠»ヽヾーァィゥェォッャュョヮヵヶぁぃぅぇぉっゃゅょゎゕゖㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿ々〻‐゠–〜？!‼⁇⁈⁉・:;。.\"™";
        
        // Get characters
        _notStartingLineCharactersCount = [notStartingLineCharacters length];
        _notStartingLineCharacters = malloc(sizeof(unichar) * _notStartingLineCharactersCount);
        [notStartingLineCharacters getCharacters:_notStartingLineCharacters 
                range:NSMakeRange(0, _notStartingLineCharactersCount)];
    }
    
    // Find character
    unichar*    tmp;
    tmp = _notStartingLineCharacters;
    while (tmp - _notStartingLineCharacters < _notStartingLineCharactersCount) {
        if (*tmp == uc) {
            return YES;
        }
        tmp++;
    }
    
    return NO;
}

static BOOL _isNotEndingLineCharacter(
        unichar uc)
{
    // Initialize static variables
    static unichar*     _notEndingLineCharacters;
    static NSUInteger   _notEndingLineCharactersCount = 0;
    if (!_notEndingLineCharacters) {
        // Create string for not ending line characters
        NSString*   notEndingLineCharacters;
        notEndingLineCharacters = @"(（[［｛〔〈《「『【〘〖〝‘“｟«\"'";
        
        // Get characters
        _notEndingLineCharactersCount = [notEndingLineCharacters length];
        _notEndingLineCharacters = malloc(sizeof(unichar) * _notEndingLineCharactersCount);
        [notEndingLineCharacters getCharacters:_notEndingLineCharacters 
                range:NSMakeRange(0, _notEndingLineCharactersCount)];
    }
    
    // Find character
    unichar*    tmp;
    tmp = _notEndingLineCharacters;
    while (tmp - _notEndingLineCharacters < _notEndingLineCharactersCount) {
        if (*tmp == uc) {
            return YES;
        }
        tmp++;
    }
    
    return NO;
}

static SYTextRun* _nextTextRun(
        SYTextRunContext* runContext, 
        SYTextRun* run)
{
    // Get next text run
    SYTextRun*  nextRun;
    nextRun = SYTextRunContextNextRun(runContext, run);
    while (nextRun) {
        if (nextRun->type == SYRunTypeText || nextRun->type == SYRunTypeRubyText) {
            break;
        }
        
        nextRun = SYTextRunContextNextRun(runContext, nextRun);
    }
    
    return nextRun;
}

static float _runAdvances(
        SYTextRunContext* runContext, 
        SYTextRun* run, 
        int writingMode)
{
    // Check argument
    if (!run) {
        return 0;
    }
    
    // Calc adnvaces
    float   advances = 0;
    
    // For ruby begin
    if (run->type == SYRunTypeRubyBegin) {
        // Get ruby base advances
        SYTextRun*  textRun;
        float       textAdvances = 0;
        textRun = SYTextRunContextNextRun(runContext, run);
        while (textRun->type != SYRunTypeRubyEnd) {
            if (textRun->type == SYRunTypeText) {
                if (writingMode == SYStyleWritingModeLrTb) {
                    textAdvances += CGRectGetWidth(textRun->rect);
                }
                else if (writingMode == SYStyleWritingModeTbRl) {
                    textAdvances += CGRectGetHeight(textRun->rect);
                }
            }
            textRun = SYTextRunContextNextRun(runContext, textRun);
        }
        
        // Get ruby advances
        float   rubyAdvances = 0;
        textRun = SYTextRunContextNextRun(runContext, textRun);
        while (textRun->type != SYRunTypeRubyInlineEnd) {
            if (textRun->type == SYRunTypeRubyText) {
                rubyAdvances += CGRectGetWidth(textRun->rect);
            }
            textRun = SYTextRunContextNextRun(runContext, textRun);
        }
        
        // Use larger
        advances = textAdvances > rubyAdvances ? textAdvances : rubyAdvances;
    }
    // For text
    else if (run->type == SYRunTypeText) {
        // For horizontal
        if (writingMode == SYStyleWritingModeLrTb) {
            advances = CGRectGetWidth(run->rect);
        }
        // For vertical
        else if (writingMode == SYStyleWritingModeTbRl) {
            advances = CGRectGetHeight(run->rect);
        }
    }
    
    return advances;
}

NSArray* _tdWidthRects(
        SYTextRunContext* runContext, 
        SYTextRun* tableBeginRun, 
        float tableWidth, 
        unsigned int cellPadding, 
        unsigned int cellSpacing, 
        int writingMode)
{
    // Get td widths
    SYTextRun*      tmpRun;
    NSMutableArray* widthArrays;
    NSMutableArray* widthArray = nil;
    float           width = 0, maxWidth = 0;
    float           maxFontSize = 0;
    BOOL            inTd = NO;
    widthArrays = [NSMutableArray array];
    tmpRun = SYTextRunContextNextRun(runContext, tableBeginRun);
    while (tmpRun->type != SYRunTypeTableEnd) {
        // For tr begin
        if (tmpRun->type == SYRunTypeTrBegin) {
            // Create width array
            widthArray = [NSMutableArray array];
            [widthArrays addObject:widthArray];
        }
        // For tr end
        else if (tmpRun->type == SYRunTypeTrEnd) {
            // Clear width array
            widthArray = nil;
        }
        // For td begin
        else if (tmpRun->type == SYRunTypeTdBegin) {
            // Clear td width
            width = 0;
            
            // Set max font size
            if (tmpRun->inlineStyle->fontSize > maxFontSize) {
                maxFontSize = tmpRun->inlineStyle->fontSize;
            }
            
            // Set flag
            inTd = YES;
        }
        // For td end
        else if (tmpRun->type == SYRunTypeTdEnd) {
            // Add width
            float   w = width;
            if (maxWidth > 0) {
                w = maxWidth;
            }
            [widthArray addObject:[NSNumber numberWithFloat:w]];
            
            // Clear flag
            inTd = NO;
        }
        // For text
        else if (tmpRun->type == SYRunTypeText) {
            // For td
            if (inTd) {
                // Add td width
                if (writingMode == SYStyleWritingModeLrTb) {
                    width += CGRectGetWidth(tmpRun->rect);
                }
                else if (writingMode == SYStyleWritingModeTbRl) {
                    width += CGRectGetHeight(tmpRun->rect);
                }
            }
        }
        // For new line
        else if (tmpRun->type == SYRunTypeNewLine) {
            // Check max
            if (width > maxWidth) {
                maxWidth = width;
            }
            
            // Clear width
            width = 0;
        }
        
        // Get next run
        tmpRun = SYTextRunContextNextRun(runContext, tmpRun);
    }
    
    // Get max widths
    NSMutableArray* maxWidths;
    maxWidths = [NSMutableArray array];
    for (NSArray* array in widthArrays) {
        // Get width
        int i;
        for (i = 0; i < [array count]; i++) {
            // Get width
            float   width;
            width = [[array objectAtIndex:i] floatValue];
            
            // Get max width
            float   maxWidth;
            if (i >= [maxWidths count]) {
                [maxWidths addObject:[NSNumber numberWithFloat:0]];
            }
            maxWidth = [[maxWidths objectAtIndex:i] floatValue];
            
            // Compare with max
            if (width > maxWidth) {
                [maxWidths replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:width]];
            }
        }
    }
    
    // Calc total width
    float   totalWidth = 0;
    for (NSNumber* maxWidth in maxWidths) {
        // Add max width
        totalWidth += [maxWidth floatValue];
        
        // Add cell padding
        totalWidth += cellPadding * 2;
        
        // Add cell spacing
        if (maxWidth != [maxWidths lastObject]) {
            totalWidth += cellSpacing;
        }
    }
    
    // Decide td widths
    NSMutableArray* tdWidths;
    tdWidths = [NSMutableArray array];
    if (totalWidth <= tableWidth) {
        // Get max width
        float   x = 0;
        for (NSNumber* widthNumber in maxWidths) {
            // Create width rect
            CGRect  rect = CGRectZero;
            rect.origin.x = x;
            rect.size.width = [widthNumber floatValue];
            rect.size.width += cellPadding * 2;
            
            // Add rect
            [tdWidths addObject:[NSValue valueWithCGRect:rect]];
            
            // Move x and add spacing
            x = CGRectGetMaxX(rect);
            x += cellSpacing;
        }
    }
    else {
        // Decide min width
        float   minWidth;
        minWidth = maxFontSize + cellPadding * 2;
        
        // Get max width
        float   x = 0;
        float   totalWidthWithoutSpacing;
        totalWidthWithoutSpacing = totalWidth - cellSpacing * ([maxWidths count] - 1);
        for (NSNumber* widthNumber in maxWidths) {
            // Calc ratio
            float   ratio;
            ratio = ([widthNumber floatValue] + cellPadding * 2) / totalWidthWithoutSpacing;
            
            // Calc td width
            float   tdWidth;
            tdWidth = roundf(tableWidth * ratio);
            if (tdWidth < minWidth) {
                tdWidth = minWidth;
            }
            
            // Create width rect
            CGRect  rect = CGRectZero;
            rect.origin.x = x;
            rect.size.width = tdWidth;
            
            // Add rect
            [tdWidths addObject:[NSValue valueWithCGRect:rect]];
            
            // Move x and add spacing
            x = CGRectGetMaxX(rect);
            x += cellSpacing;
        }
        
#if 0
        // Calc evaluated td width
        float   evaluatedTdTotalWidth = 0;
        float   evaluatedTdMaxWidth = 0;
        for (NSValue* value in tdWidths) {
            CGRect  rect;
            rect = [value CGRectValue];
            evaluatedTdTotalWidth += CGRectGetWidth(rect);
            if (CGRectGetWidth(rect) > evaluatedTdMaxWidth) {
                evaluatedTdMaxWidth = CGRectGetWidth(rect);
            }
        }
        
        // For exceeded
        if (evaluatedTdTotalWidth > totalWidthWithoutSpacing) {
            // Set td width again
            NSArray*    copiedTdWidths;
            float       x = 0;
            copiedTdWidths = [NSArray arrayWithArray:tdWidths];
            [tdWidths removeAllObjects];
            for (NSValue* value in copiedTdWidths) {
                // Get rect and reset wdith
                CGRect  rect;
                rect = [value CGRectValue];
                if (CGRectGetWidth(rect) == evaluatedTdMaxWidth) {
                    rect.size.width = CGRectGetWidth(rect) - 
                            (evaluatedTdMaxWidth - totalWidthWithoutSpacing);
                }
                
                // Set x
                rect.origin.x = x;
                
                // Add rect
                [tdWidths addObject:[NSValue valueWithCGRect:rect]];
                
                // Move x and add spacing
                x = CGRectGetMaxX(rect);
                x += cellSpacing;
            }
        }
#endif
    }
    
    return tdWidths;
}

// Alphabet, number, greek, cyrillic, sign..
static BOOL _isKindOfAlphaNumeric(unichar uc)
{
    // Define exceptions
    static int _chars_ex_len = 0;
    static unichar _charsToBeExcepted[30];
    if (!_chars_ex_len) {
        _charsToBeExcepted[_chars_ex_len++] = ' ';
        _charsToBeExcepted[_chars_ex_len++] = '\n';
        _charsToBeExcepted[_chars_ex_len++] = '\r';
        _charsToBeExcepted[_chars_ex_len++] = '\t';
        _charsToBeExcepted[_chars_ex_len++] = '!';
        _charsToBeExcepted[_chars_ex_len++] = '"';
        _charsToBeExcepted[_chars_ex_len++] = '#';
        _charsToBeExcepted[_chars_ex_len++] = '$';
        _charsToBeExcepted[_chars_ex_len++] = '%';
        _charsToBeExcepted[_chars_ex_len++] = '&';
        _charsToBeExcepted[_chars_ex_len++] = '\'';
        _charsToBeExcepted[_chars_ex_len++] = ':';
        _charsToBeExcepted[_chars_ex_len++] = ';';
        _charsToBeExcepted[_chars_ex_len++] = 0x3010; // '【'
        _charsToBeExcepted[_chars_ex_len++] = 0x3011; // '】'
        _charsToBeExcepted[_chars_ex_len++] = 0x3016; // '〖'
        _charsToBeExcepted[_chars_ex_len++] = 0x3017; // '〗'
        _charsToBeExcepted[_chars_ex_len++] = 0x300a; // '《'
        _charsToBeExcepted[_chars_ex_len++] = 0x300b; // '》'
        _charsToBeExcepted[_chars_ex_len++] = 0x2192; // '→'
        _charsToBeExcepted[_chars_ex_len++] = 0x25E6; // '◦'
        _charsToBeExcepted[_chars_ex_len++] = 0x30fb; // '・'
        _charsToBeExcepted[_chars_ex_len++] = 0xFF0F; // '／'
    }
    
    // Check exception
    for (int i = 0; i < _chars_ex_len; i++) {
        if (uc == _charsToBeExcepted[i]) return NO;
    }
    
    // Define (a kind of) CJK chars
    static int _cjkCharSets_len = 0;
    static unichar _cjkCharSets[20];// [begin, end, begin, end..] of unicode
    if (!_cjkCharSets_len) {
        _cjkCharSets[_cjkCharSets_len++] = [@"⺀" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"鿋" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"가" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"舘" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"︐" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"﹫" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"𠀋" characterAtIndex:0];
        _cjkCharSets[_cjkCharSets_len++] = [@"鼖" characterAtIndex:0];
    }
    
    // Check cjk chars
    for (int i = 0; i < _cjkCharSets_len; i+=2) {
        if (uc >= _cjkCharSets[i] && uc <= _cjkCharSets[i+1]) return NO;
    }
    
    return YES;
}

BOOL _neigborRunTextIsKindOfAlphaNumeric(SYTextRun* run)
{
    // prev text run
    SYTextRun* prevRun = run;
    SYTextRun* nextRun = run;
    while ((prevRun = prevRun->prevRun)) {
        if (prevRun->type != SYRunTypeText) continue;
        
        // Check last char
        if (_isKindOfAlphaNumeric(prevRun->text[prevRun->textLength - 1])) return YES;
        else break;// Check next text run
    }
    // next text run
    while ((nextRun = nextRun->nextRun)) {
        if (nextRun->type != SYRunTypeText) continue;
        
        // Check 1st char
        return _isKindOfAlphaNumeric(nextRun->text[0]);
    }
    return NO;
}

#ifdef DEBUG_SURROGATE_PAIR
#define UNICODE_PLANE1_MIN   ((uint32_t)0x010000)                       // 1面の最初のコードポイント
#define SURROGATE_BITS  (10)                                            // サロゲート可変部分のビット数 (上位，下位共通)
#define HIGH_SURROGATE_MASK (((unichar)1 << SURROGATE_BITS) - 1)        // 上位用
#define LOW_SURROGATE_MASK  (((unichar)1 << SURROGATE_BITS) - 1)        // 下位用
#endif

@implementation SYTextLayout

// Property
@synthesize pageSize = _pageSize;

//--------------------------------------------------------------//
#pragma mark -- Layout --
//--------------------------------------------------------------//

- (void)_updateGlyphsAndRect
{
    // Create style stack
    SYTextInlineStyleStack* inlineStyleStack;
    inlineStyleStack = SYTextInlineStyleStackCreate();
    
    // Create font manager
    SYFontManager*  fontManager;
    fontManager = [[SYFontManager alloc] init];
    
    // Get runs
    SYTextRun*          run;
    SYTextInlineStyle*  inlineStyle = NULL;
    float               parentFontSize;
    BOOL                needsToUpdateFont = NO;
    CTFontRef           ctFont = NULL;
    parentFontSize = 24.0f;
    SYTextRunContextBeginIteration(_runContext);
    run = SYTextRunContextIterateNext(_runContext);
    while (run) {
        // For inline begin
        if (run->type == SYRunTypeInlineBegin || run->type == SYRunTypeRubyInlineBegin) {
            // Push inline style
            if (inlineStyle) {
                SYTextInlineStyleStackPush(inlineStyleStack, inlineStyle);
            }
            
            // Set flag
            needsToUpdateFont = YES;
            
            // Set inline style
            inlineStyle = run->inlineStyle;
            
            // Go next run
            goto nextRun;
        }
        
        // For inline end
        else if (run->type == SYRunTypeInlineEnd || run->type == SYRunTypeRubyInlineEnd) {
            // Pop inline style
            SYTextInlineStyle*  poppedInlineStyle;
            poppedInlineStyle = SYTextInlineStyleStackPop(inlineStyleStack);
            
            // Set flag
            needsToUpdateFont = YES;
            
            // Set popped inline style
            inlineStyle = poppedInlineStyle;
            
            // Go next run
            goto nextRun;
        }
        
        // For not text and ruby
        else if (run->type != SYRunTypeText && run->type != SYRunTypeRubyText) {
            // Go next run
            goto nextRun;
        }
        
        // Update font
        if (needsToUpdateFont) {
            // Get CTFont
            ctFont = [fontManager ctFontWithStyle:inlineStyle character:*(run->text)];
            
            // Set ascent and descent
            inlineStyle->ascent = (((int)(CTFontGetAscent(ctFont) * 1000) + 5) / 10) / 100.0f; // round
            inlineStyle->descent = (((int)(CTFontGetDescent(ctFont) * 1000) + 5) / 10) / 100.0f; // round
            
            // For Hiragino, double descent
            // Becase descent value of Hiragino is too low
            if (run->type != SYRunTypeRubyText) {
                inlineStyle->descent *= 2.0f;
            }
            
            // Clear flag
            needsToUpdateFont = NO;
        }
        
        //
        // Glyph
        //
        
        // Check glyph buffer
        if (!run->glyphs) {
            if (run->textLength <= SY_RUN_TEXTBUFFER_MAX) {
                // Set internal glyph buffer as glyphs
                run->glyphs = run->glyphBuffer;
            }
            else {
                // Allocate glyph buffer
                CGGlyph*    glyphBuffer;
                glyphBuffer = malloc(sizeof(CGGlyph) * run->textLength);
                
                // Set external glyph buffer as glyphs
                run->glyphs = glyphBuffer;
            }
            
            // For Surrogate Pair
            if (run->textLength == 2 && (0xd800 <= *run->text && *run->text <= 0xdbff)) {
                
                // SYTextParser _nextToken()でトークン分割した際、*(run->text + 1)は、
                // 必ず Low Surrogateの値になっているので、範囲のチェックをしない
                
#ifdef DEBUG_SURROGATE_PAIR
                if (0xdc00 <= *(run->text + 1) && *(run->text + 1) <= 0xdfff) {
                    NSLog(@"surrogate pair: low");
                }
#endif
                
#ifdef DEBUG_SURROGATE_PAIR
                unichar high = *run->text;
                unichar low  = *(run->text + 1);
                
                NSLog(@"surrogate pair|high=0x%x|low=0x%x|len=%d", *run->text, *(run->text + 1), run->textLength);
                
                // Decode unicode value
                uint32_t value = 0;
                value = ((high & (uint32_t)HIGH_SURROGATE_MASK) << SURROGATE_BITS) + (low & (uint32_t)LOW_SURROGATE_MASK) + UNICODE_PLANE1_MIN;
                
                NSLog(@"value=0x%x", value);
#endif
                
                // Get glyphs
                CTFontGetGlyphsForCharacters(ctFont, run->text, run->glyphs, 2);
                
#ifdef DEBUG_SURROGATE_PAIR
                NSLog(@"glyph=%d", *run->glyphs);
#endif
                // run->textLengthは 2 だが、グリフは1つ
                run->glyphLength = 1;
            }
            else {
                // Get glyphs
                CTFontGetGlyphsForCharacters(
                    ctFont, run->text, run->glyphs, run->textLength);
                run->glyphLength = run->textLength;
            }
            
            // For vertical
            if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                BOOL needsToSubst = YES;
                BOOL forceSubst = NO;
                
                // For length 1
                if (run->textLength == 1 && !inlineStyle->originalSpelling) {
                    if (_isKindOfAlphaNumeric(run->text[0])) {
                        unichar fullWidthAlphaNumeric;

                        // Check neighbors
                        if (_neigborRunTextIsKindOfAlphaNumeric(run)) {
                            forceSubst = YES;
                        }
                        // Use full width alpha numeric
                        else if ((fullWidthAlphaNumeric = _getFullWidthAlphaNumeric(run->text[0])) > 0) {
                            CTFontGetGlyphsForCharacters(
                                                         ctFont, &fullWidthAlphaNumeric, run->glyphs, run->textLength);
                            
                            // Set flag
                            needsToSubst = NO;
                        }
                    }
                }
                else if (run->textLength >= 2 && !inlineStyle->originalSpelling && _isKindOfAlphaNumeric(run->text[0])) {
                    if (_neigborRunTextIsKindOfAlphaNumeric(run)) {
                        forceSubst = YES;
                    }
                    // Tatechuyoko
                    else if (run->textLength == 2) {
                        // For alpha numeric
                        CGGlyph glyph0, glyph1;
                        glyph0 = _getHalfWidthNumericGlyph(run->text[0]);
                        glyph1 = _getHalfWidthNumericGlyph(run->text[1]);
                        if (glyph0 && glyph1) {
                            // Use half width alpha numeric
                            run->glyphs[0] = glyph0;
                            run->glyphs[1] = glyph1;
                            
                            // Set flag
                            needsToSubst = NO;
                        }
                    }
                }
                
                
                // Get subst
                if (needsToSubst || forceSubst) {
                    // Create rotate flags
                    BOOL* rotateFlags = NULL;
                    BOOL  rotated = NO;
                    if (forceSubst) {
                        size_t size = sizeof(BOOL) * run->glyphLength;
                        rotateFlags = (BOOL*)malloc(size);
                        memset(rotateFlags, 0, size);
                    }
                    
                    for (int i = 0; i < run->textLength; i++) {
                        CGGlyph substGlyph;
                        substGlyph = SYTextVerticalSubstitutionGlyphWithGlyph(@"HiraMinProN-W3", run->glyphs[i]);
                        // Set substituted glyph
                        if (substGlyph > 0 && substGlyph != run->glyphs[i]) {
                            run->glyphs[i] = substGlyph;
                        }
                        // Rotete programmatically when draw
                        else if (forceSubst) {
                            // Set flag
                            rotated = YES;
                            rotateFlags[i] = YES;
                            
                            // exchange width and height
                            float tmp = run->rect.size.width;
                            run->rect.size.width = run->rect.size.height;
                            run->rect.size.height = tmp;
                        }
                    }
                    
                    // Check rotated
                    if (rotated) {
                        // Be sure to free rotateFlags when run context is released!!
                        run->rotateFlags = rotateFlags;
                    }
                    else if (rotateFlags) free(rotateFlags);
                }
            }
        }
        
        //
        // Advance
        //
        
        // Check advance buffer
        if (run->textLength <= SY_RUN_TEXTBUFFER_MAX) {
            // Set internal advance buffer as advances
            run->advances = run->advanceBuffer;
        }
        else {
            // Allocate advance buffer
            CGSize* advanceBuffer;
            advanceBuffer = malloc(sizeof(CGSize) * run->glyphLength);
            
            // Set external advance buffer as advances
            run->advances = advanceBuffer;
        }
        
        // Get advance for tate-chu-yoko
        double  advance = 0;
        if (SYTextLayoutIsTateChuYoko(run, inlineStyle)) {
            // Get advance for one char
            advance = CTFontGetAdvancesForGlyphs(
                    ctFont, kCTFontVerticalOrientation, run->glyphs, run->advances, 1);
        }
        // Get advance for other
        else {
            CTFontOrientation   orientation;
            orientation = inlineStyle->writingMode == SYStyleWritingModeLrTb ? 
                    kCTFontHorizontalOrientation : kCTFontVerticalOrientation;
#if 0
            advance = SYFontGetAdvancesForGlyphs(
                    ctFont, orientation, run->glyphs, run->advances, run->glyphLength);
#else
            advance = CTFontGetAdvancesForGlyphs(
                    ctFont, orientation, run->glyphs, run->advances, run->glyphLength);
#endif
        }
        
        // Set width and height for horizontal
        if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
            run->rect.size.width = advance;
            run->rect.size.height = inlineStyle->descent + inlineStyle->ascent;
        }
        // Set width and height for vertical
        else if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
            run->rect.size.width = inlineStyle->descent + inlineStyle->ascent;
            run->rect.size.height = advance;
        }
        
        // Set punctuation
        if (run->textLength == 1) {
            run->punctuation = _getPunctuationType(*(run->text));
        }
        else {
            run->punctuation = SYPunctuationWhole;
        }
        
        // For not whole punctuation
        if (run->punctuation != SYPunctuationWhole) {
            // For horizontal
            if (inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                run->rect.size.width = CGRectGetWidth(run->rect) * 0.5f;
            }
            // For vertical
            else if (inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                run->rect.size.height = CGRectGetHeight(run->rect) * 0.5f;
            }
        }
        
        nextRun: {
            // Get next run
            run = SYTextRunContextIterateNext(_runContext);
        }
    }
    
    // Free style stack
    SYTextInlineStyleStackRelease(inlineStyleStack);
}

- (void)_updateBlockRects
{
    // Update block rects
    SYTextRun*  run;
    SYTextRun*  blockBeginRuns[128];
    SYTextRun** currentBlockBeginRun;
    CGRect      blockRects[128];
    CGRect*     currentBlockRect;
    BOOL        hasTable = NO, inTable = NO;
    currentBlockBeginRun = NULL;
    currentBlockRect = NULL;
    SYTextRunContextBeginIteration(_runContext);
    run = SYTextRunContextIterateNext(_runContext);
    while (run) {
//NSLog(@"runId %d, type %d, text %@, rect %@", run->runId, run->type, SYTextRunStringWithRun(run), NSStringFromCGRect(run->rect));
        // For block begin
        if (run->type == SYRunTypeBlockBegin && !inTable) {
            // Push current begin run
            if (!currentBlockBeginRun) {
                currentBlockBeginRun = blockBeginRuns;
            }
            else {
                if (currentBlockBeginRun > blockBeginRuns + sizeof(blockBeginRuns) / sizeof(SYTextRun*)) {
                    NSLog(@"Exceed block begin runs");
                    
                    break;
                }
                currentBlockBeginRun++;
            }
            *currentBlockBeginRun = run;
            
            // Push current block rect
            if (!currentBlockRect) {
                currentBlockRect = blockRects;
            }
            else {
                if (currentBlockRect > blockRects + sizeof(blockRects) / sizeof(CGRect)) {
                    NSLog(@"Exceed block rects");
                    
                    break;
                }
                currentBlockRect++;
            }
            
            // Clear current block rect
            *currentBlockRect = CGRectZero;
        }
        // For block end
        else if (run->type == SYRunTypeBlockEnd && !inTable) {
            // Calc rect with margin
            CGRect  extendedRect;
            float   wide;
            float   top = 0, right = 0, bottom = 0, left = 0;
            extendedRect = *currentBlockRect;
            wide = CGRectGetWidth(extendedRect);
            if (run->blockStyle->marginTop > 0) {
                top = SYStyleMarginTop(run->blockStyle, run->inlineStyle, wide);
            }
            if (run->blockStyle->marginRight > 0) {
                right = SYStyleMarginRight(run->blockStyle, run->inlineStyle, wide);
            }
            if (run->blockStyle->marginBottom > 0) {
                bottom = SYStyleMarginBottom(run->blockStyle, run->inlineStyle, wide);
            }
            if (run->blockStyle->marginLeft > 0) {
                left = SYStyleMarginLeft(run->blockStyle, run->inlineStyle, wide);
            }
            
            // Extend rect
            if (run->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                extendedRect.origin.x -= left;
                extendedRect.origin.y -= top;
                extendedRect.size.width += left + right;
                extendedRect.size.height += top + bottom;
            }
            else if (run->inlineStyle->writingMode == SYStyleWritingModeTbRl &&
                     (*currentBlockBeginRun)->numberOfColumnBreaks == 0)
            {
                extendedRect.origin.x -= bottom;
                extendedRect.origin.y -= left;
                extendedRect.size.width += bottom + top;
                extendedRect.size.height += left + right;
            }
            
//NSLog(@"runId %d, extendedRect %@, inTd %d", run->runId, NSStringFromCGRect(extendedRect), inTd);
            // Set block run rect
            run->rect = extendedRect;
            (*currentBlockBeginRun)->rect = extendedRect;
            
            // Pop current block begin run
            currentBlockBeginRun--;
            
            // Pop current block rect
            if (currentBlockRect > blockRects) {
                currentBlockRect--;
            }
            else {
                currentBlockRect = NULL;
            }
            
            // Union rect
            if (currentBlockRect) {
                if (CGRectIsEmpty(*currentBlockRect)) {
                    *currentBlockRect = run->rect;
                }
                else {
                    *currentBlockRect = CGRectUnion(run->rect, *currentBlockRect);
                }
            }
        }
        // For text and image
        else if (run->type == SYRunTypeText || run->type == SYRunTypeImage) {
            // Check run rect
            if (!CGRectIsEmpty(run->rect)) {
                // Union rect
                if (CGRectIsEmpty(*currentBlockRect)) {
                    *currentBlockRect = run->rect;
                }
                else {
                    *currentBlockRect = CGRectUnion(run->rect, *currentBlockRect);
                }
            }
        }
        // For table begin
        else if (run->type == SYRunTypeTableBegin) {
            // Set flag
            hasTable = YES;
            inTable = YES;
        }
        // For table end
        else if (run->type == SYRunTypeTableEnd) {
            // Set flag
            inTable = NO;
        }
        
        // Get next run
        run = SYTextRunContextIterateNext(_runContext);
    }
    
    // For has table
    if (hasTable) {
        // Update block rects agein for table
        SYTextRun*  tableBlockBeginRun;
        SYTextRun*  tdBlockBeginRuns[128];
        SYTextRun*  tdBlockEndRuns[128];
        SYTextRun** currentTdBlockBeginRun;
        SYTextRun** currentTdBlockEndRun;
        BOOL        inTable, inTr, inTd;
        float       maxX;
        tableBlockBeginRun = NULL;
        currentTdBlockBeginRun = NULL;
        currentTdBlockEndRun = NULL;
        inTable = NO, inTr = NO, inTd = NO;
        maxX = 0;
        SYTextRunContextBeginIteration(_runContext);
        run = SYTextRunContextIterateNext(_runContext);
        while (run) {
//NSLog(@"runId %d, type %d, text %@, rect %@", run->runId, run->type, SYTextRunStringWithRun(run), NSStringFromCGRect(run->rect));
            // For block begin
            if (run->type == SYRunTypeBlockBegin) {
                // For block in table
                if (inTable && !inTr && !inTd) {
                    // Set table block begin run
                    tableBlockBeginRun = run;
                }
                // For block in td
                else if (inTable && inTr && inTd) {
                    // Push current block begin run
                    if (!currentTdBlockBeginRun) {
                        currentTdBlockBeginRun = tdBlockBeginRuns;
                    }
                    else {
                        if (currentTdBlockBeginRun > tdBlockBeginRuns + sizeof(tdBlockBeginRuns) / sizeof(SYTextRun*)) {
                            NSLog(@"Exceed td begin runs");
                            
                            break;
                        }
                        currentTdBlockBeginRun++;
                    }
                    *currentTdBlockBeginRun = run;
                }
            }
            // For block end
            else if (run->type == SYRunTypeBlockEnd) {
                // For block in table
                if (inTable && !inTr && !inTd) {
                    // Calc width with max X
                    run->rect.size.width = maxX - CGRectGetMinX(run->rect);
                    if (tableBlockBeginRun) {
                        tableBlockBeginRun->rect.size.width = CGRectGetWidth(run->rect);
                    }
                }
                // For block in td
                else if (inTable && inTr && inTd) {
                    // Push current block end run
                    if (!currentTdBlockEndRun) {
                        currentTdBlockEndRun = tdBlockEndRuns;
                    }
                    else {
                        if (currentTdBlockEndRun > tdBlockEndRuns + sizeof(tdBlockEndRuns) / sizeof(SYTextRun*)) {
                            NSLog(@"Exceed td end runs");
                            
                            break;
                        }
                        currentTdBlockEndRun++;
                    }
                    *currentTdBlockEndRun = run;
                }
            }
            // For table begin
            else if (run->type == SYRunTypeTableBegin) {
                // Set flag
                inTable = YES;
                tableBlockBeginRun = NULL;
            }
            // For table end
            else if (run->type == SYRunTypeTableEnd) {
                // Clear flag
                inTable = NO;
                tableBlockBeginRun = NULL;
            }
            // For tr begin
            else if (run->type == SYRunTypeTrBegin) {
                // Reset td begin runs
                currentTdBlockBeginRun = NULL;
                currentTdBlockEndRun = NULL;
                
                // Set flag
                inTr = YES;
            }
            // For tr end
            else if (run->type == SYRunTypeTrEnd) {
                // For horizontal
                if (run->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                    // Get td runs max size
                    int     i;
                    float   maxHeight = 0;
                    for (i = 0; i <= currentTdBlockBeginRun - tdBlockBeginRuns; i++) {
                        // Get block begin run
                        SYTextRun*  blockBeginRun;
                        blockBeginRun = tdBlockBeginRuns[i];
                        
                        // Get height
                        float   height;
                        height = CGRectGetHeight(blockBeginRun->rect);
                        
                        // Decide max height
                        if (height > maxHeight) {
                            maxHeight = height;
                        }
                    }
                    
                    // Set max height to blocks
                    for (i = 0; i <= currentTdBlockBeginRun - tdBlockBeginRuns; i++) {
                        // Get block begin and end run
                        SYTextRun*  blockBeginRun;
                        SYTextRun*  blockEndRun;
                        blockBeginRun = tdBlockBeginRuns[i];
                        blockEndRun = tdBlockEndRuns[i];
                        
                        // Set max height
                        blockBeginRun->rect.size.height = maxHeight;
                        blockEndRun = blockBeginRun;
                        
                        // Set max X
                        if (CGRectGetMaxX(blockBeginRun->rect) > maxX) {
                            maxX = CGRectGetMaxX(blockBeginRun->rect);
                        }
                    }
                }
                // For vertical
                else if (run->inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                    // Get td runs max size
                    int     i;
                    float   maxWidth = 0;
                    for (i = 0; i <= currentTdBlockBeginRun - tdBlockBeginRuns; i++) {
                        // Get block begin run
                        SYTextRun*  blockBeginRun;
                        blockBeginRun = tdBlockBeginRuns[i];
                        
                        // Get width
                        float   width;
                        width = CGRectGetWidth(blockBeginRun->rect);
                        
                        // Decide max width
                        if (width > maxWidth) {
                            maxWidth = width;
                        }
                    }
                    
                    // Set max width to blocks
                    for (i = 0; i <= currentTdBlockBeginRun - tdBlockBeginRuns; i++) {
                        // Get block begin and end run
                        SYTextRun*  blockBeginRun;
                        SYTextRun*  blockEndRun;
                        blockBeginRun = tdBlockBeginRuns[i];
                        blockEndRun = tdBlockEndRuns[i];
                        
                        // Set width as max
                        float   maxX;
                        maxX = CGRectGetMaxX(blockBeginRun->rect);
                        blockBeginRun->rect.size.width = maxWidth;
                        blockBeginRun->rect.origin.x = maxX - maxWidth;
                        blockEndRun = blockBeginRun;
                    }
                }
                
                // Clear flag
                inTr = NO;
            }
            // For td begin
            else if (run->type == SYRunTypeTdBegin) {
                // Set flag
                inTd = YES;
            }
            // For td end
            else if (run->type == SYRunTypeTdEnd) {
                // Clear flag
                inTd = NO;
            }
            
if (inTable) {
//NSLog(@"runId %d, type %d, text %@, rect %@", run->runId, run->type, SYTextRunStringWithRun(run), NSStringFromCGRect(run->rect));
}
            // Get next run
            run = SYTextRunContextIterateNext(_runContext);
        }
    }
}

NSString* NSStringFromRunType(unsigned char type)
{
    switch (type) {
    case SYRunTypeText              : return @"SYRunTypeText";
    case SYRunTypeBlockBegin        : return @"SYRunTypeBlockBegin";
    case SYRunTypeBlockEnd          : return @"SYRunTypeBlockEnd";
    case SYRunTypeInlineBegin       : return @"SYRunTypeInlineBegin";
    case SYRunTypeInlineEnd         : return @"SYRunTypeInlineEnd";
    case SYRunTypeNewLine           : return @"SYRunTypeNewLine";
    case SYRunTypeAnchor            : return @"SYRunTypeAnchor";
    case SYRunTypeImage             : return @"SYRunTypeImage";
    case SYRunTypeRubyBegin         : return @"SYRunTypeRubyBegin";
    case SYRunTypeRubyEnd           : return @"SYRunTypeRubyEnd";
    case SYRunTypeRubyText          : return @"SYRunTypeRubyText";
    case SYRunTypeRubyInlineBegin   : return @"SYRunTypeRubyInlineBegin";
    case SYRunTypeRubyInlineEnd     : return @"SYRunTypeRubyInlineEnd";
    case SYRunTypeTableBegin        : return @"SYRunTypeTableBegin";
    case SYRunTypeTableEnd          : return @"SYRunTypeTableEnd";
    case SYRunTypeTrBegin           : return @"SYRunTypeTrBegin";
    case SYRunTypeTrEnd             : return @"SYRunTypeTrEnd";
    case SYRunTypeTdBegin           : return @"SYRunTypeTdBegin";
    case SYRunTypeTdEnd             : return @"SYRunTypeTdEnd";
    }
    
    return @"";
}

NSString* NSStringFromVerticalAlign(unsigned short va)
{
    switch (va) {
    case SYStyleVerticalAlignBaseLine   : return @"SYStyleVerticalAlignBaseLine";
    case SYStyleVerticalAlignBottom     : return @"SYStyleVerticalAlignBottom";
    case SYStyleVerticalAlignMiddle     : return @"SYStyleVerticalAlignMiddle";
    case SYStyleVerticalAlignSub        : return @"SYStyleVerticalAlignSub";
    case SYStyleVerticalAlignSuper      : return @"SYStyleVerticalAlignSuper";
    case SYStyleVerticalAlignTextBottom : return @"SYStyleVerticalAlignTextBottom";
    case SYStyleVerticalAlignTextTop    : return @"SYStyleVerticalAlignTextTop";
    case SYStyleVerticalAlignTop        : return @"SYStyleVerticalAlignTop";
    }

    return @"";
}

NSString* NSStringFromFontSizeUnit(unsigned char unit)
{
    switch (unit) {
    case SYStyleUnitCM      : return @"SYStyleUnitCM";
    case SYStyleUnitDEG     : return @"SYStyleUnitDEG";
    case SYStyleUnitEM      : return @"SYStyleUnitEM";
    case SYStyleUnitEX      : return @"SYStyleUnitEX";
    case SYStyleUnitGRAD    : return @"SYStyleUnitGRAD";
    case SYStyleUnitHZ      : return @"SYStyleUnitHZ";
    case SYStyleUnitIN      : return @"SYStyleUnitIN";
    case SYStyleUnitKHZ     : return @"SYStyleUnitKHZ";
    case SYStyleUnitMM      : return @"SYStyleUnitMM";
    case SYStyleUnitMS      : return @"SYStyleUnitMS";
    case SYStyleUnitPC      : return @"SYStyleUnitPC";
    case SYStyleUnitPCT     : return @"SYStyleUnitPCT";
    case SYStyleUnitPT      : return @"SYStyleUnitPT";
    case SYStyleUnitPX      : return @"SYStyleUnitPX";
    case SYStyleUnitRAD     : return @"SYStyleUnitRAD";
    case SYStyleUnitS       : return @"SYStyleUnitS";
    }
    return @"";
}

static  float   _maxSize = 2048.0f;

- (void)_layoutWithParser:(SYTextParser*)parser
{
//NSLog(@"%s, _pageSize %@, html %@", __PRETTY_FUNCTION__, NSStringFromCGSize(_pageSize), [[NSString alloc] initWithData:parser.htmlData encoding:NSUTF8StringEncoding]);
    float   x = MAXFLOAT, y = MAXFLOAT, endX = 0, endY = 0;
    
    // Get number of lines
    int numberOfLines;
    numberOfLines = parser.numberOfLines;
    
    // Decide page size
    CGSize  pageSize;
    pageSize = _pageSize;
    if (pageSize.width == 0) {
        pageSize.width = _maxSize;
    }
    if (pageSize.height == 0) {
        pageSize.height = _maxSize;
    }
    
    // Initialize min and max
    if (parser.writingMode == SYStyleWritingModeLrTb) {
        _minX = 0;
        _maxX = pageSize.width;
        _minY = 0;
        _maxY = pageSize.height;
    }
    else if (parser.writingMode == SYStyleWritingModeTbRl) {
        _minX = 0;
        _maxX = pageSize.width;
        _minY = 0;
        if (parser.rowHeightForVertical > 0) {
            _maxY = parser.rowHeightForVertical;
        }
        else {
            _maxY = pageSize.height;
        }
    }
    
    // Create stack
    SYTextRunStack* blockRunStack;
    SYTextRunStack* inlineRunStack;
    blockRunStack = SYTextRunStackCreate();
    inlineRunStack = SYTextRunStackCreate();
    
    // Get runs
    SYTextRun*  run;
    SYTextRun*  currentBlockRun = NULL;
    SYTextRun*  currentInlineRun = NULL;
    int         currentWritingMode = SYStyleWritingModeLrTb;
    SYTextRun*  lineBeginRun = NULL;
    int         lineCount = 0;
    int         columnBreakCount;
    NSArray*    tdWidthRects = nil;
    int         tdIndex = 0;
    float       tableMinX= MAXFLOAT, tableMaxX = MAXFLOAT;
    float       tableMinY = MAXFLOAT, tableMaxY = MAXFLOAT;
    int         tableCellPadding = 0, tableCellSpacing = 0;
    float       trX, trY;
    BOOL        inTable = NO, inTd = NO, inTr = NO, trRollbacked = NO;
    SYTextRunContextBeginIteration(_runContext);
    run = SYTextRunContextIterateNext(_runContext);
    while (run) {
//NSLog(@"runId %d, %@, %@, runRect %@", run->runId, NSStringFromRunType(run->type), SYTextRunStringWithRun(run), NSStringFromCGRect(run->rect));
        // For max line number
        if (numberOfLines > 0 && lineCount >= numberOfLines) {
            // Set empty rect
            run->rect = CGRectZero;
            
            // Go next run
            goto nextRun;
        }
        
        // Check last line
        BOOL    lastLine, lastText = NO, exceeded = NO;
        lastLine = numberOfLines > 0 && lineCount >= numberOfLines - 1;
        
        // ------------------------------------------------------------ //
        #pragma mark ├ Block begin
        // ------------------------------------------------------------ //
        
        // For block begin
        if (run->type == SYRunTypeBlockBegin) {
            // Push block run
            if (currentBlockRun) {
                SYTextRunStackPush(blockRunStack, currentBlockRun);
            }
            
            // Set block run
            currentBlockRun = run;
            
            // Set block run as inline run
            currentInlineRun = run;
            currentWritingMode = currentInlineRun->inlineStyle->writingMode;
            
            // Get current block style and inline style
            SYTextBlockStyle*   blkStyle;
            SYTextInlineStyle*  inlStyle;
            blkStyle = currentBlockRun->blockStyle;
            inlStyle = currentBlockRun->inlineStyle;
            
            // For horizontal
            if (currentBlockRun->blockStyle->writingMode == SYStyleWritingModeLrTb) {
                // Reset initial x and y
                if (x == MAXFLOAT && y == MAXFLOAT) {
                    x = 0;
                    y = 0;
                }
                
                // Calc wide
                float   wide;
                wide = _maxX - _minX;
                
                // Calc border width
                blkStyle->borderTop.width = SYStyleCalcUnitValue(
                        blkStyle->borderTop.value, blkStyle->borderTop.unit, wide, inlStyle->fontSize);
                blkStyle->borderLeft.width = SYStyleCalcUnitValue(
                        blkStyle->borderLeft.value, blkStyle->borderLeft.unit, wide, inlStyle->fontSize);
                blkStyle->borderRight.width = SYStyleCalcUnitValue(
                        blkStyle->borderRight.value, blkStyle->borderRight.unit, wide, inlStyle->fontSize);
                blkStyle->borderBottom.width = SYStyleCalcUnitValue(
                        blkStyle->borderBottom.value, blkStyle->borderBottom.unit, wide, inlStyle->fontSize);
                
                // Set block run rect origin and width
                currentBlockRun->rect.origin.x = x + SYStyleMarginLeft(blkStyle, inlStyle, wide);
                currentBlockRun->rect.origin.y = y + SYStyleMarginTop(blkStyle, inlStyle, wide);
                currentBlockRun->rect.size.width = 0;
                currentBlockRun->rect.size.width = 
                        _maxX - CGRectGetMinX(currentBlockRun->rect) - SYStyleMarginRight(blkStyle, inlStyle, wide);
                currentBlockRun->rect.size.height = 0;
                
                // Calc min x and max x
                _minX = CGRectGetMinX(currentBlockRun->rect) + 
                        SYStylePaddingLeft(blkStyle, inlStyle, wide) + 
                        blkStyle->borderLeft.width;
                _maxX = CGRectGetMaxX(currentBlockRun->rect) - 
                        SYStylePaddingRight(blkStyle, inlStyle, wide) - 
                        blkStyle->borderRight.width;
                endX = _maxX;
                
                // Move x and y
                x = _minX;
                y = CGRectGetMinY(currentBlockRun->rect) + SYStylePaddingTop(blkStyle, inlStyle, wide) + 
                        blkStyle->borderTop.width;
                
                // For begin block for tr begin
                if (inTable && inTr && !inTd) {
                    // Set tr x and y
                    trX = x;
                    trY = y;
                }
                
                // For begin block for td begin
                if (inTable && inTr && inTd) {
                    // Add cell padding
                    endX -= tableCellPadding;
                    x += tableCellPadding;
                    y += tableCellPadding;
                }
            }
            // For vertical
            else if (currentBlockRun->blockStyle->writingMode == SYStyleWritingModeTbRl) {
                // Reset initial x and y
                if (x == MAXFLOAT && y == MAXFLOAT) {
                    x = pageSize.width;
                    y = 0;
                }
                
                // Reset paragraph break count
                columnBreakCount = 0;
                
                // Set block run rect origin and width
                float   wide;
                wide = _maxY - _minY;
                currentBlockRun->rect.origin.x = x - SYStyleMarginTop(blkStyle, inlStyle, wide);
                currentBlockRun->rect.origin.y = y + SYStyleMarginLeft(blkStyle, inlStyle, wide);
                currentBlockRun->rect.size.width = 0;
                currentBlockRun->rect.size.height = 
                        _maxY - CGRectGetMinY(currentBlockRun->rect) - SYStyleMarginRight(blkStyle, inlStyle, wide);
                
                // Calc min y and max y
                _minY = CGRectGetMinY(currentBlockRun->rect) + SYStylePaddingLeft(blkStyle, inlStyle, wide);
                _maxY = CGRectGetMaxY(currentBlockRun->rect) - SYStylePaddingRight(blkStyle, inlStyle, wide);
                endY = _maxY;
                
                // Move x and y
                x = CGRectGetMaxX(currentBlockRun->rect) - SYStylePaddingTop(blkStyle, inlStyle, wide);
                y = _minY;
                
                // For begin block for td begin
                if (inTable && inTr && inTd) {
                    // Add cell padding
                    endY -= tableCellPadding;
                    x -= tableCellPadding;
                    y += tableCellPadding;
                }
            }
            
            // Go next line
            goto nextLine;
        }
        
        // ------------------------------------------------------------ //
        #pragma mark ├ Block end
        // ------------------------------------------------------------ //
        
        // For block end
        else if (run->type == SYRunTypeBlockEnd) {
            // Set block run as inline run
            currentInlineRun = run;
            currentWritingMode = currentInlineRun->inlineStyle->writingMode;

            // Clear margin and padding for currentBlock
            float wide;
            if (run->blockStyle->writingMode == SYStyleWritingModeLrTb) {
                wide = _maxX - _minX;
                _minX -= (SYStyleMarginLeft(run->blockStyle, run->inlineStyle, wide) + SYStylePaddingLeft(run->blockStyle, run->inlineStyle, wide));
                _maxX += (SYStyleMarginRight(run->blockStyle, run->inlineStyle, wide) + SYStylePaddingRight(run->blockStyle, run->inlineStyle, wide));
            }
            else if (run->blockStyle->writingMode == SYStyleWritingModeTbRl) {
                wide = _maxY - _minY;
                _minY -= (SYStyleMarginLeft(run->blockStyle, run->inlineStyle, wide) + SYStylePaddingLeft(run->blockStyle, run->inlineStyle, wide));
                _maxY += (SYStyleMarginRight(run->blockStyle, run->inlineStyle, wide) + SYStylePaddingRight(run->blockStyle, run->inlineStyle, wide));
            }
            
            // Go next line
            goto nextLine;
        }
        
        // ------------------------------------------------------------ //
        #pragma mark ├ Inline begin
        // ------------------------------------------------------------ //
        
        // For linline begin
        else if (run->type == SYRunTypeInlineBegin) {
            // Push inline run
            if (currentInlineRun) {
                SYTextRunStackPush(inlineRunStack, currentInlineRun);
            }
                
            // Set inline run
            currentInlineRun = run;
            currentWritingMode = currentInlineRun->inlineStyle->writingMode;
            
            // Get current inline style
            SYTextInlineStyle*  inlStyle;
            inlStyle = currentInlineRun->inlineStyle;
            
            // Calc wide
            float   wide;
            wide = _maxX - _minX;
            
            // Calc border width
            inlStyle->borderTop.width = SYStyleCalcUnitValue(
                    inlStyle->borderTop.value, inlStyle->borderTop.unit, wide, inlStyle->fontSize);
            inlStyle->borderLeft.width = SYStyleCalcUnitValue(
                    inlStyle->borderLeft.value, inlStyle->borderLeft.unit, wide, inlStyle->fontSize);
            inlStyle->borderRight.width = SYStyleCalcUnitValue(
                    inlStyle->borderRight.value, inlStyle->borderRight.unit, wide, inlStyle->fontSize);
            inlStyle->borderBottom.width = SYStyleCalcUnitValue(
                    inlStyle->borderBottom.value, inlStyle->borderBottom.unit, wide, inlStyle->fontSize);
            
            // Go next run
            goto nextRun;
        }
        
        // ------------------------------------------------------------ //
        #pragma mark ├ Inline end
        // ------------------------------------------------------------ //
        
        // For linline end
        else if (run->type == SYRunTypeInlineEnd) {
            // Pop inline run
            SYTextRun*  poppedInlineRun;
            poppedInlineRun = SYTextRunStackPop(inlineRunStack);
            
            // Set popped inline run
            currentInlineRun = poppedInlineRun;
            if (currentInlineRun) {
                currentWritingMode = currentInlineRun->inlineStyle->writingMode;
            }
            
            // Go next run
            goto nextRun;
        }
        
        // ------------------------------------------------------------ //
        #pragma mark ├ Table begin
        // ------------------------------------------------------------ //
        
        // For table begin
        else if (run->type == SYRunTypeTableBegin) {
            // Set cell padding and spacing
            tableCellPadding = run->blockStyle->tableCellPadding;
            tableCellSpacing = run->blockStyle->tableCellSpacing;
            
            // For horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                // Set table min X and max X
                tableMinX = _minX;
                tableMaxX = _maxX;
                
                // Calc td widths
                tdWidthRects = _tdWidthRects(
                        _runContext, 
                        run, 
                        tableMaxX - tableMinX, 
                        tableCellPadding, 
                        tableCellSpacing, 
                        currentWritingMode);
            }
            // For vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Set table min Y and max Y
                tableMinY = _minY;
                tableMaxY = _maxY;
                
                // Calc td widths
                tdWidthRects = _tdWidthRects(
                        _runContext, 
                        run, 
                        tableMaxY - tableMinY, 
                        tableCellPadding, 
                        tableCellSpacing, 
                        currentWritingMode);
            }
            
            // Set flag
            inTable = YES;
            
            // Go next run
            goto nextRun;
        }
        
        // For table end
        else if (run->type == SYRunTypeTableEnd) {
            // For horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                // Reset min X and max X
                _minX = tableMinX;
                _maxX = tableMaxX;
            }
            // For vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Reset min Y and max Y
                _minY = tableMinY;
                _maxY = tableMaxY;
            }
            
            // Reset table min and max
            tableMinX = MAXFLOAT;
            tableMaxX = MAXFLOAT;
            tableMinY = MAXFLOAT;
            tableMaxY = MAXFLOAT;
            
            // Go next column for vertical
            if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Set min and max Y
                _minY = _maxY + parser.rowMarginForVertical;
                _maxY = _minY + parser.rowHeightForVertical;
                
                // Set X and Y
                x = _maxX;
                y = _minY;
                
                // Update end y
                endY = _maxY;
                
                // Increment column break count
                columnBreakCount++;
            }
            
            // Clear flag
            inTable = NO;
            
            // Go next line
            goto nextLine;
        }
        
        // For tr begin
        else if (run->type == SYRunTypeTrBegin) {
            // Reset td index
            tdIndex = 0;
            
            // For horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                // Set tr Y
                trY = y;
            }
            // For vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Set tr X
                trX = x;
            }
            
            // Set flag
            inTr = YES;
            
            // Go next run
            goto nextRun;
        }
        
        // For tr end
        else if (run->type == SYRunTypeTrEnd) {
            // For horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                // Reset min X and max X
                _minX = tableMinX;
                _maxX = tableMaxX;
                
                // Set Y to max Y in td
                SYTextRun*  tmpRun;
                float       maxY = 0;
                tmpRun = SYTextRunContextPrevRun(_runContext, run);
                while (tmpRun->type != SYRunTypeTrBegin) {
                    if (tmpRun->type == SYRunTypeBlockBegin) {
                        if (CGRectGetMaxY(tmpRun->rect) > maxY) {
                            maxY = CGRectGetMaxY(tmpRun->rect);
                        }
                    }
                    tmpRun = SYTextRunContextPrevRun(_runContext, tmpRun);
                }
                
                if (maxY > y) {
                    y = maxY;
                }
                
                // Add cell spacing
                y += tableCellSpacing;
            }
            // For vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Reset min Y and max Y
                _minY = tableMinY;
                _maxY = tableMaxY;
                
                // Set X to min X in td
                SYTextRun*  tmpRun;
                float       minX = MAXFLOAT;
                tmpRun = SYTextRunContextPrevRun(_runContext, run);
                while (tmpRun->type != SYRunTypeTrBegin) {
                    if (tmpRun->type == SYRunTypeBlockBegin) {
                        if (CGRectGetMinX(tmpRun->rect) < minX) {
                            minX = CGRectGetMinX(tmpRun->rect);
                        }
                    }
                    tmpRun = SYTextRunContextPrevRun(_runContext, tmpRun);
                }
                
                if (x > minX) {
                    x = minX;
                }
                
                // Add cell spacing
                x -= tableCellSpacing;
            }
            
            // Clear flag
            inTr = NO;
            trRollbacked = NO;
            
            // Go next line
            goto nextLine;
        }
        
        // For td begin
        else if (run->type == SYRunTypeTdBegin) {
            // For horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                // Set X
                x = trX;
                x += CGRectGetMinX([tdWidthRects[tdIndex] CGRectValue]);
                
                // Set Y
                y = trY;
                
                // Set min X and max X
                _minX = x;
                if (tdIndex < [tdWidthRects count]) {
                    _maxX = CGRectGetMaxX([tdWidthRects[tdIndex] CGRectValue]);
                }
                else {
                    _maxX = tableMaxX;
                }
            }
            // For vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Set Y
                y = tableMinY;
                y += CGRectGetMinX([tdWidthRects[tdIndex] CGRectValue]);
                
                // Set X
                x = trX;
                
                // Set min Y and max Y
                _minY = y;
                if (tdIndex < [tdWidthRects count]) {
                    _maxY = tableMinY + CGRectGetMaxX([tdWidthRects[tdIndex] CGRectValue]);
                }
                else {
                    _maxY = tableMaxY;
                }
            }
            
            // Set flag
            inTd = YES;
            
            // Go next run
            goto nextRun;
        }
        
        // For td end
        else if (run->type == SYRunTypeTdEnd) {
            // Increment td index
            tdIndex++;
            
            // Clear flag
            inTd = NO;
            
            // Go next run
            goto nextRun;
        }
        
        // For ruby begin
        else if (run->type == SYRunTypeRubyBegin) {
            float rubyAdvances = _runAdvances(_runContext, run, currentWritingMode);
            float baseAdvances = 0.f;
            // Get ruby base advances
            SYTextRun*  textRun;
            textRun = SYTextRunContextNextRun(_runContext, run);
            while (textRun->type != SYRunTypeRubyEnd) {
                if (textRun->type == SYRunTypeText) {
                    if (currentWritingMode == SYStyleWritingModeLrTb) {
                        baseAdvances += CGRectGetWidth(textRun->rect);
                    }
                    else if (currentWritingMode == SYStyleWritingModeTbRl) {
                        baseAdvances += CGRectGetHeight(textRun->rect);
                    }
                }
                textRun = SYTextRunContextNextRun(_runContext, textRun);
            }
            
            // Check line end for horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                // Check with max x
                if (x + rubyAdvances > _maxX) {
                    // Set excceeded
                    if (lastLine) {
                        exceeded = YES;
                    }
                    
                    // Go next line
                    goto nextLine;
                }
                else if (rubyAdvances > baseAdvances) {
                    // Ruby overflow
                    x += rubyAdvances - baseAdvances;
                }
            }
            // Check line end for vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Check with max y
                if (y + rubyAdvances > _maxY) {
                    // Set excceeded
                    if (lastLine) {
                        exceeded = YES;
                    }
                    
                    // Go next line
                    goto nextLine;
                }
                else if (rubyAdvances > baseAdvances) {
                    // Reby overflow
                    y += rubyAdvances - baseAdvances;
                }
            }
            
            // Go next run
            goto nextRun;
        }
        
        // For ruby end
        else if (run->type == SYRunTypeRubyEnd) {
            // Get next text run
            SYTextRun* nextTextRun = run;
            while ((nextTextRun = SYTextRunContextNextRun(_runContext, nextTextRun))) {
                if (nextTextRun->type == SYRunTypeText ||
                    nextTextRun->type == SYRunTypeRubyBegin)
                {
                    break;
                }
                if (nextTextRun->type == SYRunTypeBlockBegin ||
                    nextTextRun->type == SYRunTypeBlockEnd)
                {
                    nextTextRun = NULL;
                    break;
                }
            }
            
            // Get advance
            float advances = 0.f;
            if (nextTextRun) {
                advances = _runAdvances(_runContext, nextTextRun, currentWritingMode);
            }
        
            // Determine go next line
            BOOL goNextLine = NO;
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                goNextLine = x + advances > _maxX;
            }
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                goNextLine = y + advances > _maxY;
            }
            
            // Go ahead
            if (goNextLine) {
                // Go ahead until ruby inline end run
                while (run && run->type != SYRunTypeRubyInlineEnd) {
                    run = SYTextRunContextIterateNext(_runContext);
                }
                // Go ahead while runtype is inline end run
                while (YES) {
                    if (SYTextRunContextNextRun(_runContext, run)->type == SYRunTypeInlineEnd) {
                        // update
                        if ((currentInlineRun = SYTextRunStackPop(inlineRunStack))) {
                            currentWritingMode = currentInlineRun->inlineStyle->writingMode;
                        }
                        
                        // Go next run
                        run = SYTextRunContextIterateNext(_runContext);
                    }
                    else break;
                }
                
                // Go next line
                goto nextLine;
            }
            else {
                goto nextRun;
            }
        }

        // For not text
        else if (run->type != SYRunTypeText && 
                 run->type != SYRunTypeNewLine && 
                 run->type != SYRunTypeImage)
        {
            // Go next run
            goto nextRun;
        }
        
        // Check current inline run
        if (!currentInlineRun) {
            // Go next run
            goto nextRun;
        }
        
        // Set line begin run
        if (!lineBeginRun) {
            lineBeginRun = run;
        }
        
        // Layout run for horizontal
        if (currentWritingMode == SYStyleWritingModeLrTb) {
            run->rect.origin.x = x;
            run->rect.origin.y = y;
        }
        else if (currentWritingMode == SYStyleWritingModeTbRl) {
            run->rect.origin.x = x - CGRectGetWidth(run->rect);
            run->rect.origin.y = y;
        }
//NSLog(@"runId %d, text %@, rect %@", run->runId, SYTextRunStringWithRun(run), NSStringFromCGRect(run->rect));
        
        // Go next char for horizontal
        if (currentWritingMode == SYStyleWritingModeLrTb) {
            // Increase x
            x += CGRectGetWidth(run->rect);
        }
        // Go next char for vertical
        else if (currentWritingMode == SYStyleWritingModeTbRl) {
            // Increase y
            y += CGRectGetHeight(run->rect);
        }
        
        // For new line
        if (run->type == SYRunTypeNewLine) {
            // Go next line
            goto nextLine;
        }
        
        // Get next run advances
        SYTextRun*  nextTextRun;
        SYTextRun*  rubyBeginRun;
        float       advances;
        nextTextRun = _nextTextRun(_runContext, run);
        rubyBeginRun = _nextTextRun(_runContext, run);
        while (rubyBeginRun) {// Get ruby begin run
            SYTextRun* prevRun = rubyBeginRun->prevRun;
            if (prevRun->type == SYRunTypeRubyBegin) {
                rubyBeginRun = prevRun;
                break;
            }
            if (prevRun->type == SYRunTypeInlineBegin) {
                rubyBeginRun = prevRun;
                continue;
            }
            rubyBeginRun = NULL;
            break;
        }
        if (rubyBeginRun) {
            advances = _runAdvances(_runContext, rubyBeginRun, currentWritingMode);
        }
        else {
            advances = _runAdvances(_runContext, nextTextRun, currentWritingMode);
        }
        
        // For last line
        if (lastLine) {
            // Check last text or not
            lastText = YES;
            SYTextRun*  lastTextRun = NULL;
            lastTextRun = SYTextRunContextNextRun(_runContext, nextTextRun);
            while (lastTextRun) {
                if (lastTextRun->type == SYRunTypeText) {
                    lastText = NO;
                    break;
                }
                lastTextRun = SYTextRunContextNextRun(_runContext, lastTextRun);
            }
            
            // Ignore punctuation
            if (!lastText && nextTextRun && nextTextRun->punctuation != SYPunctuationWhole) {
                advances *= 2;
            }
        }
        
//NSLog(@"runId %d, next text %@, x %f, next advances %f, _maxX %f", run->runId, SYTextRunStringWithRun(nextTextRun), x, advances, _maxX);
//NSLog(@"next text %@, y %f, next advances %f, _maxY %f", SYTextRunStringWithRun(nextTextRun), y, advances, _maxY);
        // Check line end for horizontal
        if (currentWritingMode == SYStyleWritingModeLrTb) {
            // Check with max x
            if (x + advances > endX) {
                // Set excceeded
                if (lastLine) {
                    exceeded = YES;
                }
                
                // Go next line
                goto nextLine;
            }
        }
        // Check line end for vertical
        else if (currentWritingMode == SYStyleWritingModeTbRl) {
            // Check with end y
            if (y + advances > endY) {
                // Set excceeded
                if (lastLine) {
                    exceeded = YES;
                }
                
                // Go next line
                goto nextLine;
            }
        }
        
        // Check floating
        if (nextTextRun && [parser.floatRects count] > 0) {
            // Check floating for horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                // Decide next rect
                CGRect  nextRect;
                nextRect.origin.x = x;
                nextRect.origin.y = y;
                nextRect.size.width = advances;
                nextRect.size.height = CGRectGetHeight(nextTextRun->rect);
                
                // Check with floating rects
                for (NSValue* floatRectValue in parser.floatRects) {
                    // For intersection
                    CGRect  floatRect;
#if TARGET_OS_IPHONE
                    floatRect = [floatRectValue CGRectValue];
#elif TARGET_OS_MAC
                    floatRect = NSRectToCGRect([floatRectValue rectValue]);
#endif
                    if (CGRectIntersectsRect(floatRect, nextRect)) {
                        // Set end X
                        endX = CGRectGetMinX(floatRect);
                        
                        // Set excceeded
                        if (lastLine) {
                            exceeded = YES;
                        }
                        
                        // Go next line
                        goto nextLine;
                    }
                }
            }
            // Check floating for vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                // Decide next rect
                CGRect  nextRect;
                nextRect.origin.x = x - CGRectGetWidth(nextTextRun->rect);
                nextRect.origin.y = y + advances;
                nextRect.size.width = CGRectGetWidth(nextTextRun->rect);
                nextRect.size.height = advances;
                
                // Check with floating rects
                for (NSValue* floatRectValue in parser.floatRects) {
                    // Get float rect
                    CGRect  floatRect;
#if TARGET_OS_IPHONE
                    floatRect = [floatRectValue CGRectValue];
#elif TARGET_OS_MAC
                    floatRect = NSRectToCGRect([floatRectValue rectValue]);
#endif
                    
                    // Move x position
                    floatRect.origin.x = pageSize.width - CGRectGetMaxX(floatRect);
                    
                    // For intersection
                    if (CGRectIntersectsRect(floatRect, nextRect)) {
                        // Set end Y
                        endY = CGRectGetMinY(floatRect);
                        
                        // Set excceeded
                        if (lastLine) {
                            exceeded = YES;
                        }
                        
                        // Go next line
                        goto nextLine;
                    }
                }
            }
        }
        
        // Go next run
        goto nextRun;
        
        // ------------------------------------------------------------ //
        #pragma mark ├ Next line
        // ------------------------------------------------------------ //
        
        nextLine: {
            SYTextRun*  tmpRun;
            BOOL        done;
            
            // Check line begin run
            if (!lineBeginRun) {
                // For block end
                if (run->type == SYRunTypeBlockEnd) {
                    // Go end line
                    goto endLine;
                }
                
                // Go next run
                goto nextRun;
            }
            
            //
            // Not ending characters and not starting characters
            //
            
            // When last run is text or inline end
            if (run->type == SYRunTypeText || run->type == SYRunTypeInlineEnd) {
                // For not ending line characters
                SYTextRun*  lineEndRun;
                BOOL        inRuby = NO;
                lineEndRun = run;
                while (lineEndRun->runId > lineBeginRun->runId) {
                    // For text
                    if (lineEndRun->type == SYRunTypeText) {
                        // For not not ending line character
                        if (lineEndRun->textLength >= 1 && 
                            !_isNotEndingLineCharacter(*lineEndRun->textBuffer))
                        {
                            break;
                        }
                    }
                    else if (lineEndRun->type == SYRunTypeRubyEnd) {
                        inRuby = YES;
                    }
                    else if (lineEndRun->type == SYRunTypeRubyBegin) {
                        inRuby = NO;
                    }
                    
                    // Get prev run
                    lineEndRun = SYTextRunContextPrevRun(_runContext, lineEndRun);
                }
                
                // Roll back to line end run
                if (lineEndRun->runId > lineBeginRun->runId) {
                    while (run->runId > lineEndRun->runId) {
                        run = SYTextRunContextIteratePrev(_runContext);
                    }
                    if (inRuby) {
                        while (run->type != SYRunTypeRubyInlineEnd) {
                            run = SYTextRunContextIterateNext(_runContext);
                        }
                    }
                }
            }
            
            // Get next line begin run
            SYTextRun*  nextLineBeginRun;
            nextLineBeginRun = run;
            while (YES) {
                // Get next run
                nextLineBeginRun = SYTextRunContextNextRun(_runContext, nextLineBeginRun);
                if (!nextLineBeginRun) {
                    break;
                }
                
                // Check run type
                if (nextLineBeginRun->type == SYRunTypeText || 
                    nextLineBeginRun->type == SYRunTypeBlockBegin || 
                    nextLineBeginRun->type == SYRunTypeBlockEnd || 
                    nextLineBeginRun->type == SYRunTypeNewLine)
                {
                    break;
                }
            }
            
            // in case next line begin run is text
            if (nextLineBeginRun && nextLineBeginRun->type == SYRunTypeText) {
                BOOL inRuby = NO;
                while (nextLineBeginRun->runId > lineBeginRun->runId) {
                    // For text
                    if (nextLineBeginRun->type == SYRunTypeText) {
                        // For not not starting line character
                        if (nextLineBeginRun->textLength >= 1 &&
                            !_isNotStartingLineCharacter(*nextLineBeginRun->textBuffer))
                        {
                            // Get line end run again
                            SYTextRun*  newEndRun;
                            newEndRun = SYTextRunContextPrevRun(_runContext, nextLineBeginRun);
                            while (newEndRun->runId > lineBeginRun->runId) {
                                if (newEndRun->type == SYRunTypeText) {
                                    break;
                                }

                                newEndRun = SYTextRunContextPrevRun(_runContext, newEndRun);
                            }
                            
                            // Check not ending line character
                            if (newEndRun->textLength >= 1 &&
                                !_isNotEndingLineCharacter(*newEndRun->textBuffer))
                            {
                                break;
                            }
                        }
                    }
                    else if (nextLineBeginRun->type == SYRunTypeRubyEnd) {
                        inRuby = YES;
                    }
                    else if (nextLineBeginRun->type == SYRunTypeRubyBegin) {
                        inRuby = NO;
                    }
                    
                    // Get prev run
                    nextLineBeginRun = SYTextRunContextPrevRun(_runContext, nextLineBeginRun);
                }
                
                // Roll back to ruby begin if in ruby
                if (nextLineBeginRun && inRuby) {
                    while ((nextLineBeginRun = SYTextRunContextPrevRun(_runContext, nextLineBeginRun)) &&
                           nextLineBeginRun->runId > lineBeginRun->runId)
                    {
                        if (nextLineBeginRun->type == SYRunTypeRubyBegin) {
                            break;
                        }
                    }
                }
                
                // Roll back to next line begin run
                while (run->runId >= nextLineBeginRun->runId && run->runId > lineBeginRun->runId) {
                    run = SYTextRunContextIteratePrev(_runContext);
                }
            }
            
            // Show line
//NSLog(@"line %@", SYTextRunContextStringBetweenRun(_runContext, lineBeginRun, run));
            
            //
            // Text align
            //
            
            // Find begin and end text run
            SYTextRun*  beginTextRun = NULL;
            SYTextRun*  endTextRun = NULL;
            tmpRun = lineBeginRun;
            done = NO;
            while (tmpRun) {
                // For text run
                if (tmpRun->type == SYRunTypeText) {
                    if (!beginTextRun) {
                        beginTextRun = tmpRun;
                    }
                    else {
                        endTextRun = tmpRun;
                    }
                }
                
                // Get next run
                if (done) {
                    break;
                }
                tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                done = tmpRun->runId >= run->runId;
            }
            
            // Make 0 width space character at begin and end
            BOOL    isSpaceAtBegin = NO;
            BOOL    isSpaceAtEnd = NO;
            if (beginTextRun && beginTextRun->textLength == 1 && _isRunFilledWithSpace(beginTextRun)) {
                if (currentWritingMode == SYStyleWritingModeLrTb) {
                    beginTextRun->rect.size.width = 0;
                }
                else if (currentWritingMode == SYStyleWritingModeTbRl) {
                    beginTextRun->rect.size.height = 0;
                }
                isSpaceAtBegin = YES;
                
                // Find begin text run again
                tmpRun = SYTextRunContextNextRun(_runContext, beginTextRun);
                while (tmpRun && endTextRun && tmpRun->runId < endTextRun->runId) {
                    if (tmpRun->type == SYRunTypeText) {
                        beginTextRun = tmpRun;
                        
                        break;
                    }
                    tmpRun = SYTextRunContextPrevRun(_runContext, tmpRun);
                }
            }
            if (endTextRun && endTextRun->textLength == 1 && _isRunFilledWithSpace(endTextRun) && !lastLine) {
                if (currentWritingMode == SYStyleWritingModeLrTb) {
                    endTextRun->rect.size.width = 0;
                }
                else if (currentWritingMode == SYStyleWritingModeTbRl) {
                    endTextRun->rect.size.height = 0;
                }
                isSpaceAtEnd = YES;
                
                // Find end text run again
                tmpRun = SYTextRunContextPrevRun(_runContext, endTextRun);
                while (tmpRun->runId > beginTextRun->runId) {
                    if (tmpRun->type == SYRunTypeText) {
                        endTextRun = tmpRun;
                        
                        break;
                    }
                    tmpRun = SYTextRunContextPrevRun(_runContext, tmpRun);
                }
            }
            
            // Count text run and total advances
            int     textRunCount = 0;
            int     firstHalfCount = 0, secondHalfCount = 0, notInsertAfterMarginCount = 0;
            float   totalAdvances = 0;
            tmpRun = lineBeginRun;
            done = NO;
            while (YES) {// back to ruby begin run if exists
                SYTextRun* prevRun = tmpRun->prevRun;
                if (!prevRun) break;
                if (prevRun->type == SYRunTypeInlineBegin ||
                    prevRun->type == SYRunTypeRubyBegin)
                {
                    tmpRun = prevRun;
                }
                else break;
            }
            while (tmpRun) {
                // For ruby begin run
                if (tmpRun->type == SYRunTypeRubyBegin) {
                    // Add advances
                    totalAdvances += _runAdvances(_runContext, tmpRun, currentWritingMode);
                    
                    // Skip to ruby end
                    while (YES) {
                        // Get next run
                        tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                        if (!tmpRun) break;
                        
                        // For text run
                        if (tmpRun->type == SYRunTypeText) {
                            // Increment count
                            textRunCount++;
                        }
                        // For ruby end
                        else if (tmpRun->type == SYRunTypeRubyEnd) {
                            break;
                        }
                    }
                    continue;
                }
                
                // For text run
                else if (tmpRun->type == SYRunTypeText || tmpRun->type == SYRunTypeImage) {
                    // Increment count
                    textRunCount++;
                    
                    // Add advances
                    if (exceeded && tmpRun == endTextRun) {
                        totalAdvances += tmpRun->inlineStyle->fontSize;
                    }
                    else {
                        totalAdvances += _runAdvances(_runContext, tmpRun, currentWritingMode);
                    }
                    
                    // For first half
                    if (_isFirstHalfPunctuation(*(tmpRun->text))) {
                        firstHalfCount++;
                    }
                    
                    // For second half
                    if (_isSecondHalfPunctuation(*(tmpRun->text))) {
                        secondHalfCount++;
                    }
                    
                    if (_isNotInsertingAfterMarginCharacter(*(tmpRun->text))) {
                        notInsertAfterMarginCount++;
                    }
                }
                
                // Get next run
                if (done) {
                    break;
                }
                tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                done = tmpRun->runId >= run->runId;
            }
            
            // Align text
            int     textAlign;
            float   tx, ty;
            float   margin = 0;
            textAlign = lineBeginRun->blockStyle->textAlign;
            
            // Calc begin x and margin for horizontal
            if (currentWritingMode == SYStyleWritingModeLrTb) {
                if (textAlign == SYStyleTextAlignRight) {
                    tx = _maxX - totalAdvances;
                }
                else if (textAlign == SYStyleTextAlignCenter) {
                    tx = _minX + ((_maxX - _minX) - totalAdvances) * 0.5f;
                }
                else {
                    tx = _minX;
                    
                    // For hanging indent
                    if (lineCount > 0 && parser.hangingIndent > 0) {
                        tx += currentInlineRun->inlineStyle->fontSize * parser.hangingIndent;
                    }
                }
                
                if (textAlign == SYStyleTextAlignJustify) {
                    int count;
                    count = textRunCount;
                    if (isSpaceAtBegin) {
                        count--;
                    }
                    if (isSpaceAtEnd) {
                        count--;
                    }
                    count -= firstHalfCount + secondHalfCount + notInsertAfterMarginCount;
                    if (count > 1) {
                        margin = ((endX - tx) - totalAdvances) / (count - 1);
                        
                        // Do not use big margin
                        if (margin > currentInlineRun->inlineStyle->fontSize * 0.5f) {
                            margin = 0;
                        }
                    }
                }
            }
            // Calc begin y and margin for vertical
            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                if (textAlign == SYStyleTextAlignRight) {
                    ty = _maxY - totalAdvances;
                }
                else if (textAlign == SYStyleTextAlignCenter) {
                    ty = _minY + ((_maxY - _minY) - totalAdvances) * 0.5f;
                }
                else {
                    ty = _minY;
                    
                    // For hanging indent
                    if (lineCount > 0 && parser.hangingIndent > 0) {
                        ty += currentInlineRun->inlineStyle->fontSize * parser.hangingIndent;
                    }
                }
                
                if (textAlign == SYStyleTextAlignJustify) {
                    int count;
                    count = textRunCount;
                    if (isSpaceAtBegin) {
                        count--;
                    }
                    if (isSpaceAtEnd) {
                        count--;
                    }
                    count -= firstHalfCount + secondHalfCount + notInsertAfterMarginCount;
                    if (count > 1) {
                        margin = ((endY - ty) - totalAdvances) / (count - 1);
                        
                        // Do not use big margin
                        if (margin > currentInlineRun->inlineStyle->fontSize * 0.5f) {
                            margin = 0;
                        }
                    }
                }
            }
            margin = margin > 0.f ? margin : 0;

            // Check end block or not
            BOOL    isEndBlock = NO;
            tmpRun = run;
            if (run->type == SYRunTypeText) {
                tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
            }
            while (tmpRun) {
                if (tmpRun->type == SYRunTypeBlockEnd) {
                    isEndBlock = YES;
                    break;
                }
                if (tmpRun->type == SYRunTypeText) {
                    break;
                }
                tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
            }
            
            //
            // Apply margin
            //
            
            tmpRun = lineBeginRun;
            done = NO;
            {// back to ruby begin if exists
                SYTextRun* prevRun;
                while (YES) {
                    prevRun = tmpRun->prevRun;
                    if (!prevRun) break;
                    if (prevRun->type == SYRunTypeInlineBegin ||
                        prevRun->type == SYRunTypeRubyBegin)
                    {
                        tmpRun = prevRun;
                    }
                    else break;
                }
            }
            
            while (tmpRun) {
                // For ruby run
                if (tmpRun->type == SYRunTypeRubyBegin) {
                    float advances = _runAdvances(_runContext, tmpRun, currentWritingMode);
                    float baseRunAdvances = 0.f;
                    SYTextRun* tmpRubyTextRun = tmpRun;
                    SYTextRun *baseTextBeginRun = NULL, *baseTextEndRun = NULL;
                    while ((tmpRubyTextRun = tmpRubyTextRun->nextRun)) {// Get begin and end run
                        if (tmpRubyTextRun->type == SYRunTypeRubyEnd) break;
                        if (tmpRubyTextRun->type == SYRunTypeText) {
                            if (!baseTextBeginRun) baseTextBeginRun = tmpRubyTextRun;
                            baseTextEndRun = tmpRubyTextRun;
                        }
                    }
                    for (tmpRubyTextRun = baseTextBeginRun; tmpRubyTextRun->runId <= baseTextEndRun->runId; tmpRubyTextRun = tmpRubyTextRun->nextRun) {
                        if (tmpRubyTextRun->type == SYRunTypeText) {
                            // For horizontal
                            if (currentWritingMode == SYStyleWritingModeLrTb) {
                                baseRunAdvances += CGRectGetWidth(tmpRubyTextRun->rect);
                            }
                            // For vertical
                            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                                baseRunAdvances += CGRectGetHeight(tmpRubyTextRun->rect);
                            }
                        }
                    }
                    // case: Ruby runs has bigger advances than base runs
                    if (advances > baseRunAdvances) {
                        tmpRun = baseTextBeginRun;
                        while (tmpRun) {
                            if (tmpRun->runId > baseTextEndRun->runId) break;
                            
                            // Set run origin
                            if (tmpRun->type == SYRunTypeText) {
                                if (tmpRun == baseTextBeginRun) {
                                    if (currentWritingMode == SYStyleWritingModeLrTb) {
                                        tx += (advances - baseRunAdvances) * 0.5f;
                                    }
                                    else if (currentWritingMode == SYStyleWritingModeTbRl) {
                                        ty += (advances - baseRunAdvances) * 0.5f;
                                    }
                                }
                                
                                // For right or center
                                if (textAlign == SYStyleTextAlignRight || textAlign == SYStyleTextAlignCenter) {
                                    // For horizontal
                                    if (currentWritingMode == SYStyleWritingModeLrTb) {
                                        // Set x
                                        tmpRun->rect.origin.x = tx;
                                        
                                        // Increase x
                                        tx += CGRectGetWidth(tmpRun->rect);
                                    }
                                    // For vertical
                                    else if (currentWritingMode == SYStyleWritingModeTbRl) {
                                        // Set y
                                        tmpRun->rect.origin.y = ty;
                                        
                                        // Increase y
                                        ty += CGRectGetHeight(tmpRun->rect);
                                    }
                                }
                                // For justify
                                else if (textAlign == SYStyleTextAlignJustify) {
                                    // Check last run
                                    if (tmpRun->type == SYRunTypeText) {
                                        // Check puncutation for skip
                                        SYTextRun* nextTmpRun = _nextTextRun(_runContext, tmpRun);
                                        BOOL    skipMargin = NO;
                                        if (_isSecondHalfPunctuation(*(tmpRun->text)) ||
                                            _isNotInsertingAfterMarginCharacter(*(tmpRun->text)))
                                        {
                                            skipMargin = YES;
                                        }
                                        else if (nextTmpRun &&
                                                 nextTmpRun->type == SYRunTypeText &&
                                                 _isFirstHalfPunctuation(*(nextTmpRun)->text))
                                        {
                                            skipMargin = YES;
                                        }
                                        
                                        // For horizontal
                                        if (currentWritingMode == SYStyleWritingModeLrTb) {
                                            // Set x
                                            tmpRun->rect.origin.x = tx;
                                            
                                            // Increase x
                                            if (CGRectGetWidth(tmpRun->rect) > 0) {
                                                tx += CGRectGetWidth(tmpRun->rect);
                                            }
                                            if (!skipMargin) {
                                                tx += margin;
                                            }
                                        }
                                        // For vertical
                                        else if (currentWritingMode == SYStyleWritingModeTbRl) {
                                            // Set y
                                            tmpRun->rect.origin.y = ty;
                                            
                                            // Increase y
                                            if (CGRectGetHeight(tmpRun->rect) > 0) {
                                                ty += CGRectGetHeight(tmpRun->rect);
                                            }
                                            if (!skipMargin) {
                                                ty += margin;
                                            }
                                        }
                                    }
                                }
                            }
                            tmpRun = tmpRun->nextRun;
                        }
                        
                        // For last ruby text run
                        if (currentWritingMode == SYStyleWritingModeLrTb) {
                            tx += (advances - baseRunAdvances) * 0.5f;
                        }
                        else if (currentWritingMode == SYStyleWritingModeTbRl) {
                            ty += (advances - baseRunAdvances) * 0.5f;
                        }
                    }
                }
                
                // For text run
                if (tmpRun->type == SYRunTypeText || tmpRun->type == SYRunTypeImage) {
                    // For right or center
                    if (textAlign == SYStyleTextAlignRight || textAlign == SYStyleTextAlignCenter) {
                        // For horizontal
                        if (currentWritingMode == SYStyleWritingModeLrTb) {
                            // Set x
                            tmpRun->rect.origin.x = tx;
                            
                            // Increase x
                            tx += CGRectGetWidth(tmpRun->rect);
                        }
                        // For vertical
                        else if (currentWritingMode == SYStyleWritingModeTbRl) {
                            // Set y
                            tmpRun->rect.origin.y = ty;
                            
                            // Increase y
                            ty += CGRectGetHeight(tmpRun->rect);
                        }
                    }
                    // For justify
                    else if (textAlign == SYStyleTextAlignJustify) {
                        // Check last run
                        if (tmpRun->type == SYRunTypeText) {
                            // Check puncutation for skip
                            SYTextRun*  nextTmpRun = _nextTextRun(_runContext, tmpRun);
                            BOOL    skipMargin = NO;
                            if (_isSecondHalfPunctuation(*(tmpRun->text)) ||
                                _isNotInsertingAfterMarginCharacter(*(tmpRun->text)))
                            {
                                skipMargin = YES;
                            }
                            else if (nextTmpRun &&
                                     nextTmpRun->type == SYRunTypeText &&
                                     _isFirstHalfPunctuation(*(nextTmpRun->text)))
                            {
                                skipMargin = YES;
                            }
                            else if (isEndBlock) {
                                skipMargin = YES;
                            }
                            
                            // For horizontal
                            if (currentWritingMode == SYStyleWritingModeLrTb) {
                                // Set x
                                tmpRun->rect.origin.x = tx;
                                
                                // Increase x
                                if (CGRectGetWidth(tmpRun->rect) > 0) {
                                    tx += CGRectGetWidth(tmpRun->rect);
                                }
                                if (!skipMargin) {
                                    tx += margin;
                                }
                            }
                            // For vertical
                            else if (currentWritingMode == SYStyleWritingModeTbRl) {
                                // Set y
                                tmpRun->rect.origin.y = ty;
                                
                                // Increase y
                                if (CGRectGetHeight(tmpRun->rect) > 0) {
                                    ty += CGRectGetHeight(tmpRun->rect);
                                }
                                if (!skipMargin) {
                                    ty += margin;
                                }
                            }
                        }
                    }
                }
                
                // Get next run
                if (done) {
                    break;
                }
                tmpRun = tmpRun->nextRun;
                done = tmpRun->runId >= run->runId;
            }
            
            //
            // Line height
            //
            
            // Decide line height
            float   maxLineHeight = 0;
            float   maxTextHeight = 0;
            float   maxTextHeightWithoutLineHeight = 0;
            float   maxLeadingHeight = 0;
            float   maxImageHeight = 0;
            tmpRun = lineBeginRun;
            done = NO;
            while (tmpRun) {
                // For text run
                if (tmpRun->type == SYRunTypeText || tmpRun->type == SYRunTypeNewLine) {
                    // Calc line height
                    float               textHeight;
                    float               textHeightWithoutLineHeight;
                    float               leadingHeight = 0;
                    SYTextInlineStyle*  inlineStyle;
                    inlineStyle = tmpRun->inlineStyle;
                    textHeightWithoutLineHeight = inlineStyle->descent + inlineStyle->ascent;
                    if (run->type == SYRunTypeBlockEnd) {
                        // For block end, dose not multiply line height
                        textHeight = textHeightWithoutLineHeight;
                    }
                    else {
                        textHeight = inlineStyle->lineHeight * textHeightWithoutLineHeight;
                        leadingHeight = (inlineStyle->lineHeight - 1.0f) * textHeightWithoutLineHeight;
                    }
                    
                    if (textHeight > maxTextHeight) {
                        maxTextHeight = textHeight;
                    }
                    if (textHeightWithoutLineHeight > maxTextHeightWithoutLineHeight) {
                        maxTextHeightWithoutLineHeight = textHeightWithoutLineHeight;
                    }
                    if (leadingHeight > maxLeadingHeight) {
                        maxLeadingHeight = leadingHeight;
                    }
                }
                // For image run
                else if (tmpRun->type == SYRunTypeImage) {
                    // Get height
                    float   imageHeight;
                    imageHeight = CGRectGetHeight(tmpRun->rect);
                    if (imageHeight > maxImageHeight) {
                        maxImageHeight = imageHeight;
                    }
                }
                
                // Get next run
                if (done) {
                    break;
                }
                tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                done = tmpRun->runId >= run->runId;
            }
            
            // Add leading height to image height
            maxImageHeight += maxLeadingHeight;
            
            // Decide max line height
            maxLineHeight = maxTextHeight > maxImageHeight ? maxTextHeight : maxImageHeight;
            
            //
            // Vertical align
            //
            
            // Align vertically
            tmpRun = lineBeginRun;
            done = NO;
            while (tmpRun) {
                CGRect  rect;
                
                // For text run
                if (tmpRun->type == SYRunTypeText) {
                    // Swtich by vertical align
                    switch (tmpRun->inlineStyle->verticalAlign) {
                    // For text top
                    case SYStyleVerticalAlignTextTop: {
                        break;
                    }
                    // For bottom
                    case SYStyleVerticalAlignBottom: {
                        // For horizontal
                        if (currentWritingMode == SYStyleWritingModeLrTb) {
                            rect = tmpRun->rect;
                            tmpRun->rect.origin.y = CGRectGetMinY(rect) + 
                                    maxTextHeightWithoutLineHeight - CGRectGetHeight(rect);
                        }
                        else if (currentWritingMode == SYStyleWritingModeTbRl) {
                            rect = tmpRun->rect;
                            tmpRun->rect.origin.x = CGRectGetMaxX(rect) - 
                                    maxTextHeightWithoutLineHeight;
                        }
                        
                        break;
                    }
                    // For super
                    case SYStyleVerticalAlignSuper: {
                        // For horizontal
                        if (currentWritingMode == SYStyleWritingModeLrTb) {
                            rect = tmpRun->rect;
                            tmpRun->rect.origin.y = CGRectGetMinY(rect) - maxTextHeightWithoutLineHeight * 0.2f;
                        }
                        // For vertical
                        else if (currentWritingMode == SYStyleWritingModeTbRl) {
                            tmpRun->rect.origin.x = CGRectGetMaxX(rect) - maxTextHeightWithoutLineHeight * 0.2f;
                        }
                        break;
                    }
                    // For sub
                    case SYStyleVerticalAlignSub: {
                        // For horizontal
                        if (currentWritingMode == SYStyleWritingModeLrTb) {
                            rect = tmpRun->rect;
                            tmpRun->rect.origin.y = CGRectGetMinY(rect) + maxTextHeightWithoutLineHeight * 0.5f;
                        }
                        // For vertical
                        else if (currentWritingMode == SYStyleWritingModeTbRl) {
                            tmpRun->rect.origin.x = CGRectGetMinX(rect);
                        }
                        break;
                    }
                    }
                }
                
                // Get next run
                if (done) {
                    break;
                }
                tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                done = tmpRun->runId >= run->runId;
            }
            
            //
            // Ruby
            //
            
            tmpRun = lineBeginRun;
            done = NO;
            while (tmpRun) {
                // For ruby inline begin run
                if (tmpRun->type == SYRunTypeRubyInlineBegin && currentInlineRun) {
                    // Get base run
                    SYTextRun*  baseRun;
                    baseRun = tmpRun->inlineStyle->baseRun;
                    
                    // Decide base run start point and advance
                    float   baseX = MAXFLOAT, baseY = MAXFLOAT;
                    float   baseAdvances = 0;
                    baseRun = SYTextRunContextNextRun(_runContext, baseRun);
                    while (baseRun->type == SYRunTypeText || baseRun->type == SYRunTypeInlineBegin) {
                        if (baseRun->type == SYRunTypeText) {
                            // Get base position and advance for horizontal
                            if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                                if (baseX == MAXFLOAT) {
                                    baseX = CGRectGetMinX(baseRun->rect);
                                    baseY = CGRectGetMinY(baseRun->rect);
                                }
                                baseAdvances = CGRectGetMaxX(baseRun->rect) - baseX;
                            }
                            // Get base position and advance for vertical
                            else if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                                if (baseX == MAXFLOAT) {
                                    baseX = CGRectGetMaxX(baseRun->rect);
                                    baseY = CGRectGetMinY(baseRun->rect);
                                }
                                baseAdvances = CGRectGetMaxY(baseRun->rect) - baseY;
                            }
                        }
                        
                        // Get next run
                        baseRun = SYTextRunContextNextRun(_runContext, baseRun);
                    }
                    
                    // Get total advantces of ruby
                    SYTextRun*  rubyRun;
                    float       rubyAdvances = 0;
                    int         rubyCount = 0;
                    rubyRun = SYTextRunContextNextRun(_runContext, tmpRun);
                    while (rubyRun->type == SYRunTypeRubyText) {
                        // Add ruby advance for horizontal
                        if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                            rubyAdvances += CGRectGetWidth(rubyRun->rect);
                        }
                        // Add ruby advance for vertical
                        else if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                            rubyAdvances += CGRectGetHeight(rubyRun->rect);
                        }
                        
                        // Increment ruby count
                        rubyCount++;
                        
                        // Get next run
                        rubyRun = SYTextRunContextNextRun(_runContext, rubyRun);
                    }
                    
                    // Calc ruby x or y
                    float   rubyX, rubyY;
                    
                    // Calc ruby x for horizontal
                    if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                        rubyX = baseX + (baseAdvances - rubyAdvances) * 0.5f;
                    }
                    // Calc ruby y for vertical
                    else if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                        rubyY = baseY + (baseAdvances - rubyAdvances) * 0.5f;
                    }
                    
                    // Layout ruby
                    rubyRun = SYTextRunContextNextRun(_runContext, tmpRun);
                    while (rubyRun->type == SYRunTypeRubyText) {
                        // For horizontal
                        if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                            // Layout ruby
                            rubyRun->rect.origin.x = rubyX;
                            rubyRun->rect.origin.y = baseY - (rubyRun->inlineStyle->descent + rubyRun->inlineStyle->ascent);

                            // Increase ruby x
                            rubyX += CGRectGetWidth(rubyRun->rect);
                        }
                        // For vertical
                        else if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                            // Layout ruby
                            rubyRun->rect.origin.y = rubyY;
                            rubyRun->rect.origin.x = baseX;
                            
                            // Increase ruby y
                            rubyY += CGRectGetHeight(rubyRun->rect);
                        }
                        
                        // Get next run
                        rubyRun = SYTextRunContextNextRun(_runContext, rubyRun);
                    }
                }
                
                // Get next run
                if (done) {
                    break;
                }
                tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                done = tmpRun && tmpRun->runId == run->runId;
            }
            
            //
            // Go next line
            //
            
            // For horizontal
            if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeLrTb) {
                // Go next line
                if (inTable && inTr && inTd) {
                    x = _minX + tableCellPadding;
                    endX = _maxX - tableCellPadding;
                }
                else {
                    x = _minX;
                    endX = _maxX;
                }
                
                if (isEndBlock) {
                    y += maxTextHeightWithoutLineHeight;
                }
                else {
                    y += maxLineHeight;
                }
                
                // For hanging indent
                if (parser.hangingIndent > 0) {
                    x += currentInlineRun->inlineStyle->fontSize * parser.hangingIndent;
                }
            }
            // For vertical
            else if (currentInlineRun->inlineStyle->writingMode == SYStyleWritingModeTbRl) {
                float spaceToNextBlock = 0.f;
                
                // Go next line
                if (isEndBlock) {
                    x -= maxTextHeightWithoutLineHeight;
                    
                    // Calc next block space
                    {
                        SYTextRun* tmpRun = run;
                        if(tmpRun->type == SYRunTypeText) {// if 'run' has last char of this line, get next run.
                            tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                        }
                        while (tmpRun) {
                            if (tmpRun->type == SYRunTypeBlockEnd) {
                                spaceToNextBlock += SYStyleMarginBottom(tmpRun->blockStyle, tmpRun->inlineStyle, 0) +
                                                    SYStylePaddingBottom(tmpRun->blockStyle, tmpRun->inlineStyle, 0);
                            }
                            else if (tmpRun->type == SYRunTypeBlockBegin) {
                                spaceToNextBlock += SYStyleMarginTop(tmpRun->blockStyle, tmpRun->inlineStyle, 0) +
                                                    SYStylePaddingTop(tmpRun->blockStyle, tmpRun->inlineStyle, 0);
                            }
                            else if (tmpRun->type == SYRunTypeText) {
                                break;
                            }
                            
                            // Go to next run
                            tmpRun = SYTextRunContextNextRun(_runContext, tmpRun);
                        }
                    }
                }
                else {
                    x -= maxLineHeight;
                }
                
                if (inTable && inTr && inTd) {
                    y = _minY + tableCellPadding;
                    endY = _maxY - tableCellPadding;
                }
                else {
                    y = _minY;
                    endY = _maxY;
                }
                
                // For vertical column
                if (parser.rowHeightForVertical > 0) {
                    if (x - maxTextHeightWithoutLineHeight - spaceToNextBlock < _minX) {
                        // Set min and max Y
                        float   maxY;
                        if (tableMinY != MAXFLOAT) {
                            maxY = tableMaxY;
                        }
                        else {
                            maxY = _maxY;
                        }
                        _minY = maxY + parser.rowMarginForVertical;
                        _maxY = _minY + parser.rowHeightForVertical;
                        
                        // Set X and Y
                        x = _maxX;
                        y = _minY;
                        
                        // Update end y
                        endY = _maxY;
                        
                        // Update table min Y and max Y
                        if (tableMinY != MAXFLOAT) {
                            tableMinY = _minY;
                            tableMaxY = _maxY;
                        }
                        
                        // Increment column break count
                        columnBreakCount++;
                        
                        // Roll back to tr begin
                        if (inTr && !trRollbacked) {
                            // Find tr begin
                            while (run->type != SYRunTypeTrBegin && run->type != SYRunTypeTableBegin) {
                                if (run->type == SYRunTypeBlockBegin && run == currentBlockRun) {
                                    // Pop block run
                                    SYTextRun*  poppedBlockRun;
                                    poppedBlockRun = SYTextRunStackPop(blockRunStack);
                                    currentBlockRun = poppedBlockRun;
                                }
                                run = SYTextRunContextIteratePrev(_runContext);
                            }
                            
                            // Set flag
                            trRollbacked = YES;
                            
                            continue;
                        }
                    }
                }
                
                // For hanging indent
                if (parser.hangingIndent > 0) {
                    y += currentInlineRun->inlineStyle->fontSize * parser.hangingIndent;
                }
            }
            else {
                // Go next line as horizontal
                x = _minX;
                y += maxLineHeight;
            }
            
            // Clear line begin run
            lineBeginRun = NULL;
        }
        
        // ------------------------------------------------------------ //
        #pragma mark ├ End line
        // ------------------------------------------------------------ //
        
        endLine: {
            // For block end
            if (run->type == SYRunTypeBlockEnd) {
                // Pop block run
                SYTextRun*  poppedBlockRun;
                poppedBlockRun = SYTextRunStackPop(blockRunStack);
                
                // Get current block style and inline style
                SYTextBlockStyle*   blkStyle;
                SYTextInlineStyle*  inlStyle;
                blkStyle = currentBlockRun->blockStyle;
                inlStyle = currentBlockRun->inlineStyle;
                
                // For horizontal
                if (currentBlockRun->blockStyle->writingMode == SYStyleWritingModeLrTb) {
                    // Add cell padding
                    if (inTable && inTr && inTd) {
                        y += tableCellPadding;
                    }
                    
                    // Reset min x and max x
                    if (poppedBlockRun) {
                        _minX = CGRectGetMinX(poppedBlockRun->rect);
                        _maxX = CGRectGetMaxX(poppedBlockRun->rect);
                    }
                    else {
                        _minX = 0;
                        _maxX = pageSize.width;
                    }
                    
                    // Calc run height
                    float   wide;
                    float   borderBottom;
                    wide = _maxX - _minX;
                    borderBottom = SYStyleCalcUnitValue(
                        blkStyle->borderBottom.value, blkStyle->borderBottom.unit, wide, inlStyle->fontSize);
                    currentBlockRun->rect.size.height = 
                            y + 
                            SYStylePaddingBottom(blkStyle, inlStyle, wide) + 
                            borderBottom - 
                            CGRectGetMinY(currentBlockRun->rect);
                    
                    // Set x and y
                    x = _minX;
                    y = CGRectGetMaxY(currentBlockRun->rect) + SYStyleMarginBottom(blkStyle, inlStyle, wide);
                }
                // For vertical
                else if (currentBlockRun->blockStyle->writingMode == SYStyleWritingModeTbRl) {
                    // Add cell padding
                    if (inTable && inTr && inTd) {
                        x -= tableCellPadding;
                    }
                    
                    // Calc run width
                    float   beginX;
                    beginX = CGRectGetMinX(currentBlockRun->rect);
                    currentBlockRun->rect.origin.x = x - currentBlockRun->blockStyle->paddingLeft;
                    currentBlockRun->rect.size.width = beginX - CGRectGetMinX(currentBlockRun->rect);
                    
                    // Set run height
                    if (CGRectGetMaxY(currentBlockRun->rect) < _maxY) {
                        currentBlockRun->rect.size.height = _maxY - CGRectGetMinY(currentBlockRun->rect);
                    }
                    
                    // Remove margin and padding
                    _minY -= run->blockStyle->marginRight;
                    _minY -= run->blockStyle->paddingRight;
                    _maxY += run->blockStyle->marginLeft;
                    _maxY += run->blockStyle->paddingLeft;
                    
                    // Set x and y
                    x -= SYStylePaddingBottom(blkStyle, inlStyle, currentBlockRun->rect.size.width);
                    x -= SYStyleMarginBottom(blkStyle, inlStyle, currentBlockRun->rect.size.width);
                    y = _minY;
                    
                    // Get number of columns
                    int columnsOfChildren = 0;
                    for (SYTextRun* r = currentBlockRun; r && r != run; r = SYTextRunContextNextRun(_runContext, r)) {
                        if (r->type == SYRunTypeBlockBegin)
                            columnsOfChildren += r->numberOfColumnBreaks;
                    }
                    currentBlockRun->numberOfColumnBreaks = columnsOfChildren + columnBreakCount;
                }
                
                // Set popped block run
                currentBlockRun = poppedBlockRun;
            }
            
            // Increment line count
            lineCount++;
        }
        
        // ------------------------------------------------------------ //
        #pragma mark └ Next run
        // ------------------------------------------------------------ //
        
        nextRun: {
//NSLog(@"runId %d, text %@, rect %@, lineCount %d", run->runId, run->type == SYRunTypeText ? SYTextRunStringWithRun(run) : @"", NSStringFromCGRect(run->rect), lineCount);
            // Get next run
            run = SYTextRunContextIterateNext(_runContext);
        }
    }
    
    // Update block rects
    [self _updateBlockRects];
    
#if 0
    // For vertical
    if (x < 0) {
        // Move origin x
        SYTextRunContextBeginIteration(_runContext);
        run = SYTextRunContextIterateNext(_runContext);
        while (run) {
            run->rect.origin.x -= x;
            
            // Get next run
            run = SYTextRunContextIterateNext(_runContext);
        }
    }
#endif
    
    // Free run stack
    SYTextRunStackRelease(blockRunStack), blockRunStack = NULL;
    SYTextRunStackRelease(inlineRunStack), inlineRunStack = NULL;
}

- (BOOL)layoutWithParser:(SYTextParser*)parser
{
    // Set run context
    _runContext = parser.runContext;
    
    // Update glyphs and rect
    [self _updateGlyphsAndRect];
    
    // Layout
    [self _layoutWithParser:parser];
    
    return YES;
}

@end

//--------------------------------------------------------------//
#pragma mark -- Utility --
//--------------------------------------------------------------//

BOOL SYTextLayoutIsTateChuYoko(
        SYTextRun* run, 
        SYTextInlineStyle* inlineStyle)
{
    return inlineStyle->writingMode == SYStyleWritingModeTbRl && 
            run->textLength == 2 && 
            _isHalfWidthNumericGlyph(run->glyphs[0]) && 
            _isHalfWidthNumericGlyph(run->glyphs[1]);
}
