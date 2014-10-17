//
//  CAHMessageStream.m
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import "CAHMessageStream.h"

static NSString * const kNamespace = @"com.bears.triviaCast";

/* 
 * Protocol
 */

// General
static NSString * const keyType = @"type";
static NSString * const keyCards = @"cards";
static NSString * const keyLeave = @"leave";

// Messages Sent

// Join
static NSString * const valueTypeJoin = @"join";
static NSString * const keyName = @"name";

// Change Name
static NSString * const valueTypeUpdateSettings = @"updateSettings";

// Play Submission
static NSString * const valueTypePlaySubmission = @"playSubmission";
static NSString * const keyCardIDs = @"cardIDs";

// Submissions Judged
static NSString * const valueTypeSubmissionsJudged = @"submissionsJudged";
static NSString * const keyWinningPlayerID = @"winningPlayerID";

// Submission Read
static NSString * const valueTypeSubmissionRead = @"submissionRead";

// Next Round
static NSString * const valueTypeNextRound = @"nextRound";

// Messages Recieved

// Did Queue
static NSString * const valueTypeDidQueue = @"didQueue";

// Did Join
static NSString * const valueTypeDidJoin = @"didJoin";
static NSString * const keyPlayerID = @"playerID";

// Was Made Judge
static NSString * const valueTypeJudging = @"judging";

// Game Did Sync
static NSString * const valueTypeGameSync = @"gameSync";
static NSString * const keyPlayer = @"player";
static NSString * const keyJudge = @"judge";

// Judge Submissions
static NSString * const valueTypeJudgeSubmissions = @"judgeSubmissions";
static NSString * const keyResponses = @"responses";

// Round Did Start
static NSString * const valueTypeRoundStarted = @"roundStarted";
static NSString * const keyPrompt = @"prompt";

// Round Did End
static NSString * const valueTypeRoundEnded = @"roundEnded";

// Response
static NSString * const valueTypeResponse = @"response";
static NSString * const keyCode = @"code";

@interface CAHMessageStream () {
    BOOL _joined;
}

@property(nonatomic, strong, readwrite) id<CAHMessageStreamDelegate> delegate;

@end;

@implementation CAHMessageStream

- (id)initWithDelegate:(id<CAHMessageStreamDelegate>)delegate {
    if (self = [super initWithNamespace:kNamespace]) {
        _delegate = delegate;
        _joined = NO;
    }
    return self;
}

- (BOOL)leaveGame {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:@"" forKey:keyLeave];
    
    return [self sendMessage:payload];
}

- (BOOL)joinWithName:(NSString *)name {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeJoin forKey:keyType];
    [payload gck_setStringValue:name forKey:keyName];
    
    return [self sendMessage:payload];
}

- (BOOL)changeName:(NSString *)name {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeUpdateSettings forKey:keyType];
    [payload gck_setStringValue:name forKey:keyName];

    return [self sendMessage:payload];
}

- (BOOL)playSubmission:(NSArray *)submission {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypePlaySubmission forKey:keyType];
    NSMutableArray *cardIDs = [NSMutableArray array];
    for (Card *c in submission) {
        [cardIDs addObject:[NSNumber numberWithInt:c.cardID]];
    }
    NSString *submissionJson = [GCKJsonUtils writeJson:cardIDs];
    [payload gck_setStringValue:submissionJson forKey:keyCardIDs];

    return [self sendMessage:payload];
}

- (BOOL)submissionsJudged:(int)winningPlayer {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeSubmissionsJudged forKey:keyType];
    [payload gck_setIntegerValue:winningPlayer forKey:keyWinningPlayerID];

    return [self sendMessage:payload];
}

- (BOOL)submissionRead:(NSMutableArray *)cards {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeSubmissionRead forKey:keyType];
    NSMutableArray *cardIDs = [NSMutableArray array];
    for (Card *c in cards) {
        [cardIDs addObject:[NSNumber numberWithInt:c.cardID]];
    }
    NSString *cardIDString = [GCKJsonUtils writeJson:cardIDs];
    [payload gck_setStringValue:cardIDString forKey:keyCardIDs];

    return [self sendMessage:payload];
}

- (BOOL)nextRound {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeNextRound forKey:keyType];

    return [self sendMessage:payload];
}

- (void)didReceiveMessage:(id)message {
    NSDictionary *payload = message;

    NSString *type = [payload gck_stringForKey:keyType];
    if (!type) {
        NSLog(@"Invalid type");
        return;
    }
    
    if ([type isEqualToString:valueTypeDidQueue]) {
        [_delegate didQueue];
    }
    else if ([type isEqualToString:valueTypeDidJoin]){
        int playerID = [payload gck_integerForKey:keyPlayerID];
        _joined = YES;
        [_delegate didJoin:playerID];
    }
    else if ([type isEqualToString:valueTypeJudging]) {
        [_delegate judging];
    }
    else if ([type isEqualToString:valueTypeGameSync]) {
        NSLog(@"Game sync");
        NSDictionary *jsonPlayer = [payload gck_dictionaryForKey:keyPlayer];
        int judge = [payload gck_integerForKey:keyJudge];
        NSMutableArray *jsonHand = [jsonPlayer objectForKey:@"hand"];
        Player *player = [[Player alloc] init];
        NSMutableArray *hand = [NSMutableArray array];
        for (NSDictionary *jsonCard in jsonHand) {
            Card *card = [[Card alloc] init];
            card.cardID = [[jsonCard objectForKey:@"ID"] intValue];
            card.text = [jsonCard objectForKey:@"text"];
            [hand addObject:card];
        }
        player.hand = hand;
        player.playerID = [[jsonPlayer objectForKey:@"ID"] intValue];
        [_delegate gameDidSynced:player judge:judge];
    }
    else if ([type isEqualToString:valueTypeJudgeSubmissions]) {
        NSArray *jsonResponses = [payload gck_arrayForKey:keyResponses];
        NSMutableArray *responses = [NSMutableArray array];
        for (NSDictionary *d in jsonResponses) {
            Response *response = [[Response alloc] init];
            NSMutableArray *a = [d objectForKey:@"cards"];
            NSMutableArray *cards = [NSMutableArray array];
            for (NSDictionary *cardDict in a) {
                Card *newCard = [[Card alloc] init];
                newCard.cardID = [[cardDict objectForKey:@"ID"] intValue];
                newCard.text = [cardDict objectForKey:@"text"];
                [cards addObject:newCard];
            }
            int submitter = [[d objectForKey:@"submitter"] intValue];
            response.cards = cards;
            response.submitterID = submitter;
            [responses addObject:response];
        }
        [_delegate judgeSubmissions:responses];
    }
    else if ([type isEqualToString:valueTypeRoundStarted]) {
        NSString *prompt = [payload gck_stringForKey:keyPrompt];
        [_delegate roundDidStart:prompt];
    }
    else if ([type isEqualToString:valueTypeRoundEnded]) {
        [_delegate roundDidEnded];
    }
    else if ([type isEqualToString:valueTypeResponse]) {
        int code = [payload gck_integerForKey:keyCode];
        [_delegate response:code];
    }
    else {
        NSLog(@"Invalid response from server recieved, with key: '%@'.", type);
    }
}

- (void)didDetach {
    _joined = NO;
}

@end
