//
//  BRWordCountHelper.m
//  BRWordCounter
//
//  Created by Matt on 12/04/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "BRWordCountHelper.h"

#import "BRWordCountDelegate.h"

#if (DEBUG)
#define BRLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define BRLog(...)
#endif

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

- (instancetype)initWithTextView:(UITextView *)textView delegate:(nullable id<BRWordCountDelegate>)delegate {
	if ( (self = [self initWithWordCount:0]) ) {
		textView.delegate = self;
		self.delegate = delegate;
		[BRWordCountHelper countWordsInString:textView.text queue:queue finished:^(NSUInteger count) {
			wordCount = count;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate wordCounter:self wordCountDidChange:count];
			});
		}];
	}
	return self;
}

// this method is here with OS X in mind, to support NSTextView by changing the view parameter to id
static inline NSString *CurrentTextInView(UITextView *view) {
	return view.text;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	NSString *oldText = CurrentTextInView(textView);
	NSUInteger replacedTextEnd = NSMaxRange(range);

	dispatch_async(queue, ^{
		
		// The general strategy used here is to examine the current text for word boundaries before/after the changing range, and then
		// compare the number of words in that range to the equivalent range in the updated text. This allows for contractions that
		// are formed or removed to be counted correctly without counting all words in the entire updated text each time.
		
		NSUInteger startingWordCount = wordCount;
		__block NSUInteger start = range.location;
		__block NSUInteger end = replacedTextEnd;
		__block NSUInteger replacedWordCount = 0;
		__block NSUInteger addedWordCount = 0;
		
		// find the start of word before our change range
		[oldText enumerateSubstringsInRange:NSMakeRange(0, range.location) options:(NSStringEnumerationByWords|NSStringEnumerationReverse|NSStringEnumerationSubstringNotRequired) usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			BRLog(@"Old text “%@” word “%@” found at %@; %@", oldText, [oldText substringWithRange:substringRange], NSStringFromRange(substringRange), NSStringFromRange(range));
			start = substringRange.location;
			*stop = YES;
		}];
		
		// count all words being replaced, and note the end of the last word after change range
		[oldText enumerateSubstringsInRange:NSMakeRange(start, oldText.length - start) options:(NSStringEnumerationByWords|NSStringEnumerationSubstringNotRequired) usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			BRLog(@"Old text “%@” word “%@” found at %@; %@", oldText, [oldText substringWithRange:substringRange], NSStringFromRange(substringRange), NSStringFromRange(range));
			if ( substringRange.location > replacedTextEnd ) {
				*stop = YES;
			} else {
				replacedWordCount += 1;
				end = NSMaxRange(substringRange);
			}
		}];
		
		if ( end < replacedTextEnd ) {
			end = replacedTextEnd;
		}
		
		NSString *oldPassage = [oldText substringWithRange:NSMakeRange(start, end - start)];
		NSRange replaceRange = NSMakeRange(range.location - start, range.length);
		NSString *newPassage = [oldPassage stringByReplacingCharactersInRange:replaceRange withString:text];
		
		// count the words we now have
		[newPassage enumerateSubstringsInRange:NSMakeRange(0, newPassage.length) options:(NSStringEnumerationByWords|NSStringEnumerationSubstringNotRequired) usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			BRLog(@"Next text “%@” word “%@” found at %@; %@", newPassage, [newPassage substringWithRange:substringRange], NSStringFromRange(substringRange), NSStringFromRange(range));
			addedWordCount += 1;
		}];
		
		// our final count is the difference between what we have now and what we used to have
		NSInteger diff = (addedWordCount - replacedWordCount);
		NSUInteger finalWordCount = (startingWordCount + diff);
		BRLog(@"Got final word count %lu for text: %@", (unsigned long)finalWordCount, [oldText stringByReplacingCharactersInRange:range withString:text]);
		if ( wordCount != finalWordCount ) {
			[self willChangeValueForKey:@"wordCount"];
			wordCount = finalWordCount;
			[self didChangeValueForKey:@"wordCount"];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate wordCounter:self wordCountDidChange:finalWordCount];
			});
		}
	});
	
	return YES;
}

+ (void)countWordsInString:(NSString *)string finished:(void (^)(NSUInteger wordCount))callback {
	[self countWordsInString:string queue:nil finished:callback];
}

+ (void)countWordsInString:(NSString *)string queue:(dispatch_queue_t)queue finished:(void (^)(NSUInteger wordCount))callback {
	if ( !callback ) {
		return;
	}
	if ( !queue ) {
		queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	}
	dispatch_async(queue, ^{
		__block NSUInteger count = 0;
		[string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			count += 1;
		}];
		dispatch_async(dispatch_get_main_queue(), ^{
			callback(count);
		});
	});
}

@end
