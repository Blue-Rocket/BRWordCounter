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

@interface BRWordCountHelper : NSObject <UITextViewDelegate>

/** The delegate to respond to word count events. */
@property (nonatomic, strong, nullable) id<BRWordCountDelegate> delegate;

/** The current word count. */
@property (nonatomic, readonly) NSUInteger wordCount;

- (instancetype)initWithWordCount:(NSUInteger)count; // TODO: remove

@end

NS_ASSUME_NONNULL_END
