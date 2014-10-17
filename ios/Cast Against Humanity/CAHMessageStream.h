//
//  CAHMessageStream.h
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import <GCKFramework/GCKFramework.h>
#import "Player.h"
#import "Card.h"
#import "Response.h"

/**
 * Delegate protocol for CAHMessageStream.
 */
@protocol CAHMessageStreamDelegate

/**
 * Called when the player has been successfully queued for a game.
 *
 */
- (void)didQueue;

/**
 * Called when the player has successfully joined a game.
 *
 * @param playerID int that corresponds to the client's player.
 */
- (void)didJoin:(int)playerID;

/**
 * Called when the player has been made the judge.
 *
 */
- (void)judging;

/**
 * Called when the game status on the server has changed.
 *
 * @param player contains the client's player object, with updated quantities (i.e. hand, trophies, etc...).
 * @param judge the number associated with the current judge.
 */
- (void)gameDidSynced:(Player *)player judge:(int)judge;

/**
 * Submissions that must be judged.
 *
 * @param responses dictionary of responses which includes submitted cards and the submitter's number.
 */
- (void)judgeSubmissions:(NSMutableArray *)response;

/**
 * Called when a new round has started.
 *
 * @param prompt the prompt for the new round.
 */
- (void)roundDidStart:(NSString *)prompt;

/**
 * Called when the current round has ended.
 *
 */
- (void)roundDidEnded;

/**
 * Called when the server responds to the client's command.
 *
 * @param code int which corresponds to the way the game behaved for the given response.
 *
 * Code:            Meaning:
 *  0               Valid command received.
 *  1               Player submitted the wrong number of cards.
 *  2               Judge submitted an invalid player to win the round.
 *  3               Judge tried to judge before all cards were received.
 */
- (void)response:(int)code;

@end

@interface CAHMessageStream : GCKMessageStream

- (id)initWithDelegate:(id<CAHMessageStreamDelegate>)delegate;

/**
 * Joins a game.
 *
 * @param name The name of this player.
 */
- (BOOL)joinWithName:(NSString *)name;

/**
 * Leaves the game.
 *
 */
- (BOOL)leaveGame;

/**
 * Changes the player's name on the server.
 *
 * @param name The name of this player.
 */
- (BOOL)changeName:(NSString *)name;

/**
 * Sends the server a player submission
 *
 * @param submission the array of cards the player wishes to play.
 */
- (BOOL)playSubmission:(NSArray *)submission;

/**
 * Submits a winning player ID to the server.
 *
 * @param winningPlayer the player ID that corresponds to the player the judge picked.
 */
- (BOOL)submissionsJudged:(int)winningPlayer;

/**
 * Tells the server that a submission have been read by the judge.
 *
 * @param cards the response that the player has read.
 */
- (BOOL)submissionRead:(NSMutableArray *)cards;

/**
 * Advances the game to the next round.
 *
 * @param name The name of this player.
 */
- (BOOL)nextRound;

@end
