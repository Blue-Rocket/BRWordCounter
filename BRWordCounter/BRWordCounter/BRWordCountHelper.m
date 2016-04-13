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

static NSRegularExpression *LastWordWithPunctuationRegularExpression() {
	static NSRegularExpression *LastWordWithPunctuation;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		LastWordWithPunctuation = [NSRegularExpression regularExpressionWithPattern:@"\\b\\w+\\W+$" options:NSRegularExpressionUseUnicodeWordBoundaries error:nil];
	});
	return LastWordWithPunctuation;
}

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
		NSUInteger startingWordCount = wordCount;
		__block NSUInteger replacedWords = 0;
		__block NSUInteger addedWords = 0;
		__block NSUInteger newWords = 0;
		__block BOOL startsInWord = NO;
		__block BOOL endsInWord = NO;
		__block NSRange firstAddedWordRange = NSMakeRange(NSNotFound, 0);
		
		[oldText enumerateSubstringsInRange:NSMakeRange(0, range.location) options:(NSStringEnumerationByWords|NSStringEnumerationReverse) usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			BRLog(@"Old text “%@” word “%@” found at %@; %@", oldText, [oldText substringWithRange:substringRange], NSStringFromRange(substringRange), NSStringFromRange(range));
			NSUInteger maxRange = NSMaxRange(substringRange);
			if ( maxRange == range.location ) {
				startsInWord = YES;
			}
			*stop = YES;
		}];
		[oldText enumerateSubstringsInRange:NSMakeRange(range.location, oldText.length - range.location) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			BRLog(@"Old text “%@” word “%@” found at %@; %@", oldText, [oldText substringWithRange:substringRange], NSStringFromRange(substringRange), NSStringFromRange(range));
			if ( substringRange.location > replacedTextEnd ) {
				*stop =YES;
				return;
			}
			if ( NSLocationInRange(replacedTextEnd, substringRange) ) {
				endsInWord = YES;
			}
			if ( !((substringRange.location == range.location && startsInWord) || endsInWord) ) {
				replacedWords += 1;
			}
			if ( NSMaxRange(substringRange) >= replacedTextEnd ) {
				*stop = YES;
			}
		}];
		
		[text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable word, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
			BRLog(@"New text “%@” word “%@” found at %@", text, [text substringWithRange:substringRange], NSStringFromRange(substringRange));
			newWords += 1;
			if ( !((substringRange.location == 0 && startsInWord) || (NSMaxRange(substringRange) == text.length && endsInWord)) || (startsInWord && endsInWord && addedWords > 0) ) {
				addedWords += 1;
				if ( firstAddedWordRange.location == NSNotFound ) {
					firstAddedWordRange = substringRange;
				}
			}
		}];
		
		__block NSInteger diff = (addedWords - replacedWords);
		
		if ( startsInWord && endsInWord && newWords == 0 && range.length == 0 && text.length > 0 ) {
			// split word in two
			diff += 1;
		} else if ( firstAddedWordRange.location == 0 && [oldText rangeOfCharacterFromSet:[NSCharacterSet punctuationCharacterSet] options:(NSBackwardsSearch|NSAnchoredSearch)].location != NSNotFound ) {
			// edge case of going from "don'" -> "don't"; we don't know that's actually a single word unless we combine the old + new text and look
			// try to be easy on copying large strings here... by looking for a word boundary that can serve as our contraction prefix
			NSRange wordRange = [LastWordWithPunctuationRegularExpression() rangeOfFirstMatchInString:oldText options:0 range:NSMakeRange(0, range.location)];
			if ( wordRange.location != NSNotFound ) {
				NSString *possibleSingleWord = [[oldText substringWithRange:wordRange] stringByAppendingString:text];
				[possibleSingleWord enumerateSubstringsInRange:NSMakeRange(0, possibleSingleWord.length) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
					BRLog(@"Possible combined text “%@” word “%@” found at %@", possibleSingleWord, [possibleSingleWord substringWithRange:substringRange], NSStringFromRange(substringRange));
					if ( substringRange.location == 0 && substringRange.length > wordRange.length ) {
						diff -= 1;
					}
					*stop = YES;
				}];
			}
		}
		
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
