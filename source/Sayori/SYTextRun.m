/*
SYTextRun.m

Author: Makoto Kinoshita, Hajime Nakamura

Copyright 2010-2013 HMDT. All rights reserved.
*/

#import "SYTextRun.h"

//--------------------------------------------------------------//
#pragma mark -- Functions --
//--------------------------------------------------------------//

SYTextRunContext* SYTextRunContextCreate()
{
    // Allocate run context
    SYTextRunContext*   runContext;
    runContext = malloc(sizeof(SYTextRunContext));
    
    // Initialize run context
    runContext->runCount = 0;
    runContext->runPool = NULL;
    runContext->currentRunPool = NULL;
    runContext->currentRun = NULL;
    
    return runContext;
}

void SYTextRunContextRelease(
        SYTextRunContext* runContext)
{
    // Check argument
    if (!runContext) {
        return;
    }
    
    // Free runs
    SYTextRun*  run;
    SYTextRunContextBeginIteration(runContext);
    run = SYTextRunContextIterateNext(runContext);
    while (run) {
        // Free run instance values
        if (run->text && run->text != run->textBuffer) {
            free(run->text);
        }
        if (run->glyphs && run->glyphs != run->glyphBuffer) {
            free(run->glyphs);
        }
        if (run->advances && run->advances != run->advanceBuffer) {
            free(run->advances);
        }
        if ((run->type == SYRunTypeInlineBegin || 
             run->type == SYRunTypeRubyInlineBegin || 
             run->type == SYRunTypeRubyInlineEnd) && 
            run->inlineStyle)
        {
            if (run->inlineStyle->linkUrl) {
// Just for testing
#if 0
                CFRelease((__bridge CFTypeRef)(run->inlineStyle->linkUrl)), run->inlineStyle->linkUrl = nil;
#endif
            }
#if 0
            free(run->inlineStyle);
#endif
        }
        if (run->type == SYRunTypeBlockBegin && run->blockStyle) {
#if 0
            free(run->blockStyle);
#endif
        }
        if (run->rotateFlags) {
            free(run->rotateFlags);
        }
        
        // Get next run
        run = SYTextRunContextIterateNext(runContext);
    }
    
    // Free run pools
    SYTextRunPool*  runPool;
    runPool = runContext->runPool;
    while (runPool) {
        // Get next run pool
        SYTextRunPool*  nextRunPool;
        nextRunPool = runPool->nextPool;
        
        // Free run pool
        free(runPool);
        
        // Set next run pool
        runPool = nextRunPool;
    }
    
    // Free run context
    free(runContext);
}

SYTextRun* SYTextRunContextAllocateRun(
        SYTextRunContext* runContext)
{
    // Find next run
    SYTextRun*  run = NULL;
    
    // For no current run ppol
    if (!runContext->runPool) {
        // Create run pool
        SYTextRunPool*  runPool;
        runPool = runPool = malloc(sizeof(SYTextRunPool));
        runPool->prevPool = NULL;
        runPool->nextPool = NULL;
        
        // Set run pool
        runContext->runPool = runPool;
        runContext->currentRunPool = runPool;
        
        // Set run
        run = runPool->runs;
    }
    else {
        // When there are enough pool
        if (runContext->currentRun - runContext->currentRunPool->runs < SY_RUNPOOL_MAX - 1) {
            // Increment run
            run = runContext->currentRun + 1;
        }
        // When no extra run
        else {
            // Create run pool
            SYTextRunPool*  runPool;
            runPool = malloc(sizeof(SYTextRunPool));
            runPool->prevPool = runContext->currentRunPool;
            runPool->nextPool = NULL;
            
            // Set next run pool
            runContext->currentRunPool->nextPool = runPool;
            runContext->currentRunPool = runPool;
            
            // Set run
            run = runPool->runs;
        }
    }
    
    // Set prev and next run
    if (runContext->currentRun) {
        runContext->currentRun->nextRun = run;
    }
    run->prevRun = runContext->currentRun;
    run->nextRun = NULL;
    
    // Set current run
    runContext->currentRun = run;
    
    // Increment run count and set run ID
    run->runId = runContext->runCount++;
    
    // Init num of column breaks
    run->numberOfColumnBreaks = 0;
    
    // Clear flags
    run->rotateFlags = NULL;
    
    // Clear pointers
    run->text = NULL;
    run->glyphs = NULL;
    run->advances = NULL;
    run->inlineStyle = NULL;
    run->blockStyle = NULL;
    
    return run;
}

