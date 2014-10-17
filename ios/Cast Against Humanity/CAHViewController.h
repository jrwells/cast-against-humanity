//
//  CAHViewController.h
//  Cast Against Humanity
//
//  Created by James Robert on 11/20/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GCKFramework/GCKFramework.h>
#import "CAHAppDelegate.h"
#import "CAHMessageStream.h"

@class GCKDevice;
@class GCKApplicationSession;
@class CAHMessageStream;

@interface CAHViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

// Client's Player
@property (nonatomic, strong) Player *myPlayer;
@property (nonatomic, strong) GCKDevice * device;
// In Game Booleans
@property (nonatomic) BOOL firstTurn;
@property (nonatomic) BOOL isJudge;
@property (nonatomic) BOOL canPlay;
@property (nonatomic) BOOL canJudge;
@property (nonatomic) BOOL nextRound;
// In Game Values
@property (nonatomic) Response *winner;
@property (nonatomic, strong) NSMutableArray *viewCards;
@property (nonatomic, strong) NSMutableArray *updatedHand;
@property (nonatomic, strong) NSMutableArray *submission;

@end

@interface CAHViewController (testing)

// Creates a GCKApplicationSession to talk to a cast device. Tests can
// override this method to inject a mock session.
- (GCKApplicationSession *)createSession;

// Creates a CAHMessageStream to talk to a CAH app instance on a
// cast device. Tests can override this method to inject a mock stream.
- (CAHMessageStream *)createMessageStream;

// The name of the current user playing the game on this device.
- (NSString *)currentUserName;

// Shows an alert message. This is used internally for all alert messages,
// which allows tests to easily check the important parts of the alerts.
- (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title tag:(NSInteger)tag;

// True if the current player can is the card judge.
- (BOOL)isPlayerJudge;

// Once the game has been joined, the player on this device.
- (char)player;

@end