//
//  CCPXCodeConsole.m
//
//  Copyright (c) 2013 Delisa Mason. http://delisa.me
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

#import "VWKXCodeConsole.h"

static NSMutableDictionary *sharedInstances;

@interface VWKXCodeConsole ()

@property (retain, nonatomic) NSTextView *console;
@property (strong, nonatomic) NSString *windowIdentifier;

@end


@implementation VWKXCodeConsole

- (id)initWithIdentifier:(NSString *)identifier
{
	if (self = [super init]) {
        _windowIdentifier = identifier;
	}

	return self;
}

- (NSTextView *)console
{
    if (!_console) {
        _console = [self findConsoleAndActivate];
    }
    return _console;
}

- (void)log:(id)obj
{
	[self appendText:[NSString stringWithFormat:@"%@\n", obj]];
}

- (void)error:(id)obj
{
	[self appendText:[NSString stringWithFormat:@"%@\n", obj]
               color:[NSColor redColor]];
}

- (void)appendText:(NSString *)text
{
	[self appendText:text color:nil];
}

- (NSWindow *)window
{
    for (NSWindow * window in [NSApp windows]) {
        if ([[window description] isEqualToString:self.windowIdentifier]) {
            return window;
        }
    }
    return nil;
}

- (void)appendText:(NSString *)text color:(NSColor *)color
{
	if (text.length == 0) return;
    
	if (!color)
		color = self.console.textColor;
    
	NSMutableDictionary *attributes = [@{ NSForegroundColorAttributeName: color } mutableCopy];
	NSFont *font = [NSFont fontWithName:@"Menlo Regular" size:11];
	if (font) {
		attributes[NSFontAttributeName] = font;
	}
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:text attributes:attributes];
	NSRange theEnd = NSMakeRange(self.console.string.length, 0);
	theEnd.location += as.string.length;
	if (NSMaxY(self.console.visibleRect) == NSMaxY(self.console.bounds)) {
		[self.console.textStorage appendAttributedString:as];
		[self.console scrollRangeToVisible:theEnd];
	} else {
		[self.console.textStorage appendAttributedString:as];
	}
}

#pragma mark - Class Methods

+ (instancetype)consoleForKeyWindow
{
    return [self consoleForWindow:[NSApp keyWindow]];
}

+ (instancetype)consoleForWindow:(NSWindow *)window
{
    if (window == nil)  return nil;

    NSString * key = [window description];

    if (!sharedInstances)
        sharedInstances = [[NSMutableDictionary alloc] init];

    if (!sharedInstances[key]) {
        VWKXCodeConsole *console = [[VWKXCodeConsole alloc] initWithIdentifier:key];
        [sharedInstances setObject:console forKey:key];
    }

    return sharedInstances[key];
}

#pragma mark - Console Detection


+ (NSView *)findConsoleViewInView:(NSView *)view
{
    Class consoleClass = NSClassFromString(@"IDEConsoleTextView");
    return [self findViewOfKind:consoleClass inView:view];
}

+ (NSView *)findViewOfKind:(Class)kind
                    inView:(NSView *)view
{
    if ([view isKindOfClass:kind]) {
		return view;
	}

	for (NSView *v in view.subviews) {
		NSView *result = [self findViewOfKind:kind
                                       inView:v];
		if (result) {
			return result;
		}
	}
	return nil;
}

- (NSTextView *)findConsoleAndActivate
{
	NSTextView *console = (NSTextView *)[[self class] findConsoleViewInView:self.window.contentView];
	if (console
     && [self.window isKindOfClass:NSClassFromString(@"IDEWorkspaceWindow")]
     && [self.window.windowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        id editorArea = [self.window.windowController valueForKey:@"editorArea"];
        [editorArea performSelector:@selector(activateConsole:) withObject:self];
	}

	[console.textStorage deleteCharactersInRange:NSMakeRange(0, console.textStorage.length)];
    
	return console;
}

@end