SYTextRun* SYTextRunContextPrevRun(
        SYTextRunContext* runContext, 
        SYTextRun* run)
{
    // For NULL
    if (!run) {
        // Get top run
        return runContext->runPool->runs;
    }
    
#if 1
    // Get prev run
    return run->prevRun;
#else
    // Find run in pool
    int             index = 0;
    SYTextRunPool*  runPool;
    runPool = runContext->runPool;
    while (runPool) {
        // For begin of pool
        if (run == runPool->runs) {
            // Check index
            if (index == 0) {
                return NULL;
            }
            
            // Get end of prev pool
            if (runPool->prevPool) {
                return ((SYTextRunPool*)runPool->prevPool)->runs + SY_RUNPOOL_MAX - 1;
            }
        }
        // Check with pool
        else if (run > runPool->runs && run < runPool->runs + SY_RUNPOOL_MAX - 1) {
            // Check index
            index += run - runPool->runs;
            if (index >= runContext->runCount) {
                return NULL;
            }
            
            // Get prev run
            return run - 1;
        }
        
        // Get next run pool
        runPool = runPool->nextPool;
        index += SY_RUNPOOL_MAX;
    }
    
    return NULL;
#endif
}

SYTextRun* SYTextRunContextNextRun(
        SYTextRunContext* runContext, 
        SYTextRun* run)
{
    // For NULL
    if (!run) {
        // Get top run
        return runContext->runPool->runs;
    }
    
#if 1
    return run->nextRun;
#else
    // Find run in pool
    int             index = 0;
    SYTextRunPool*  runPool;
    runPool = runContext->runPool;
    while (runPool) {
        // Check with pool
        if (run >= runPool->runs && run < runPool->runs + SY_RUNPOOL_MAX - 1) {
            // Check index
            index += run - runPool->runs;
            if (index >= runContext->runCount - 1) {
                return NULL;
            }
            
            // Get next run
            return run + 1;
        }
        // For end of pool
        else if (run == runPool->runs + SY_RUNPOOL_MAX - 1) {
            // Check index
            index += SY_RUNPOOL_MAX;
            if (index >= runContext->runCount) {
                return NULL;
            }
            
            // Get top of next pool
            if (runPool->nextPool) {
                return ((SYTextRunPool*)runPool->nextPool)->runs;
            }
        }
        
        // Get next run pool
        runPool = runPool->nextPool;
        index += SY_RUNPOOL_MAX;
    }
    
    return NULL;
#endif
}

SYTextRun* SYTextRunContextPrevTextRun(
           SYTextRunContext* runContext,
           SYTextRun* run)
{
    // Filter
    if (!run) return NULL;
    
    SYTextRun* tmpRun = run;
    while ((tmpRun = SYTextRunContextPrevRun(runContext, tmpRun))) {
        // For text run
        if (tmpRun->type == SYRunTypeText) return tmpRun;
        
        // For block begin / end
        if (tmpRun->type == SYRunTypeBlockBegin ||
            tmpRun->type == SYRunTypeBlockEnd)
        {
            return NULL;
        }
    }
    
    return NULL;
}

SYTextRun* SYTextRunContextNextTextRun(
           SYTextRunContext* runContext,
           SYTextRun* run)
{
    // Filter
    if (!run) return NULL;
        
    SYTextRun* tmpRun = run;
    while ((tmpRun = SYTextRunContextNextRun(runContext, tmpRun))) {
        // For text run
        if (tmpRun->type == SYRunTypeText) return tmpRun;
        
        // For block begin / end
        if (tmpRun->type == SYRunTypeBlockBegin ||
            tmpRun->type == SYRunTypeBlockEnd)
        {
            return NULL;
        }        
    }
    
    return NULL;
}


void SYTextRunContextBeginIteration(
        SYTextRunContext* runContext)
{
    // Check argument
    if (!runContext) {
        return;
    }
    
    // Reset current run
    runContext->currentRunPool = runContext->runPool;
    runContext->currentRun = NULL;
    runContext->currentIndex = 0;
}

