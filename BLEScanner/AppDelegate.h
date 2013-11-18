//
//  AppDelegate.h
//  BLEScanner
//
//  Created by Liam Nichols on 16/11/2013.
//  Copyright (c) 2013 Liam Nichols. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSTextField *statusLabel;

@property (assign) IBOutlet NSTextField *durationTextField;

@property (assign) IBOutlet NSButton *scanButton;

@property (assign) IBOutlet NSTableView *tableView;

@end
