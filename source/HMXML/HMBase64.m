/*
 HMBase64.m
 
 Author: Kazki Miura
 
 Copyright 2009 HMDT. All rights reserved.
*/

#import "HMBase64.h"


static char base64EncodingTable[64] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

NSData* HMDataFromBase64String(
        NSString* string)
{
	// Check string
	if (!string) {
		return [NSData data];
	}
	
	// Get string info
	const char *utf8String;
	NSUInteger stringLength;
	utf8String = [string UTF8String];
	stringLength = [string length];
	
	// Create result data
	NSMutableData *result;
	result = [NSMutableData data];
	
	// Append bytes to result data
	unsigned char ch, inputs[4] = { 0, 0, 0, 0 }, outputs[3] = { 0, 0, 0 };
	short input;
	BOOL shouldEnd = NO;
	input = 0;
	for (NSUInteger location = 0; location < stringLength; location++) {
		// Get character at location
		ch = utf8String[location];
		if (ch >= 'A' && ch <= 'Z') {
			ch = ch - 'A';
		}
		else if (ch >= 'a' && ch <= 'z') {
			ch = ch - 'a' + 26;
		}
		else if (ch >= '0' && ch <= '9') {
			ch = ch - '0' + 52;
		}
		else if (ch == '+') {
			ch = 62;
		}
		else if (ch == '=') {
			shouldEnd = YES;
		}
		else if (ch == '/') {
			ch = 63;
		}
		else {
			// Ignore the character
			continue;
		}
		
		// Calc character count
		short charCount = 3;
		if (shouldEnd) {
			// Check input
			if (input == 0) {
				break;
			}
			if (input == 1 || input == 2) {
				charCount = 1;
			}
			else {
				charCount = 2;
			}
			
			input = 3;
		}
		
		// Append bytes
		inputs[input++] = ch;
		if (input == 4) {
			input = 0;
			outputs[0] = (inputs[0] << 2) | ((inputs[1] & 0x30) >> 4);
			outputs[1] = ((inputs[1] & 0x0F) << 4) | ((inputs[2] & 0x3C) >> 2);
			outputs[2] = ((inputs[2] & 0x03) << 6) | (inputs[3] & 0x3F);
			for (short i = 0; i < charCount; i++) {
				[result appendBytes:&outputs[i] length:1];
			}
		}
		
		// End if needed
		if (shouldEnd) {
			break;
		}
	}
	
	return result;
}

NSString* HMBase64StringFromData(
		NSData *data,
		NSInteger length)
{
	// Get length and raw bytes from data
	NSUInteger dataLength;
	const unsigned char *raw;
	dataLength = [data length];
	if (dataLength < 1) {
		return @"";
	}
	raw = [data bytes];
	
    // Create buffer
    char*   buf;
    char*   tmp;
    buf = malloc(dataLength * 2);
    tmp = buf;
 	
	// Append characters to result
	unsigned long location;
	long remaining;
	unsigned char inputs[3], outputs[4];
	short charsOnLine = 0;
	short characterCount;
	location = 0;
	while ((remaining = dataLength - location) > 0) {
		// Supply inputs
		for (short i = 0; i < 3; i++) {
			if (location + i < dataLength) {
				inputs[i] = raw[location + i];
			}
			else {
				inputs[i] = 0;
			}
		}
		
		// Supply outputs
		outputs[0] = (inputs[0] & 0xFC) >> 2;
		outputs[1] = ((inputs[0] & 0x03) << 4) | ((inputs[1] & 0xF0) >> 4);
		outputs[2] = ((inputs[1] & 0x0F) << 2) | ((inputs[2] & 0xC0) >> 6);
		outputs[3] = inputs[2] & 0x3F;
		
		// Decide character count to append
		characterCount = 4;
		switch (remaining) {
		case 1 : {
			characterCount = 2;
			break;
		}
		case 2 : {
			characterCount = 3;
			break;
		}
		}
		
		// Append characters
		for (short i = 0; i < characterCount; i++) {
            *tmp++ = base64EncodingTable[outputs[i]];
		}
		for (short i = characterCount; i < 4; i++) {
            *tmp++ = '=';
		}
		
		// Update location and charsonline
		location += 3;
		charsOnLine += 4;
		
		// Insert new line
		if (length > 0) {
			if (charsOnLine >= length) {
				charsOnLine = 0;
				
                *tmp++ = '\n';
			}
		}
	}
    
    // Create result string
    NSString*   result;
    result = [[NSString alloc] initWithBytes:buf length:tmp - buf encoding:NSASCIIStringEncoding];
    [result autorelease];
    free(buf), buf = NULL;
	
	return result;
}
