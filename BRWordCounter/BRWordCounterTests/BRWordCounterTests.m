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

- (void)testCountWordsNilString {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:nil finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(0));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
#pragma clang diagnostic pop
}

- (void)testCountWordsNilCallback {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	[BRWordCountHelper countWordsInString:@"FOO" finished:nil];
#pragma clang diagnostic pop
}

- (void)testCountWordsEmptyString {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"" finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(0));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCountWord {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"word" finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(1));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCountWordWithWhitespace {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"\n word \n" finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(1));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCountWordsWithPunctuation {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"Here, we have an actual (lovely) sentence; behold!" finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(8));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCountWordsWithPossessives {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"The dude's beard grows! The ladies' handbags grow!" finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(8));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCountWordsWithFancyPossessives {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"The dude’s beard grows! The ladies’ handbags grow!" finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(8));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCountWordsWithSingleQuotes {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"The 'quoted' string." finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(3));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInitializeWithTextView {
	id textView = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	NSString *initialText = @"Here is some text for you to start with.";
	NSUInteger expectedCount = 9;

	OCMExpect([textView text]).andReturn(initialText);
	OCMExpect([delegate wordCounter:anything() wordCountDidChange:expectedCount])
		.andPost([NSNotification notificationWithName:@"WordCountDidChange" object:nil]);
	
	[self expectationForNotification:@"WordCountDidChange" object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];

	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithTextView:textView delegate:delegate];
	
	[self waitForExpectationsWithTimeout:1 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(expectedCount));

	OCMVerifyAll(textView);
	OCMVerifyAll(delegate);
}

- (void)testInitializeWithEmptyTextView {
	id textView = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	NSString *initialText = @"";
	NSUInteger expectedCount = 0;
	
	OCMExpect([textView text]).andReturn(initialText);
	OCMExpect([delegate wordCounter:anything() wordCountDidChange:expectedCount])
	.andPost([NSNotification notificationWithName:@"WordCountDidChange" object:nil]);
	
	[self expectationForNotification:@"WordCountDidChange" object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithTextView:textView delegate:delegate];
	
	[self waitForExpectationsWithTimeout:1 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(expectedCount));
	
	OCMVerifyAll(textView);
	OCMVerifyAll(delegate);
}

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

- (void)testTypingDeleteAtBeginning {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:8];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *textToType = @"This is the text I want to type.";
	NSMutableArray<NSNumber *> *wordIndexes = [@[@5, @8, @12, @16, @18, @23, @26, @29] mutableCopy];
	__block NSUInteger i = 0;
	NSUInteger len = textToType.length;
	
	__block NSUInteger resolvedWordCount = 0;
	
	for ( ; i < len; i += 1 ) {
		if ( wordIndexes.count > 0 && i >= [wordIndexes[0] unsignedIntegerValue] ) {
			[wordIndexes removeObjectAtIndex:0];
			NSUInteger idx = wordIndexes.count;
			NSLog(@"Expecting notification for word count %@", @(idx));
			[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
				resolvedWordCount = [notification.userInfo[@"wordCount"] unsignedIntegerValue];
				BOOL resolved = (resolvedWordCount == idx);
				NSLog(@"Notification word count %@ resolved to %@: %@", notification.userInfo[@"wordCount"], @(idx), (resolved ? @"YES" : @"NO"));
				return resolved;
			}];
			OCMExpect([delegate wordCounter:counter wordCountDidChange:idx])
				.andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter userInfo:@{@"wordCount":@(idx)}]);
		}
		OCMExpect([textViewMock text]).andReturn([textToType substringFromIndex:i]);
		NSString *typedText = @"";
		[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(0, 1) replacementText:typedText];
	}
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(0));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testInsertCharacterAtBeginningInWord {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text.";
	NSString *insertText = @"M";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:insertText];
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);

	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(4));
}

- (void)testInsertCharacterAtEndOfWord {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"Thi is the text.";
	NSString *insertText = @"s";
	NSRange replaceRange = NSMakeRange(3, 0);
	NSUInteger finalWordCount = 4;
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
}

- (void)testInsertSpaceInFirstWord {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:3];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"Donot think so.";
	NSString *insertText = @" ";
	NSRange replaceRange = NSMakeRange(2, 0);
	NSUInteger finalWordCount = 4;
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:finalWordCount]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	
	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
}

- (void)testInsertSpaceInMiddleWord {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:6];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"Do or donot the saying goes.";
	NSString *insertText = @" ";
	NSRange replaceRange = NSMakeRange(8, 0);
	NSUInteger finalWordCount = 7;
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:finalWordCount]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	
	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
}

