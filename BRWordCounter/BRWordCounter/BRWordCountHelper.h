//
//  BRWordCountHelper.h
//  BRWordCounter
//
//  Created by Matt on 12/04/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BRWordCountDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 Class to efficiently keep track of the word count of an editable text view. As changes
 are made to the text in the configured text view, this class will calculate the total 
 word count of the text in the background, and then call on a @c BRWordCountDelegate
 instance with the results.
 
 This class works by setting it as the delegate of a @c UITextView. The only method
 this delegate actually uses is @c textView:shouldChangeTextInRange:replacementText:
 however, so you can forward that method call to this object if you already have a
 delegate configured on a text view you'd also like to track the word count on.
 */
@interface BRWordCountHelper : NSObject <UITextViewDelegate>

/** The delegate to respond to word count events. */
@property (nonatomic, strong, nullable) id<BRWordCountDelegate> delegate;

/** The current word count. */
@property (nonatomic, readonly) NSUInteger wordCount;

/**
 Initialize with a pre-computed word count.
 
 Use this method if you already know the word count and only need to track changes.
 
 @param count The know word count.
 
 @return The initialized instance.
 */
- (instancetype)initWithWordCount:(NSUInteger)count;


/**
 Initialize with a text view. The receiver will become the view's delegate. If you do not want the delegate to be set,
 use the @c initWithWordCount: method instead, passing in the current word count of the text view. The initial word
 count will be calculated from the provided @c textView in the background. Pass a non-nil @c delegate to be notified
 of the initial word count.
 
 @param textView The text view to become the delegate of and track word chagnes.
 @param delegate The count delegate.
 
 @return The initialized instance.
 */
- (instancetype)initWithTextView:(UITextView *)textView delegate:(nullable id<BRWordCountDelegate>)delegate;

/**
 Utility method to asynchronously count the words in a document.
 
 @param string   The string to count the words in.
 @param callback A callback to pass the word count to. The callback will be invoked on the main thread.
 */
+ (void)countWordsInString:(NSString *)string finished:(void (^)(NSUInteger wordCount))callback;

@end

NS_ASSUME_NONNULL_END
