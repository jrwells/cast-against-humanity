//
//  CAHDiscoveryViewController.m
//  Cast Against Humanity
//
//  Created by James Robert on 11/16/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import "CAHDiscoveryViewController.h"

@interface CAHDiscoveryViewController () <GCKDeviceManagerListener> {
    NSMutableArray *_devices;
    GCKDevice *_selectedDevice;
}

@end

@implementation CAHDiscoveryViewController

- (void)viewDidLoad {
    if (!_devices) {
        _devices = [[NSMutableArray alloc] init];
    }
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _devices = [appDelegate.deviceManager.devices mutableCopy];
    [appDelegate.deviceManager addListener:self];
    [appDelegate.deviceManager startScan];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *userName = [appDelegate userName];
    if (!userName || [userName length] == 0) {
        [self askForName:NO];
    }
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
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [appDelegate.deviceManager stopScan];
    [appDelegate.deviceManager removeListener:self];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions

- (IBAction)refresh:(id)sender {
    [appDelegate.deviceManager startScan];
}

- (IBAction)setName:(id)sender {
    [self askForName:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell.
    const GCKDevice *device = [_devices objectAtIndex:(NSUInteger)indexPath.row];
    cell.textLabel.text = device.friendlyName;
    cell.detailTextLabel.text = device.ipAddress;
    
    return cell;
}

#pragma mark - GCKDeviceManagerListener

- (void)scanStarted {
}

- (void)scanStopped {
}

- (void)deviceDidComeOnline:(GCKDevice *)device {
    if (![_devices containsObject:device]) {
        [_devices addObject:device];
        [self.tableView reloadData];
    }
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
    [_devices removeObject:device];
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DeviceSelected"]) {
        CAHViewController *viewController = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        viewController.device = [_devices objectAtIndex:indexPath.row];
    }
}

@end
