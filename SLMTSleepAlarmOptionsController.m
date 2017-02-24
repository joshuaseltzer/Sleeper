//
//  SLMTSleepAlarmOptionsController.x
//  The view controller that allows the user to configure the options for the special Sleep alarm on iOS10.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "SLAppleSharedInterfaces.h"
#import "SLPrefsManager.h"
#import "SLLocalizedStrings.h"
#import "SLCompatibilityHelper.h"
#import "SLPickerTableViewController.h"
#import "SLSnoozeTimeViewController.h"
#import "SLSkipTimeViewController.h"

// define an enum to reference the sections of the table view
typedef enum SLSleepAlarmOptionsSection : NSUInteger {
    kSLSleepAlarmOptionsSectionDaysOfWeek,
    kSLSleepAlarmOptionsSectionBedtimeReminder,
    kSLSleepAlarmOptionsSectionWakeUpSound,
    kSLSleepAlarmOptionsSectionSoundVolume,
    kSLSleepAlarmOptionsSectionSleeper
} SLSleepAlarmOptionsSection;

// define an enum to define the rows in the kSLSleepAlarmOptionsSectionSleeper section
typedef enum SLSleepAlarmOptionsSectionSleeperRow : NSUInteger {
    kSLSleepAlarmOptionsSectionSleeperRowSnoozeTime,
    kSLSleepAlarmOptionsSectionSleeperRowSkipToggle,
    kSLSleepAlarmOptionsSectionSleeperRowSkipTime,
    kSLSleepAlarmOptionsSectionSleeperNumRows
} SLSleepAlarmOptionsSectionSleeperRow;

// the custom cell used to display information when editing an alarm
@interface MoreInfoTableViewCell : UITableViewCell
@end

// table view controller which configures the settings for the sleep alarm
@interface MTSleepAlarmOptionsController : UITableViewController <SLPickerSelectionDelegate>
@end

// custom interface for added properties
@interface MTSleepAlarmOptionsController (Sleeper)

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

@end

// define a constant that is used to identify the sleep alarm
static NSString * const kSLSleepAlarmId = @"sleepAlarmId";

%hook MTSleepAlarmOptionsController

// the Sleeper preferences for the special sleep alarm
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

- (void)viewDidLoad
{
    // load the preferences for the sleep alarm
    self.SLAlarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:kSLSleepAlarmId];
    if (self.SLAlarmPrefs == nil) {
        self.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:kSLSleepAlarmId];
    }

    %orig;
}

