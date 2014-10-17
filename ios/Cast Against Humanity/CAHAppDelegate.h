//
//  CAHAppDelegate.h
//  Cast Against Humanity
//
//  Created by James Robert on 11/16/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GCKFramework/GCKFramework.h>

@class GCKContext;
@class GCKDevice;
@class GCKDeviceManager;

@interface CAHAppDelegate : UIResponder <UIApplicationDelegate>

@property(nonatomic, strong, readonly) GCKContext *context;
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) GCKDeviceManager *deviceManager;

- (NSString *)userName;
- (void)setUserName:(NSString *)userName;

@end

#define appDelegate ((CAHAppDelegate *) [UIApplication sharedApplication].delegate)
