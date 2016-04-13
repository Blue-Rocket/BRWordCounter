# BRWordCounter

BRWordCounter is a small Objective-C helper for efficiently counting words in a `UITextView` while
editing happens.

Here is an example of how to use the helper, in a `UIViewController` subclass:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    UITextView *textView = self.textView;
    self.counter = [[BRWordCountHelper alloc] initWithTextView:textView delegate:self];
}

- (void)wordCounter:(BRWordCountHelper *)counter wordCountDidChange:(NSUInteger)count {
    UILabel *wordCountLabel = self.wordCountLabel;
    wordCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)count];
}
```

There is also a utility method available for counting words in a string:

```objc
[BRWordCountHelper countWordsInString:@"The 'quoted' string." finished:^(NSUInteger wordCount) {
    // wordCount == 3 here
}];
```


# Custom UITextViewDelegate

By default the `BRWordCountHelper` class expects to be configured as the `delegate` on the
`UITextView` it counts the words of. If you need to have a different delegate, you can do
so as long as you forward one delegate method on to the `BRWordCountHelper` as well:
`textView:shouldChangeTextInRange:replacementText:`. For example:

```objc
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // forward this call to our counter...
    [counter textView:textView shouldChangeTextInRange:range replacementText:text];

    // do whatever else needed here...

    return YES;
}

```


# Sample App

See the `CountedWords` example iPhone app that comes with the source for a simple example
of the code in action.


# Project Integration

You can integrate BRWordCounter via [CocoaPods](https://cocoapods.org/) or manually as
a dependent project.

## via CocoaPods

Install CocoaPods if not already available:

```bash
$ [sudo] gem install cocoapods
$ pod setup
```

Change to the directory of your Xcode project, and create a file named `Podfile` with
contents similar to this:

```ruby
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.1'

target :MyApp do
    pod 'BRWordCounter', '~> 2.0'
end

```
Install into your project:

``` bash
$ pod install
```

Open your project in Xcode using the **.xcworkspace** file CocoaPods generated.
