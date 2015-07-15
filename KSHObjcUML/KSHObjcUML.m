//
//  KSHObjcUML.m
//  KSHObjcUML
//
//  Created by 金聖輝 on 15-2-18.
//  Copyright (c) 2015年 KimSungwhee. All rights reserved.
//

#import "KSHObjcUML.h"

#import "VWKShellHandler.h"
#import "VWKWorkspaceManager.h"
#import "VWKProject.h"

static KSHObjcUML *sharedPlugin;

static NSString *BIN_PATH            = @"/bin";
static NSString *USER_BIN_PATH       = @"/usr/bin";
static NSString *USER_LOCAL_BIN_PATH = @"/usr/local/bin";

static NSString *COPY_EXECUTABLE        = @"cp";
static NSString *RM_EXECUTABLE          = @"rm";
static NSString *UNZIP_EXECUTABLE       = @"unzip";
static NSString *OPEN_EXECUTABLE        = @"open";
static NSString *ZIP_FILE_NAME          = @"ObjcUML.zip";
static NSString *FOLDAR_NAME            = @"ObjcUML";
static NSString *RUBY_EXECUTE_FILE_NAME = @"script.rb";
static NSString *HTML_FILE              = @"index.html";
static NSString *OUT_PUT_JS_FILE        = @"origin.js";

@interface KSHObjcUML ()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, copy) NSString              *directoryPath;
@property (nonatomic, copy) NSString              *zipFilePath;
@property (nonatomic, copy) NSString              *projectName;
@property (nonatomic, copy) NSString              *scriptPath;
@end

@implementation KSHObjcUML

+ (NSBundle *)pluginBundle
{
    return [NSBundle bundleForClass:self];
}

- (NSString *)scriptPath
{
    NSString *tempScriptPath = [[self.directoryPath stringByAppendingPathComponent:FOLDAR_NAME] stringByAppendingPathComponent:@"script.rb"];
    if (tempScriptPath) {
        _scriptPath = tempScriptPath;
    }
    return _scriptPath;
}

- (NSString *)projectName
{
    NSString *tempProjectName = [VWKProject projectForKeyWindow].projectOriginalName;
    if (tempProjectName) {
        _projectName = tempProjectName;
    }
    return _projectName;
}

- (NSString *)zipFilePath
{
    NSString *tempZipFilePath = [[KSHObjcUML pluginBundle] pathForResource:FOLDAR_NAME ofType:@"zip"];
    if (tempZipFilePath) {
        _zipFilePath = tempZipFilePath;
    }
    return _zipFilePath;
}

- (NSString *)directoryPath
{
    NSString *tempDirectoryPath = [VWKProject projectForKeyWindow].directoryPath;
    if (tempDirectoryPath) {
        _directoryPath = tempDirectoryPath;
    }
    return _directoryPath;
}

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString              *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if( [currentApplicationName isEqual:@"Xcode"] )
    {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if( self = [super init] )
    {
        self.bundle = plugin;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
            if( menuItem )
            {
                [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
                NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Objc-UML" action:@selector(startGenerateGraph) keyEquivalent:@""];
                [actionMenuItem setTarget:self];
                [[menuItem submenu] insertItem:actionMenuItem atIndex:[menuItem.submenu indexOfItemWithTitle:@"Build For"]];
            }
        }];
    }
    
    return self;
}

- (void)startGenerateGraph
{
    [VWKShellHandler runShellCommand:[BIN_PATH stringByAppendingPathComponent:COPY_EXECUTABLE]
                            withArgs:@[self.zipFilePath, self.directoryPath]
                           directory:self.directoryPath
                          completion:^(NSTask *t, NSString *standardOutputString, NSString *standardErrorString) {
                              [VWKShellHandler runShellCommand:[USER_BIN_PATH stringByAppendingPathComponent:UNZIP_EXECUTABLE] withArgs:@[@"-o", @"-d",
                                                                                                                                          self.directoryPath,
                                                                                                                                          [self.directoryPath stringByAppendingPathComponent:ZIP_FILE_NAME]] directory:self.directoryPath completion:^(NSTask *t,
                                                                                                                                                                                                                                                       NSString *
                                                                                                                                                                                                                                                       standardOutputString,
                                                                                                                                                                                                                                                       NSString *
                                                                                                                                                                                                                                                       standardErrorString)
                               {
                                   [VWKShellHandler runShellCommand:[BIN_PATH stringByAppendingPathComponent:RM_EXECUTABLE] withArgs:@[@"-rf", [self.directoryPath stringByAppendingPathComponent:ZIP_FILE_NAME]] directory:self.directoryPath completion:^(
                                                                                                                                                                                                                                                            NSTask *t, NSString *standardOutputString, NSString *standardErrorString) {
                                       [VWKShellHandler runShellCommand:self.scriptPath withArgs:@[@"-s",[NSString stringWithFormat:@"\"%@\"",self.projectName], @"-t",
                                                                                                   [[self.directoryPath stringByAppendingPathComponent:FOLDAR_NAME] stringByAppendingPathComponent:OUT_PUT_JS_FILE]] directory:
                                        self.directoryPath   completion:^(NSTask *t, NSString *standardOutputString, NSString *standardErrorString) {
                                            [VWKShellHandler runShellCommand:[BIN_PATH stringByAppendingPathComponent:RM_EXECUTABLE] withArgs:@[@"-rf", self.scriptPath] directory:self.directoryPath completion:^(NSTask *t, NSString *standardOutputString,
                                                                                                                                                                                                                   NSString *standardErrorString) {
                                                [VWKShellHandler runShellCommand:[USER_BIN_PATH stringByAppendingPathComponent:OPEN_EXECUTABLE] withArgs:@[[[self.directoryPath stringByAppendingPathComponent:FOLDAR_NAME] stringByAppendingPathComponent:
                                                                                                                                                            HTML_FILE]] directory:self.directoryPath completion:nil];
                                            }];
                                        }];
                                   }];
                               }];
                          }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
