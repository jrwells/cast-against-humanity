//
//  CAHViewController.m
//  Cast Against Humanity
//
//  Created by James Robert on 11/20/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import "CAHViewController.h"

static NSString * const kReceiverApplicationName = @"1f96e9a0-9cf0-4e61-910e-c76f33bd42a2";

@interface CAHViewController () <GCKApplicationSessionDelegate, CAHMessageStreamDelegate> {

    GCKApplicationSession *_session;
    GCKApplicationChannel *_channel;
    CAHMessageStream *_messageStream;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UINavigationItem *navTitle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *button;

@end

@implementation CAHViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

// Start the remote application session when the view appears.
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startSession];
}

// End the remote application session when the view disappears.
- (void)viewDidDisappear:(BOOL)animated {
    [self endSession];
    [super viewDidDisappear:animated];
}

// Begin the application session with the current device.
- (void)startSession {
    _myPlayer = [[Player alloc] init];
    _viewCards = [NSMutableArray array];
    _submission = [NSMutableArray array];
    _updatedHand = [NSMutableArray array];
    _winner = [[Response alloc] init];
    _firstTurn = YES;
    _nextRound = NO;
    _canPlay = NO;
    _canJudge = NO;
    
    NSAssert(!_session, @"Starting a second session");
    NSAssert(self.device, @"device is nil");
    
    _session = [self createSession];
    _session.delegate = self;
    
    [_session startSessionWithApplication:kReceiverApplicationName];
}

// End the current application session.
- (void)endSession {
    NSAssert(_session, @"Ending non-existent session");
    [_messageStream leaveGame];
    [_session endSession];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didQueue {
    NSLog(@"Connected to the game");
    [self.navTitle setTitle:@"Queued"];
}

- (void)didJoin:(int)playerID {
    [self.navTitle setTitle:@"Playing"];
    _myPlayer.playerID = playerID;
}

- (void)judging {
    if (_isJudge) {
        _canJudge = YES;
        [self.button setTitle:@"Submit Judgement"];
    }
    else {
        [self.navTitle setTitle:@"Judging"];
    }
}

- (void)gameDidSynced:(Player *)player judge:(int)judge {
    _myPlayer.playerID = player.playerID;
    _myPlayer.hand = [[NSMutableArray alloc] initWithArray:player.hand copyItems:YES];
    if (judge == _myPlayer.playerID) {
        NSLog(@"I should be the judge now!");
        _isJudge = YES;
        [self.navTitle setTitle:@"Judging"];
        _viewCards = [NSMutableArray array];
        [self.button setTitle:@"Submit Judgement"];
        [self.tableView reloadData];
    }
    else {
        NSLog(@"I am not the judge");
        _isJudge = NO;
        [self.navTitle setTitle:@"Playing"];
        _viewCards = _myPlayer.hand;
        [self.tableView reloadData];
    }
}

- (void)judgeSubmissions:(NSMutableArray *)response {
    _canJudge = YES;
    _viewCards = [NSMutableArray array];
    for(Response *r in response) {
        [_messageStream submissionRead:r.cards];
        [_viewCards addObject:r];
    }
    [self.button setTitle:@"Submit Judgement"];
    [self.tableView reloadData];
}

- (void)roundDidStart:(NSString *)prompt {
    _firstTurn = NO;
    _nextRound = NO;
    NSLog(@"Round has started, there is a new prompt");
    if (_isJudge) {
        NSLog(@"I'm the judge, displaying prompt");
        _canJudge = NO;
        _canPlay = NO;
        [self.button setTitle:@"Submit Judgement"];
    }
    else {
        NSLog(@"I am not the judge, displaying prompt");
        _canPlay = YES;
        [self.button setTitle:@"Submit Cards"];
    }
    [self.statusLabel setText:prompt];
}

- (void)roundDidEnded {
    NSLog(@"Round has ended, reseting display");
    _canJudge = NO;
    _canPlay = NO;
    _nextRound = YES;
    _viewCards = _myPlayer.hand;
    _submission = [NSMutableArray array];
    _winner = [[Response alloc] init];
    [self.button setTitle:@"Next Round"];
    [self.navTitle setTitle:@"Round Over"];
    [self.statusLabel setText:@""];
    [self.tableView reloadData];
}

- (void)response:(int)code {
    UIAlertView *messageAlert;
    switch (code) {
        case -1:
            messageAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Invalid type sent to server!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [messageAlert show];
            break;
        case 0:
            NSLog(@"Error code was 0");
        case 1:
            messageAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You submitted the wrong number of cards!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [messageAlert show];
            _canPlay = YES;
            break;
        case 2:
            messageAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You made an invalid judgement!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [messageAlert show];
            _canJudge = YES;
            break;
        case 3:
            messageAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You judged too early!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [messageAlert show];
            break;
        case 4:
            messageAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your name is blank!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [messageAlert show];
            break;
        case 5:
            messageAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Round in progress!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [messageAlert show];
            break;
        case 6:
            messageAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Not enough players to start a round" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [messageAlert show];
            break;
        default:
            break;
    }
    
}

#pragma mark - IBActions

- (IBAction)buttonPress:(id)sender {
    if (_isJudge) {
        if (_canJudge) {
            NSLog(@"Sending judgment to server");
            [_messageStream submissionsJudged:_winner.submitterID];
            _canJudge = NO;
            return;
        }
    }
    else {
        if (_canPlay) {
            NSLog(@"Sending submission to server");
            [_messageStream playSubmission:_submission];
            _submission = [NSMutableArray array];
            for (UITableViewCell *cell in [self.tableView visibleCells]) {
                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES];
            }
            _canPlay = NO;
            return;
        }
    }
    if (_nextRound || _firstTurn) {
        NSLog(@"Advancing to next round");
        [_messageStream nextRound];
    }
}