- (void)testInsertPossessiveAtEndOfWord {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:3];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"Don' stop believing.";
	NSString *insertText = @"t";
	NSRange replaceRange = NSMakeRange(4, 0);
	NSUInteger finalWordCount = 3;
	
	OCMExpect([textViewMock text]).andReturn(startingText);

	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];
	
	[NSThread sleepForTimeInterval:0.2];

	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
}

- (void)testCountWordsWithAlmostContraction {
	XCTestExpectation *expectation = [self expectationWithDescription:@"Count"];
	[BRWordCountHelper countWordsInString:@"I on't believe it." finished:^(NSUInteger wordCount) {
		assertThatUnsignedInteger(wordCount, equalToUnsignedInteger(4));
		[expectation fulfill];
	}];
	[self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInsertPrefixCreatesContraction {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"I on't believe it.";
	NSString *insertText = @"d";
	NSRange replaceRange = NSMakeRange(2, 0);
	NSUInteger finalWordCount = 4;
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];
	
	[NSThread sleepForTimeInterval:0.2];
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
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

- (void)testPasteInMiddleOutsideWordBoundariesAddWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is--the text.";
	NSString *insertText = @"More text";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:6]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(8, 0) replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(6));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testPasteInMiddleWithinWordBoundariesAddWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:3];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is text.";
	NSString *insertText = @"MORE AND MORE TEXT";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:6]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(6, 0) replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(6));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testPasteInMiddleAtStartWordBoundaryAddWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:3];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is text.";
	NSString *insertText = @"MORE AND MORE TEXT";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:6]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(7, 0) replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(6));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testPasteInMiddleAtEndWordBoundaryAddWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:3];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is text.";
	NSString *insertText = @"MORE AND MORE TEXT";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:6]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(5, 0) replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(6));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testPasteAtEndAddWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text.";
	NSString *insertText = @" More text.";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:6]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);	
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(startingText.length, 0) replacementText:insertText];
	
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
	
	[NSThread sleepForTimeInterval:0.2];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(4));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
}

- (void)testPasteAtEndUnchangedWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text";
	NSString *insertText = @"BUT";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(startingText.length, 0) replacementText:insertText];
	
	[NSThread sleepForTimeInterval:0.2];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(4));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
}

- (void)testReplaceAtStartUnchangedWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text";
	NSString *insertText = @"THAT";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(0, 4) replacementText:insertText];
	
	[NSThread sleepForTimeInterval:0.2];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(4));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
}

- (void)testReplaceInMiddleUnchangedWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text";
	NSString *insertText = @"IS THE";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(5, 6) replacementText:insertText];
	
	[NSThread sleepForTimeInterval:0.2];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(4));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
}

- (void)testReplaceInMiddleCombineWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text";
	NSString *insertText = @"IS";
	NSRange replaceRange = NSMakeRange(5, 6);
	NSUInteger finalWordCount = 3;
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:finalWordCount]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];

	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testReplaceInMiddleAddWord {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text";
	NSString *insertText = @"IS NOT";
	NSRange replaceRange = NSMakeRange(5, 2);
	NSUInteger finalWordCount = 5;
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:finalWordCount]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

- (void)testReplaceAtEndUnchangedWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text";
	NSString *insertText = @"FOOBAR";
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	
	[counter textView:textViewMock shouldChangeTextInRange:NSMakeRange(12, 4) replacementText:insertText];
	
	[NSThread sleepForTimeInterval:0.2];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(4));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAllWithDelay(delegate, 0.1);
}

- (void)testReplaceAtEndAddWords {
	BRWordCountHelper *counter = [[BRWordCountHelper alloc] initWithWordCount:4];
	id textViewMock = OCMClassMock([UITextView class]);
	id delegate = OCMProtocolMock(@protocol(BRWordCountDelegate));
	counter.delegate = delegate;
	
	NSString *startingText = @"This is the text";
	NSString *insertText = @"TEXT, DUDE.";
	NSRange replaceRange = NSMakeRange(12, 4);
	NSUInteger finalWordCount = 5;
	
	OCMExpect([textViewMock text]).andReturn(startingText);
	OCMExpect([delegate wordCounter:counter wordCountDidChange:finalWordCount]).andPost([NSNotification notificationWithName:@"WordCountDidChange" object:counter]);
	[self expectationForNotification:@"WordCountDidChange" object:counter handler:^BOOL(NSNotification * _Nonnull notification) {
		return YES;
	}];
	
	[counter textView:textViewMock shouldChangeTextInRange:replaceRange replacementText:insertText];
	
	[self waitForExpectationsWithTimeout:2 handler:nil];
	
	assertThatUnsignedInteger(counter.wordCount, equalToUnsignedInteger(finalWordCount));
	
	OCMVerifyAll(textViewMock);
	OCMVerifyAll(delegate);
}

@end
