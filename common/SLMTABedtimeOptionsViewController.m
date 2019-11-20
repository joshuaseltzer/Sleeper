//
//  SLMTABedtimeOptionsViewController.x
//  The view controller that allows the user to configure the options for the special Sleep alarm (iOS 11 and iOS 12).
//
//  Created by Joshua Seltzer on 4/1/18.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLPrefsManager.h"
#import "../SLLocalizedStrings.h"
#import "../SLCompatibilityHelper.h"
#import "../SLSnoozeTimeViewController.h"
#import "../SLSkipTimeViewController.h"

// define an enum to reference the sections of the table view
typedef enum SLBedtimeOptionsViewControllerSection : NSUInteger {
    kSLBedtimeOptionsViewControllerSectionDaysOfWeek,
    kSLBedtimeOptionsViewControllerSectionBedtimeReminder,
    kSLBedtimeOptionsViewControllerSectionWakeUpSound,
    kSLBedtimeOptionsViewControllerSectionSleeper,
    kSLBedtimeOptionsViewControllerNumSections
} SLBedtimeOptionsViewControllerSection;

// define an enum to define the rows in the kSLBedtimeOptionsViewControllerSectionSleeper section
typedef enum SLBedtimeOptionsViewControllerSleeperSectionRow : NSUInteger {
    kSLBedtimeOptionsViewControllerSleeperSectionRowSnoozeTime,
    kSLBedtimeOptionsViewControllerSleeperSectionRowSkipToggle,
    kSLBedtimeOptionsViewControllerSleeperSectionRowSkipTime,
    kSLBedtimeOptionsViewControllerSleeperSectionRowSkipDates,
    kSLBedtimeOptionsViewControllerSleeperSectionNumRows
} SLBedtimeOptionsViewControllerSleeperSectionRow;

// define a constant for the reuse identifier for the custom cell we will create
static NSString * const kSLBedtimeOptionsViewControllerSleeperSectionCellReuseIdentifier = @"SLBedtimeOptionsViewControllerSleeperSectionCellReuseIdentifier";

%hook MTABedtimeOptionsViewController

// the Sleeper preferences for the special sleep alarm
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

// boolean property to signify whether or not changes were made to the Sleeper preferences
%property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

