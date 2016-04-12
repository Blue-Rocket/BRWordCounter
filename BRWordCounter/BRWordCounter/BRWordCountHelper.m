//
//  BRWordCountHelper.m
//  BRWordCounter
//
//  Created by Matt on 12/04/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "BRWordCountHelper.h"

#import "BRWordCountDelegate.h"

static const char * kWordCountQueueName = "us.bluerocket.BRWordCountHelper";

@implementation BRWordCountHelper {
	// our serial counting queue... only one count operation at a time (per/helper)
	dispatch_queue_t queue;
	NSUInteger wordCount;
}

@synthesize wordCount;

- (instancetype)init {
	return [self initWithWordCount:0];
}

- (instancetype)initWithWordCount:(NSUInteger)count {
	if ( (self = [super init]) ) {
		queue = dispatch_queue_create(kWordCountQueueName, DISPATCH_QUEUE_SERIAL);
		wordCount = count;
	}
	return self;
}

// this method is here with OS X in mind, to support NSTextView by changing the view parameter to id
static inline NSString *CurrentTextInView(UITextView *view) {
	return view.text;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	NSString *oldText = CurrentTextInView(textView);
	//NSString *replacedText = [oldText substringWithRange:range];
	NSUInteger oldTextMaxRange = NSMaxRange(range);
	NSUInteger expandedStart = (range.location > 0 ? range.location - 1 : 0);
	NSUInteger expandedEnd = (oldTextMaxRange < oldText.length ? oldTextMaxRange + 1 : oldText.length);
	NSRange expandedRange = NSMakeRange(expandedStart, expandedEnd - expandedStart);
	dispatch_async(queue, ^{
		NSUInteger startingWordCount = wordCount;
		__block NSUInteger replacedWords = 0;
		__block NSUInteger addedWords = 0;
		__block BOOL startsInWord = NO;
		__block BOOL endsInWord = NO;
		
		[oldText enumerateSubstringsInRange:expandedRange options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			NSLog(@"Old text “%@” word found at %@; %@", oldText, NSStringFromRange(substringRange), NSStringFromRange(range));
			NSUInteger maxRange = NSMaxRange(substringRange);
			if ( substringRange.location == expandedRange.location && (range.location > 0) ) {
				startsInWord = YES;
			}
			if ( maxRange == expandedEnd && (oldTextMaxRange < oldText.length) ) {
				endsInWord = YES;
			}
			if ( substringRange.location > range.location && maxRange < expandedEnd ) {
				replacedWords++;
			}
		}];
		
		[text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
			NSLog(@"Replacement text “%@” word found at %@", text, NSStringFromRange(substringRange));
			NSUInteger maxRange = NSMaxRange(substringRange);
			if ( substringRange.location == 0 ) {
				if ( !startsInWord ) {
					addedWords++;
				}
			} else if ( maxRange == text.length ) {
				if ( !endsInWord ) {
					addedWords++;
				}
			} else {
				addedWords++;
			}
		}];
		NSInteger diff = (addedWords - replacedWords);
		NSUInteger finalWordCount = (startingWordCount + diff);
		NSLog(@"Got final word count %lu for text: %@", (unsigned long)finalWordCount, [oldText stringByReplacingCharactersInRange:range withString:text]);
		if ( wordCount != finalWordCount ) {
			wordCount = finalWordCount;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate wordCounter:self wordCountDidChange:finalWordCount];
			});
		}
	});

	
	return YES;
}

@end