- (void)dealloc
{
    // clear out the alarm preferences
    self.SLAlarmPrefs = nil;

    %orig;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // add an additional section for Sleeper options
    return %orig + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;
    
    // define the number of custom rows we are adding to the extra section
    if (section == kSLSleepAlarmOptionsSectionSleeper) {
        numRows = kSLSleepAlarmOptionsSectionSleeperNumRows;
    } else {
        numRows = %orig;
    }
    
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // grab the original cell that is defined for this table
    MoreInfoTableViewCell *cell = (MoreInfoTableViewCell *)%orig;
    
    // configure the custom cells
    if (indexPath.section == kSLSleepAlarmOptionsSectionSleeper) {
        switch (indexPath.row) {
            case kSLSleepAlarmOptionsSectionSleeperRowSnoozeTime:
                cell.textLabel.text = kSLSnoozeTimeString;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                // format the cell of the text with the snooze time values
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.snoozeTimeHour,
                                            (long)self.SLAlarmPrefs.snoozeTimeMinute, (long)self.SLAlarmPrefs.snoozeTimeSecond];
                break;
            case kSLSleepAlarmOptionsSectionSleeperRowSkipToggle: {
                cell.textLabel.text = kSLSkipString;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.detailTextLabel.text = nil;
                
                // create a switch to allow the user to toggle on and off the skip functionality
                UISwitch *skipControl = [[UISwitch alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
                [skipControl addTarget:self
                                action:@selector(SLSkipControlChanged:)
                      forControlEvents:UIControlEventValueChanged];
                skipControl.on = self.SLAlarmPrefs.skipEnabled;
                
                // set the switch to the custom view in the cell
                cell.accessoryView = skipControl;
                break;
            }
            case kSLSleepAlarmOptionsSectionSleeperRowSkipTime:
                cell.textLabel.text = kSLSkipTimeString;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
                // format the cell of the text with the skip time values
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.skipTimeHour,
                                            (long)self.SLAlarmPrefs.skipTimeMinute, (long)self.SLAlarmPrefs.skipTimeSecond];
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // handle row selection for the custom cells
    if (indexPath.section == kSLSleepAlarmOptionsSectionSleeper) {
        switch (indexPath.row) {
            case kSLSleepAlarmOptionsSectionSleeperRowSnoozeTime: {
                // create a custom view controller which will decide the snooze time
                SLSnoozeTimeViewController *snoozeController = [[SLSnoozeTimeViewController alloc] initWithHours:self.SLAlarmPrefs.snoozeTimeHour
                                                                                                         minutes:self.SLAlarmPrefs.snoozeTimeMinute
                                                                                                         seconds:self.SLAlarmPrefs.snoozeTimeSecond];
                snoozeController.delegate = self;
                
                // push the controller to our stack
                [self.navigationController pushViewController:snoozeController animated:YES];
                break;
            }
            case kSLSleepAlarmOptionsSectionSleeperRowSkipTime: {
                // create a custom view controller which will decide the skip time
                SLSkipTimeViewController *skipController = [[SLSkipTimeViewController alloc] initWithHours:self.SLAlarmPrefs.skipTimeHour
                                                                                                   minutes:self.SLAlarmPrefs.skipTimeMinute
                                                                                                   seconds:self.SLAlarmPrefs.skipTimeSecond];
                skipController.delegate = self;
                
                // push the controller to our stack
                [self.navigationController pushViewController:skipController animated:YES];
                break;
            }
        }
    } else {
        %orig;
    }
}

- (void)done:(UIButton *)doneButton
{
    // save our preferences
    [SLPrefsManager saveAlarmPrefs:self.SLAlarmPrefs];

    %orig;
}

// handle when the skip switch is changed
%new
- (void)SLSkipControlChanged:(UISwitch *)skipSwitch
{
    self.SLAlarmPrefs.skipEnabled = skipSwitch.on;
}

#pragma mark - SLPickerSelectionDelegate

// create the new delegate method that tells the editing view controller what picker time was selected
%new
- (void)SLPickerTableViewController:(SLPickerTableViewController *)pickerTableViewController didUpdateWithHours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds
{
    // check to see if we are updating the snooze time or the skip time
    if ([pickerTableViewController isMemberOfClass:[SLSnoozeTimeViewController class]]) {
        if (hours == 0 && minutes == 0 && seconds == 0) {
            // if all values returned are 0, then reset them to the default
            self.SLAlarmPrefs.snoozeTimeHour = kSLDefaultSnoozeHour;
            self.SLAlarmPrefs.snoozeTimeMinute = kSLDefaultSnoozeMinute;
            self.SLAlarmPrefs.snoozeTimeSecond = kSLDefaultSnoozeSecond;
        } else {
            // otherwise save our returned values
            self.SLAlarmPrefs.snoozeTimeHour = hours;
            self.SLAlarmPrefs.snoozeTimeMinute = minutes;
            self.SLAlarmPrefs.snoozeTimeSecond = seconds;
        }
    } else if ([pickerTableViewController isMemberOfClass:[SLSkipTimeViewController class]]) {
        if (hours == 0 && minutes == 0 && seconds == 0) {
            // if all values returned are 0, then reset them to the default
            self.SLAlarmPrefs.skipTimeHour = kSLDefaultSkipHour;
            self.SLAlarmPrefs.skipTimeMinute = kSLDefaultSkipMinute;
            self.SLAlarmPrefs.skipTimeSecond = kSLDefaultSkipSecond;
        } else {
            // otherwise save our returned values
            self.SLAlarmPrefs.skipTimeHour = hours;
            self.SLAlarmPrefs.skipTimeMinute = minutes;
            self.SLAlarmPrefs.skipTimeSecond = seconds;
        }
    }
}

%end

%ctor {
    // only initialize this file if we are on iOS10
    if (kSLSystemVersioniOS10) {
        %init();
    }
}