- (void)viewDidLoad
{
    // Load the preferences for the sleep alarm (iOS 11).  On iOS 12, the preferences will be set from the parent controller
    // prior to this controller being displayed.
    if (kSLSystemVersioniOS11) {
        AlarmManager *alarmManager = (AlarmManager *)[objc_getClass("AlarmManager") sharedManager];
        NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarmManager.sleepAlarm];
        self.SLAlarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
        if (self.SLAlarmPrefs == nil) {
            self.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
            self.SLAlarmPrefsChanged = YES;
        } else {
            self.SLAlarmPrefsChanged = NO;
        }
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
    // define the number of custom rows we are adding to the extra section
    NSInteger numRows = 0;
    if (section == kSLBedtimeOptionsViewControllerSectionSleeper) {
        numRows = kSLBedtimeOptionsViewControllerSleeperSectionNumRows;
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
    if (indexPath.section == kSLBedtimeOptionsViewControllerSectionSleeper) {
        // Dequeue the custom cell from the table.  Create a new one if it does not yet exist.
        cell = [tableView dequeueReusableCellWithIdentifier:kSLBedtimeOptionsViewControllerSleeperSectionCellReuseIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:kSLBedtimeOptionsViewControllerSleeperSectionCellReuseIdentifier];

            // set the background color of the cell
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
            cell.selectedBackgroundView = backgroundView;

            // set the text color for the title label of the cell
            cell.textLabel.textColor = [UIColor whiteColor];
        }

        // customize the cell based on the row
        switch (indexPath.row) {
            case kSLBedtimeOptionsViewControllerSleeperSectionRowSnoozeTime:
                cell.textLabel.text = kSLSnoozeTimeString;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                // format the cell of the text with the snooze time values
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.snoozeTimeHour,
                                            (long)self.SLAlarmPrefs.snoozeTimeMinute, (long)self.SLAlarmPrefs.snoozeTimeSecond];
                break;
            case kSLBedtimeOptionsViewControllerSleeperSectionRowSkipToggle: {
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
            case kSLBedtimeOptionsViewControllerSleeperSectionRowSkipTime:
                cell.textLabel.text = kSLSkipTimeString;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
                // format the cell of the text with the skip time values
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.skipTimeHour,
                                            (long)self.SLAlarmPrefs.skipTimeMinute, (long)self.SLAlarmPrefs.skipTimeSecond];
                break;
            case kSLBedtimeOptionsViewControllerSleeperSectionRowSkipDates:
                cell.textLabel.text = kSLSkipDatesString;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                // customize the detail text label depending on whether or not we have skip dates enabled
                cell.detailTextLabel.text = [self.SLAlarmPrefs totalSelectedDatesString];
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
    if (indexPath.section == kSLBedtimeOptionsViewControllerSectionSleeper) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        switch (indexPath.row) {
            case kSLBedtimeOptionsViewControllerSleeperSectionRowSnoozeTime: {
                // create a custom view controller which will decide the snooze time
                SLSnoozeTimeViewController *snoozeController = [[SLSnoozeTimeViewController alloc] initWithHours:self.SLAlarmPrefs.snoozeTimeHour
                                                                                                         minutes:self.SLAlarmPrefs.snoozeTimeMinute
                                                                                                         seconds:self.SLAlarmPrefs.snoozeTimeSecond];
                snoozeController.delegate = self;
                [self.navigationController pushViewController:snoozeController animated:YES];
                break;
            }
            case kSLBedtimeOptionsViewControllerSleeperSectionRowSkipTime: {
                // create a custom view controller which will decide the skip time
                SLSkipTimeViewController *skipController = [[SLSkipTimeViewController alloc] initWithHours:self.SLAlarmPrefs.skipTimeHour
                                                                                                   minutes:self.SLAlarmPrefs.skipTimeMinute
                                                                                                   seconds:self.SLAlarmPrefs.skipTimeSecond];
                skipController.delegate = self;
                [self.navigationController pushViewController:skipController animated:YES];
                break;
            }
            case kSLBedtimeOptionsViewControllerSleeperSectionRowSkipDates: {
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
    // save our preferences if needed
    if (self.SLAlarmPrefsChanged || self.SLAlarmPrefs.skipActivationStatus != kSLSkipActivatedStatusUnknown) {
        self.SLAlarmPrefs.skipActivationStatus = kSLSkipActivatedStatusUnknown;
        [SLPrefsManager saveAlarmPrefs:self.SLAlarmPrefs];
    }

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

// potentially customize the footer text depending on whether or not the alarm is going to be skipped
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerTitle = %orig;
    if (section == kSLBedtimeOptionsViewControllerSectionSleeper) {
        footerTitle = [self.SLAlarmPrefs skipReasonExplanation];
    }
    return footerTitle;
}

// handle when the skip switch is changed
%new
- (void)SLSkipControlChanged:(UISwitch *)skipSwitch
{
    self.SLAlarmPrefs.skipEnabled = skipSwitch.on;

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
    [self updateDoneButtonEnabled];

    // force the footer title to update since the explanation to display might have changed
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView footerViewForSection:kSLBedtimeOptionsViewControllerSectionSleeper].textLabel.text = [self.SLAlarmPrefs skipReasonExplanation];
    [[self.tableView footerViewForSection:kSLBedtimeOptionsViewControllerSectionSleeper].textLabel sizeToFit];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];
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

        // reload the cell that contains the snooze time
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLBedtimeOptionsViewControllerSleeperSectionRowSnoozeTime
                                                                    inSection:kSLBedtimeOptionsViewControllerSectionSleeper]]
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
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLBedtimeOptionsViewControllerSleeperSectionRowSkipTime
                                                                    inSection:kSLBedtimeOptionsViewControllerSectionSleeper]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
    [self updateDoneButtonEnabled];
}

#pragma mark - SLSkipDatesDelegate

// create a new delegate method for when the skip dates controller has updated skip dates
%new
- (void)SLSkipDatesViewController:(SLSkipDatesViewController *)skipDatesViewController didUpdateCustomSkipDates:(NSArray *)customSkipDates holidaySkipDates:(NSDictionary *)holidaySkipDates
{
    self.SLAlarmPrefs.customSkipDates = customSkipDates;
    self.SLAlarmPrefs.holidaySkipDates = holidaySkipDates;

    // reload the cell that contains the skip dates
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLBedtimeOptionsViewControllerSleeperSectionRowSkipDates
                                                                inSection:kSLBedtimeOptionsViewControllerSectionSleeper]]
                            withRowAnimation:UITableViewRowAnimationNone];

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
    [self updateDoneButtonEnabled];
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS11 || kSLSystemVersioniOS12) {
        %init();
    }
}