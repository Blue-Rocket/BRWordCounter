//
//  ViewController.m
//  CountedWords
//
//  Created by Matt on 13/04/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "ViewController.h"

#import <BRWordCounter/BRWordCounter.h>

@interface ViewController () <BRWordCountDelegate>
@property (strong, nonatomic) IBOutlet UILabel *wordCountLabel;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@end

@implementation ViewController {
	BRWordCountHelper *counter;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self reset:nil];
}

- (void)wordCounter:(BRWordCountHelper *)counter wordCountDidChange:(NSUInteger)count {
	self.wordCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)count];
}

- (IBAction)reset:(id)sender {
	counter = nil;
	counter = [[BRWordCountHelper alloc] initWithTextView:self.textView delegate:self];
}

@end
