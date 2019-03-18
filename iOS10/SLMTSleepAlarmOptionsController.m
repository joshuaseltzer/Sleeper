//
//  SLMTSleepAlarmOptionsController.x
//  The view controller that allows the user to configure the options for the special Sleep alarm on iOS 10.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLPrefsManager.h"
#import "../SLLocalizedStrings.h"
#import "../SLCompatibilityHelper.h"
#import "../SLSnoozeTimeViewController.h"
#import "../SLSkipTimeViewController.h"

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
    kSLSleepAlarmOptionsSectionSleeperRowSkipDates,
    kSLSleepAlarmOptionsSectionSleeperNumRows
} SLSleepAlarmOptionsSectionSleeperRow;

// table view controller which configures the settings for the sleep alarm
@interface MTSleepAlarmOptionsController : UITableViewController <SLPickerSelectionDelegate, SLSkipDatesDelegate>

// updates the status of the done button on the view controller
- (void)updateDoneButtonEnabled;

@end

// custom interface for added properties
@interface MTSleepAlarmOptionsController (Sleeper)

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;
@property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

@end

// define a constant for the reuse identifier for the custom cell we will create
static NSString * const kSLSleepAlarmOptionsSectionSleeperCellReuseIdentifier = @"SLSleepAlarmOptionsSectionSleeperCellReuseIdentifier";

%hook MTSleepAlarmOptionsController

// the Sleeper preferences for the special sleep alarm
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

// boolean property to signify whether or not changes were made to the Sleeper preferences
%property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

- (void)viewDidLoad
{
    // get the alarm ID for the special sleep alarm
    AlarmManager *alarmManager = [AlarmManager sharedManager];
    NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarmManager.sleepAlarm];

    // load the preferences for the sleep alarm
    self.SLAlarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (self.SLAlarmPrefs == nil) {
        self.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
    }
    self.SLAlarmPrefsChanged = NO;

    %orig;
}

- (void)dealloc
{
    // clear out the alarm preferences
    self.SLAlarmPrefs = nil;
    self.SLAlarmPrefsChanged = NO;

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
    // forward declare the cell that will be returned
    UITableViewCell *cell = nil;
    
    // configure the custom cells
    if (indexPath.section == kSLSleepAlarmOptionsSectionSleeper) {
        // Dequeue the custom cell from the table.  Create a new one if it does not yet exist.
        cell = [tableView dequeueReusableCellWithIdentifier:kSLSleepAlarmOptionsSectionSleeperCellReuseIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:kSLSleepAlarmOptionsSectionSleeperCellReuseIdentifier];

            // set the selected background color of the cell
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
            cell.selectedBackgroundView = backgroundView;

            // set the text color for the title label of the cell
            cell.textLabel.textColor = [UIColor whiteColor];
        }

        // customize the cell based on the row
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
                cell.accessoryType = UITableViewCellAccessoryNone;
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
            case kSLSleepAlarmOptionsSectionSleeperRowSkipDates:
                cell.textLabel.text = kSLSkipDatesString;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                // customize the detail text label depending on whether or not we have skip dates enabled
                cell.detailTextLabel.text = [self.SLAlarmPrefs selectedDatesString];
                break;
        }
    } else {
        cell = %orig;
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
                [self.navigationController pushViewController:snoozeController animated:YES];
                break;
            }
            case kSLSleepAlarmOptionsSectionSleeperRowSkipTime: {
                // create a custom view controller which will decide the skip time
                SLSkipTimeViewController *skipController = [[SLSkipTimeViewController alloc] initWithHours:self.SLAlarmPrefs.skipTimeHour
                                                                                                   minutes:self.SLAlarmPrefs.skipTimeMinute
                                                                                                   seconds:self.SLAlarmPrefs.skipTimeSecond];
                skipController.delegate = self;
                [self.navigationController pushViewController:skipController animated:YES];
                break;
            }
            case kSLSleepAlarmOptionsSectionSleeperRowSkipDates: {
                 // create a custom view controller which will display the skip dates for this alarm
                SLSkipDatesViewController *skipDatesController = [[SLSkipDatesViewController alloc] initWithAlarmPrefs:self.SLAlarmPrefs];
                skipDatesController.delegate = self;
                [self.navigationController pushViewController:skipDatesController animated:YES];
                break;
            }
        }
    } else {
        %orig;
    }
}

- (void)done:(UIBarButtonItem *)doneButton
{
    // save our preferences
    [SLPrefsManager saveAlarmPrefs:self.SLAlarmPrefs];

    %orig;
}

- (void)updateDoneButtonEnabled
{
    // check to see if any changes were made to the Sleeper preferences
    if (self.SLAlarmPrefsChanged) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        %orig;
    }
}

// handle when the skip switch is changed
%new
- (void)SLSkipControlChanged:(UISwitch *)skipSwitch
{
    self.SLAlarmPrefs.skipEnabled = skipSwitch.on;

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
    [self updateDoneButtonEnabled];
}

#pragma mark - SLPickerSelectionDelegate

// create the new delegate method that tells the editing view controller what picker time was selected
%new
- (void)SLPickerTableViewController:(SLPickerTableViewController *)pickerTableViewController didUpdateWithHours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds
{
    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
    [self updateDoneButtonEnabled];

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

        // reload the cell that contains the snooze time
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLSleepAlarmOptionsSectionSleeperRowSnoozeTime inSection:kSLSleepAlarmOptionsSectionSleeper]]
                              withRowAnimation:UITableViewRowAnimationNone];
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

        // reload the cell that contains the snooze time
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLSleepAlarmOptionsSectionSleeperRowSkipTime
                                                                    inSection:kSLSleepAlarmOptionsSectionSleeper]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - SLSkipDatesDelegate

// create a new delegate method for when the skip dates controller has updated skip dates
%new
- (void)SLSkipDatesViewController:(SLSkipDatesViewController *)skipDatesViewController didUpdateCustomSkipDates:(NSArray *)customSkipDates holidaySkipDates:(NSDictionary *)holidaySkipDates
{
    self.SLAlarmPrefs.customSkipDates = customSkipDates;
    self.SLAlarmPrefs.holidaySkipDates = holidaySkipDates;

    // reload the cell that contains the skip dates
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLSleepAlarmOptionsSectionSleeperRowSkipDates
                                                                inSection:kSLSleepAlarmOptionsSectionSleeper]]
                          withRowAnimation:UITableViewRowAnimationNone];

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
    [self updateDoneButtonEnabled];
}

%end

%ctor {
    // only initialize this file if we are on iOS 10
    if (kSLSystemVersioniOS10) {
        %init();
    }
}