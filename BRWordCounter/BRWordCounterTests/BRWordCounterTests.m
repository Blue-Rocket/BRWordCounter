//
//  BRWordCounterTests.m
//  BRWordCounterTests
//
//  Created by Matt on 12/04/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#import <OCMock/OCMock.h>

#import "BRWordCountDelegate.h"
#import "BRWordCountHelper.h"

@interface TestDelegate <BRWordCountDelegate>

@end

@interface BRWordCounterTests : XCTestCase

@end

@implementation BRWordCounterTests

- (void)testTyping {
	BRWordCountHelper *counter = [BRWordCountHelper new];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	__block NSUInteger i = 0;
	__block NSUInteger wordIndex = 0;
	NSUInteger len;
	NSString *textToType = @"This is the text I want to type.";
	NSArray<NSNumber *> *wordIndexes = @[@0, @5, @8, @12, @16, @18, @23, @26];
	
	__block NSUInteger resolvedWordCount = 0;

	for ( i = 0, len = textToType.length; i < len; i += 1 ) {
		if ( wordIndex < wordIndexes.count && i >= [wordIndexes[wordIndex] unsignedIntegerValue] ) {
			wordIndex += 1;
			NSUInteger idx = wordIndex;
			NSLog(@"Expecting notification for word count %@", @(idx));
			[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
				resolvedWordCount = [notification.userInfo[@"wordCount"] unsignedIntegerValue];
				BOOL resolved = (resolvedWordCount == idx);
				NSLog(@"Notification word count %@ resolved %@", notification.userInfo[@"wordCount"], (resolved ? @"YES" : @"NO"));
				return resolved;
			}];
			OCMExpect([delegate wordCounter:counter wordCountDidChange:idx])
				.andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter userInfo:@{@"wordCount":@(idx)}]);
		}
		OCMExpect([textViewMock text]).andReturn([textToType substringToIndex:i]);
		NSString *typedText = [textToType substringWithRange:NSMakeRange(i, 1)];
		[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(i, 0) replacementText:typedText];
	}
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(8));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testTypingBackspaceAtEnd {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:8];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *textToType = @"This is the text I want to type.";
	NSArray<NSNumber *> *wordIndexes = @[@0, @5, @8, @12, @16, @18, @23, @26];
	__block NSUInteger i = textToType.length;
	__block NSUInteger wordIndex = 7;
	
	__block NSUInteger resolvedWordCount = 0;
	
	for ( ; i > 0; i -= 1 ) {
		if ( wordIndex > 0 && i < [wordIndexes[wordIndex] unsignedIntegerValue] ) {
			wordIndex -= 1;
			NSUInteger idx = wordIndex;
			NSLog(@"Expecting notification for word count %@", @(idx));
			[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
				resolvedWordCount = [notification.userInfo[@"wordCount"] unsignedIntegerValue];
				BOOL resolved = (resolvedWordCount == idx);
				NSLog(@"Notification word count %@ resolved %@", notification.userInfo[@"wordCount"], (resolved ? @"YES" : @"NO"));
				return resolved;
			}];
			OCMExpect([delegate wordCounter:counter wordCountDidChange:idx])
				.andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter userInfo:@{@"wordCount":@(idx)}]);
		}
		OCMExpect([textViewMock text]).andReturn([textToType substringToIndex:i]);
		NSString *typedText = @"";
		[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(i - 1, 1) replacementText:typedText];
	}
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(0));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testPasteAtStartAddWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;

	NSString *startingText = @"This is the text.";
	NSString *insertText = @"More text. ";

	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:6]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(6));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testPasteAtStartUnchangedWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text.";
	NSString *insertText = @"BUT";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:insertText];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(4));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

@end
