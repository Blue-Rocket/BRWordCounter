//
//  BRWordCountDelegate.h
//  BRWordCounter
//
//  Created by Matt on 12/04/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BRWordCountHelper;

/**
 A delegate protocol to respond to word counting events.
 */
@protocol BRWordCountDelegate <NSObject>

/**
 Called when the count of words has changed.
 
 @param counter The counter monitoring the word count.
 @param count   The new word count.
 */
- (void)wordCounter:(BRWordCountHelper *)counter wordCountDidChange:(NSUInteger)count;

@end