SYTextRun* SYTextRunContextIteratePrev(
        SYTextRunContext* runContext)
{
    // Check current run index
    if (runContext->currentIndex == 0) {
        return NULL;
    }
    
    // Find prev run
    SYTextRunPool*  runPool = NULL;
    SYTextRun*      run = NULL;
    
    // For begin
    if (!runContext->currentRun) {
        return NULL;
    }
    // When there are enough pool
    else if (runContext->currentRun - runContext->currentRunPool->runs > 1) {
        // Decrement run
        runPool = runContext->currentRunPool;
        run = runContext->currentRun - 1;
    }
    // When no extra run
    else {
        // Check prev run pool
        if (runContext->currentRunPool->prevPool) {
            // Set prev run pool
            runPool = runContext->currentRunPool->prevPool;
            
            // Set run
            run = runPool->runs + SY_RUNPOOL_MAX - 1;
        }
    }
    
    // Set current run
    runContext->currentRunPool = runPool;
    runContext->currentRun = run;
    runContext->currentIndex--;
    
    return run;
}

SYTextRun* SYTextRunContextIterateNext(
        SYTextRunContext* runContext)
{
    // Check argument
    if (!runContext) {
        return NULL;
    }
    
    // Check current run index
    if (runContext->currentIndex >= runContext->runCount) {
        return NULL;
    }
    
    // Find next run
    SYTextRunPool*  runPool = NULL;
    SYTextRun*      run = NULL;
    
    // For begin
    if (!runContext->currentRun) {
        // Use top run
        runPool = runContext->runPool;
        run = runPool->runs;
    }
    // When there are enough pool
    else if (runContext->currentRun - runContext->currentRunPool->runs < SY_RUNPOOL_MAX - 1) {
        // Increment run
        runPool = runContext->currentRunPool;
        run = runContext->currentRun + 1;
    }
    // When no extra run
    else {
        // Get next run pool
        if (runContext->currentRunPool->nextPool) {
            // Set next run pool
            runPool = runContext->currentRunPool->nextPool;
            
            // Set run
            run = runPool->runs;
        }
    }
    
    // Set current run
    runContext->currentRunPool = runPool;
    runContext->currentRun = run;
    runContext->currentIndex++;
    
    return run;
}

NSString* SYTextRunStringWithRun(
        SYTextRun* run)
{
    // Check argument
    if (!run) {
        return nil;
    }
    
    // Check run type
    if (run->type != SYRunTypeText && run->type != SYRunTypeRubyText) {
        return nil;
    }
    
    // Check text
    if (!run->text) {
        return nil;
    }
    
    // Create string
    return [NSString stringWithCharacters:run->text length:run->textLength];
}

NSString* SYTextRunContextStringBetweenRun(
        SYTextRunContext* runContext, 
        SYTextRun* beginRun, 
        SYTextRun* endRun)
{
    // Get run text
    NSMutableString*    string;
    SYTextRun*          tmpRun;
    string = [NSMutableString string];
    tmpRun = beginRun;
    while (tmpRun) {
        // For text run
        if (tmpRun->type == SYRunTypeText) {
            // Append string
            [string appendString:[NSString stringWithCharacters:tmpRun->text length:tmpRun->textLength]];
        }
        
        // Check with end run
        if (tmpRun->runId >= endRun->runId) {
            break;
        }
        
        // Get next run
        tmpRun = SYTextRunContextNextRun(runContext, tmpRun);
    }
    
    return string;
}

SYTextRunStack* SYTextRunStackCreate()
{
    // Allocate run stack
    SYTextRunStack* runStack;
    runStack = malloc(sizeof(SYTextRunStack));
    
    // Initialize run stack
    runStack->currentRun = runStack->runs;
    
    return runStack;
}

void SYTextRunStackRelease(
        SYTextRunStack* runStack)
{
    // Check argument
    if (!runStack) {
        return;
    }
    
    // Free run stack
    free(runStack);
}

void SYTextRunStackPush(
        SYTextRunStack* runStack, 
        SYTextRun* run)
{
    // Check count
    if (runStack->currentRun - runStack->runs >= SY_RUNSTACK_MAX - 1) {
        NSLog(@"Stack exceeds limit");
        
        return;
    }
    
    // Push run
    *(runStack->currentRun) = run;
    runStack->currentRun++;
}

SYTextRun* SYTextRunStackPop(
        SYTextRunStack* runStack)
{
    // Check current run
    if (runStack->currentRun == runStack->runs) {
        return NULL;
    }
    
    // Pop run
    runStack->currentRun--;
    
    return *(runStack->currentRun);
}

SYTextRun* SYTextRunStackTop(
        SYTextRunStack* runStack)
{
    // For empty
    if (runStack->currentRun == runStack->runs) {
        return NULL;
    }
    
    // Get top run
    return *(runStack->currentRun - 1);
}