- (IBAction)quit:(id)sender {
    [self endSession];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)setName:(id)sender {
    [self askForName:NO];
}

- (void)askForName:(BOOL)required {
    UIAlertView *alert;
    if (required)
        alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please enter a name!" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Confirm", nil];
    else
        alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please enter a name!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *userName = textField.text;
    if ([userName length] > 0 && buttonIndex != [alertView cancelButtonIndex]) {
        [appDelegate setUserName:userName];
        [_messageStream changeName:[appDelegate userName]];
    }
}

#pragma mark - GCKApplicationSessionDelegate

- (GCKApplicationSession *)createSession {
    return [[GCKApplicationSession alloc] initWithContext:appDelegate.context device:self.device];
}

- (CAHMessageStream *)createMessageStream {
    return [[CAHMessageStream alloc] initWithDelegate:self];
}

// When connected to the session, attempt to join the game if the channel was
// successfully established, or show an error if there is no channel.
- (void)applicationSessionDidStart {
    _channel = _session.channel;
    if (!_channel) {
        [_session endSession];
    }
    
    _messageStream = [self createMessageStream];
    if ([_channel attachMessageStream:_messageStream]) {
        if (_messageStream.messageSink) {
        } else {
            NSLog(@"Can't send messages.");
        }
    } else {
        NSLog(@"Couldn't attachMessageStream.");
    }
    
    [_messageStream joinWithName:appDelegate.userName];
}

// Show an error indicating that the game could not be started.
- (void)applicationSessionDidFailToStartWithError:(GCKApplicationSessionError *)error {
    NSLog(@"castApplicationSessionDidFailToStartWithError: %@", [error localizedDescription]);
    _messageStream = nil;
}

// If there is an error, show it; otherwise, just nil out the message stream.
- (void)applicationSessionDidEndWithError:(GCKApplicationSessionError *)error {
    if (error)
        NSLog(@"castApplicationSessionDidEndWithError: %@", error);
    else
        NSLog(@"Left game");
    _messageStream = nil;
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isJudge) {
        if (_canJudge) {
            _winner = [_viewCards objectAtIndex:(NSUInteger)indexPath.row];
            NSLog(@"Winner is now player %d", _winner.submitterID);
        }
    }
    else {
        if (_canPlay) {
            [_submission addObject:[_viewCards objectAtIndex:(NSUInteger)indexPath.row]];
            NSLog(@"Added card to submission");
        }
    }    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_isJudge) {
        if (_canPlay) {
            [_submission removeObjectIdenticalTo:[_viewCards objectAtIndex:(NSUInteger)indexPath.row]];
            NSLog(@"Card removed from submission");
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_viewCards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell.
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [cell.textLabel.font fontWithSize:10];
    
    if ([[_viewCards objectAtIndex:(NSUInteger)indexPath.row] isKindOfClass:[Response class]]) {
        Response *response = [_viewCards objectAtIndex:(NSUInteger)indexPath.row];
        NSMutableString *text = [NSMutableString stringWithFormat:@""];
        int i = 0;
        if ([response.cards count] > 1) {
            cell.textLabel.font = [cell.textLabel.font fontWithSize:8];
        }
        for (Card *c in response.cards) {
            i++;
            [text appendString:c.text];
            if (i != [response.cards count])
                [text appendString:@" \r"];
        }
        cell.textLabel.text = [self fixHTMLEntities:text];
        cell.detailTextLabel.text = [@(response.submitterID) description];
    }
    else {
        Card *card = [_viewCards objectAtIndex:(NSUInteger)indexPath.row];
        cell.textLabel.text = [self fixHTMLEntities:card.text];
        cell.detailTextLabel.text = [@(card.cardID) description];
    }
    return cell;
}

- (NSString *)fixHTMLEntities:(NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&trade;" withString:@"™"];
    string = [string stringByReplacingOccurrencesOfString:@"&reg;" withString:@"®"];
    string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"Ãœ" withString:@"Ü"];
    
    return string;
}

@end
