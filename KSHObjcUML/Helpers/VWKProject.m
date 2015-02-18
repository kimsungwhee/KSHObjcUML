//
//  CCPWorkspace.m
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

#import <objc/runtime.h>

#import "VWKProject.h"

#import "VWKWorkspaceManager.h"

@implementation VWKProject

+ (instancetype)projectForKeyWindow
{
	id workspace = [VWKWorkspaceManager workspaceForKeyWindow];

	id contextManager = [workspace valueForKey:@"_runContextManager"];
	for (id scheme in[contextManager valueForKey:@"runContexts"]) {
		NSString *schemeName = [scheme valueForKey:@"name"];
		if (![schemeName hasPrefix:@"Pods-"]) {
            NSString *path = [VWKWorkspaceManager directoryPathForWorkspace:workspace];
            NSString *projectName = [workspace valueForKey:@"name"];
			return [[VWKProject alloc] initWithName:schemeName path:path originalName:projectName];
		}
	}

	return nil;
}

- (id)initWithName:(NSString *)name
              path:(NSString *)path
originalName:(NSString *)originalName
{
	if (self = [self init]) {
        _projectOriginalName = originalName;
		_projectName = name;
		_podspecPath = [path stringByAppendingPathComponent:[name stringByAppendingString:@".podspec"]];
		_directoryPath = path;
        
		NSString *infoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@-Info.plist", _projectName, _projectName]];

		_infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPath];
		_podfilePath = [path stringByAppendingPathComponent:@"Podfile"];
	}
    
	return self;
}

- (BOOL)hasPodspecFile
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.podspecPath];
}

- (BOOL)hasPodfile
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.podfilePath];
}

- (void)createPodspecFromTemplate:(NSString *)_template
{
	NSMutableString *podspecFile    = _template.mutableCopy;
	NSRange range; range.location = 0;
    
	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@"<Project Name>"
	                             withString:self.projectName
	                                options:NSLiteralSearch
	                                  range:range];
    
	NSString *version = self.infoDictionary[@"CFBundleShortVersionString"];
	if (version) {
		range.length = podspecFile.length;
		[podspecFile replaceOccurrencesOfString:@"<Project Version>"
		                             withString:version
		                                options:NSLiteralSearch
		                                  range:range];
	}
    
	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@"'<"
	                             withString:@"'<#"
	                                options:NSLiteralSearch
	                                  range:range];
    
	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@">'"
	                             withString:@"#>'"
	                                options:NSLiteralSearch
	                                  range:range];
    
	// Reading dependencies
	NSString *podfileContent    = [NSString stringWithContentsOfFile:self.podfilePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *fileLines          = [podfileContent componentsSeparatedByString:@"\n"];
    
	for (NSString *tmp in fileLines) {
		NSString *line = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
		if ([line rangeOfString:@"pod "].location == 0) {
			[podspecFile appendFormat:@"\n  s.dependencies =\t%@", line];
		}
	}
    
	[podspecFile appendString:@"\n\nend"];
    
	// Write Podspec File
	[[NSFileManager defaultManager] createFileAtPath:self.podspecPath contents:nil attributes:nil];
	[podspecFile writeToFile:self.podspecPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (BOOL)containsFileWithName:(NSString *)fileName
{
	NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
	return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

#pragma mark - Overriden getters

- (NSString *)workspacePath {
    return [NSString stringWithFormat:@"%@/%@.xcworkspace", self.directoryPath, self.projectName];
}

@end
