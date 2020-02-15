//
//  SLUserInterfaceHeaders.h
//  Contains all interfaces required for the User Interface project.
//
//  Created by Joshua Seltzer on 2/15/20.
//
//

#import "SLSkipTimeViewController.h"
#import "SLSkipDatesViewController.h"

// table view controller which configures the settings for the sleep alarm
@interface MTABedtimeOptionsViewController : UITableViewController

// updates the status of the done button on the view controller
- (void)updateDoneButtonEnabled;

@end

// custom interface for added properties to the options controller
@interface MTABedtimeOptionsViewController (Sleeper) <SLPickerSelectionDelegate, SLSkipDatesDelegate>

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;
@property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

@end