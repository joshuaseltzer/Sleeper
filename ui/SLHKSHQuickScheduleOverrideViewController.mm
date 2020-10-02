//
//  SLHKSHQuickScheduleOverrideViewController.xm
//  The view controller that is used to change the "Sleep / Wake Up" alarm in iOS 14 (from the SleepHealthUI PrivateFramework).
//  The equivalent controller for iOS 13 is SLMTASleepOptionsViewController.m
//
//  Created by Joshua Seltzer on 9/26/20.
//
//

#import "custom/SLSnoozeTimeViewController.h"
#import "custom/SLSkipTimeViewController.h"
#import "custom/SLSkipDatesViewController.h"
#import "../common/SLCommonHeaders.h"
#import "../common/SLAlarmPrefs.h"
#import "../common/SLCompatibilityHelper.h"
#import "../common/SLLocalizedStrings.h"

// Define an enum to reference the sections of the table view, specifically when the wake alarm is enabled
// When the wake alarm is disabled, the kSLQuickScheduleOverrideViewControllerSectionAlarmOptions is not shown.
typedef enum SLQuickScheduleOverrideViewControllerSection : NSUInteger {
    kSLQuickScheduleOverrideViewControllerSectionDial,
    kSLQuickScheduleOverrideViewControllerSectionAlarmToggle,
    kSLQuickScheduleOverrideViewControllerSectionAlarmOptions,
    kSLQuickScheduleOverrideViewControllerSectionSleepSchedule,
    kSLQuickScheduleOverrideViewControllerNumSections
} SLQuickScheduleOverrideViewControllerSection;

// define an enum to define the rows in the kSLQuickScheduleOverrideViewControllerSectionAlarmOptions section
typedef enum SLQuickScheduleOverrideViewControllerAlarmOptionsSectionRow : NSUInteger {
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSounds,
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowVolume,
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeToggle,
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeTime, // custom cells start here
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipToggle,
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipTime,
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipDates,
    kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionNumRows
} SLQuickScheduleOverrideViewControllerAlarmOptionsSectionRow;

@interface HKSHQuickScheduleOverrideViewController : UITableViewController {
    // The data source object is an instance of a UITableViewDiffableDataSource, which implements all of the table view's
    // data source methods.  We need to re-implement the data source methods manually to add custom cells to this controller
    // but will utilize this data source object to reuse a lot of the existing implmentation.
    id dataSource;
}
@end

// custom interface for added properties to this controller
@interface HKSHQuickScheduleOverrideViewController (Sleeper) <SLPickerSelectionDelegate, SLSkipDatesDelegate>

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;
@property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

@end

// define a constant for the reuse identifier for the custom cell we will create
static NSString * const kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionCellReuseIdentifier = @"SLQuickScheduleOverrideViewControllerAlarmOptionsSectionCellReuseIdentifier";

%hook HKSHQuickScheduleOverrideViewController

// the Sleeper preferences for the alarm being displayed
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

// boolean property to signify whether or not changes were made to the Sleeper preferences
%property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

- (void)viewDidLoad
{
    // load the preferences for the sleep alarm
    NSString *alarmId = [SLCompatibilityHelper wakeUpAlarmId];
    self.SLAlarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (self.SLAlarmPrefs == nil) {
        self.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
        self.SLAlarmPrefsChanged = YES;
    } else {
        self.SLAlarmPrefsChanged = NO;
    }

    %orig;

    // we will re-implement some of the UITableViewDataSource methods so that we can include custom cells to
    // change the Sleeper preferences
    self.tableView.dataSource = self;
}

- (void)dealloc
{
    // clear out the alarm preferences
    self.SLAlarmPrefs = nil;

    %orig;
}

- (void)saveButtonPressed
{
    // save our preferences if needed
    if (self.SLAlarmPrefsChanged || self.SLAlarmPrefs.skipActivationStatus != kSLSkipActivatedStatusUnknown) {
        self.SLAlarmPrefs.skipActivationStatus = kSLSkipActivatedStatusUnknown;
        [SLPrefsManager saveAlarmPrefs:self.SLAlarmPrefs];
    }

    %orig;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // return the original amount of sections from the data source object
    id dataSource = MSHookIvar<id>(self, "dataSource");
    return [dataSource numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // grab the original number of rows that were to be returned for a given section from the data source object
    id dataSource = MSHookIvar<id>(self, "dataSource");
    NSInteger numRows = [dataSource tableView:tableView numberOfRowsInSection:section];

    // Potentially add some extra custom rows for the additional Sleeper options to the Alarm options.  If the wake up
    // alarm has been disabled by the user, the alarm options section will be removed completely, in which case we will
    // not be adding any additional rows.
    if ([dataSource numberOfSectionsInTableView:tableView] == kSLQuickScheduleOverrideViewControllerNumSections && section == kSLQuickScheduleOverrideViewControllerSectionAlarmOptions && numRows > 0) {
        numRows = kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionNumRows;
    }
    
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // grab the original data source object for this controller
    id dataSource = MSHookIvar<id>(self, "dataSource");

    // forward declare the cell that is to be returned
    UITableViewCell *cell = nil;

    // If the cell being asked for is a custom Sleeper cell, define those here.  Otherwise ask the data source
    // object for the original cell that was created.
    if ([dataSource numberOfSectionsInTableView:tableView] == kSLQuickScheduleOverrideViewControllerNumSections &&
        indexPath.section == kSLQuickScheduleOverrideViewControllerSectionAlarmOptions) {
        if (indexPath.row < kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeTime) {
            // return the original cell from the data source
            cell = [dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
        } else {
            // Dequeue the custom cell from the table.  Create a new one if it does not yet exist.
            cell = [tableView dequeueReusableCellWithIdentifier:kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionCellReuseIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionCellReuseIdentifier];

                // set the background color of the cell
                cell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];

                // Set the selected background color of the cell.  For some reason, this cell is using systemGray4Color
                // instead of quaternaryLabelColor which is used throughout the rest of the MobileTimer application.
                if (@available(iOS 13.0, *)) {
                    UIView *backgroundView = [[UIView alloc] init];
                    backgroundView.backgroundColor = [UIColor systemGray4Color];
                    cell.selectedBackgroundView = backgroundView;
                }

                // set the text color for the title label of the cell
                cell.textLabel.textColor = [UIColor whiteColor];
            }

            if (indexPath.row == kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeTime) {
                cell.textLabel.text = kSLSnoozeTimeString;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.accessoryView = nil;
                
                // format the cell of the text with the snooze time values
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.snoozeTimeHour,
                                            (long)self.SLAlarmPrefs.snoozeTimeMinute, (long)self.SLAlarmPrefs.snoozeTimeSecond];
            } else if (indexPath.row == kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipToggle) {
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
            } else if (indexPath.row == kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipTime) {
                cell.textLabel.text = kSLSkipTimeString;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.accessoryView = nil;
                
                // format the cell of the text with the skip time values
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.skipTimeHour,
                                            (long)self.SLAlarmPrefs.skipTimeMinute, (long)self.SLAlarmPrefs.skipTimeSecond];
            } else if (indexPath.row == kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipDates) {
                cell.textLabel.text = kSLSkipDatesString;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.accessoryView = nil;

                // customize the detail text label depending on whether or not we have skip dates enabled
                cell.detailTextLabel.text = [self.SLAlarmPrefs totalSelectedDatesString];
            }
        }
    } else {
        // return the original cell from the data source
        cell = [dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    id dataSource = MSHookIvar<id>(self, "dataSource");

    // override to indicate that the custom cells can be highlighted if custom cells are being shown
    if ([dataSource numberOfSectionsInTableView:tableView] == kSLQuickScheduleOverrideViewControllerNumSections &&
        indexPath.section == kSLQuickScheduleOverrideViewControllerSectionAlarmOptions &&
        indexPath.row > kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeToggle &&
        indexPath.row != kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipToggle) {
        return YES;
    } else {
        return %orig;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id dataSource = MSHookIvar<id>(self, "dataSource");

    // handle row selection for the custom cells (if they are being shown)
    if ([dataSource numberOfSectionsInTableView:tableView] == kSLQuickScheduleOverrideViewControllerNumSections &&
        indexPath.section == kSLQuickScheduleOverrideViewControllerSectionAlarmOptions &&
        indexPath.row > kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeToggle) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        switch (indexPath.row) {
            case kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeTime: {
                // create a custom view controller which will decide the snooze time
                SLSnoozeTimeViewController *snoozeController = [[SLSnoozeTimeViewController alloc] initWithHours:self.SLAlarmPrefs.snoozeTimeHour
                                                                                                         minutes:self.SLAlarmPrefs.snoozeTimeMinute
                                                                                                         seconds:self.SLAlarmPrefs.snoozeTimeSecond];
                snoozeController.delegate = self;
                [self.navigationController pushViewController:snoozeController animated:YES];
                break;
            }
            case kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipTime: {
                // create a custom view controller which will decide the skip time
                SLSkipTimeViewController *skipController = [[SLSkipTimeViewController alloc] initWithHours:self.SLAlarmPrefs.skipTimeHour
                                                                                                   minutes:self.SLAlarmPrefs.skipTimeMinute
                                                                                                   seconds:self.SLAlarmPrefs.skipTimeSecond];
                skipController.delegate = self;
                [self.navigationController pushViewController:skipController animated:YES];
                break;
            }
            case kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipDates: {
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    id dataSource = MSHookIvar<id>(self, "dataSource");

    // potentially customize the footer text depending on whether or not the alarm is going to be skipped
    if ([dataSource numberOfSectionsInTableView:tableView] == kSLQuickScheduleOverrideViewControllerNumSections &&
        section == kSLQuickScheduleOverrideViewControllerSectionAlarmOptions) {
        return [self.SLAlarmPrefs skipReasonExplanation];
    } else {
        return [dataSource tableView:tableView titleForFooterInSection:section];
    }
}

// handle when the skip switch is changed
%new
- (void)SLSkipControlChanged:(UISwitch *)skipSwitch
{
    self.SLAlarmPrefs.skipEnabled = skipSwitch.on;

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
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
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSnoozeTime
                                                                    inSection:kSLQuickScheduleOverrideViewControllerSectionAlarmOptions]]
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
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipTime
                                                                    inSection:kSLQuickScheduleOverrideViewControllerSectionAlarmOptions]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
}

#pragma mark - SLSkipDatesDelegate

// create a new delegate method for when the skip dates controller has updated skip dates
%new
- (void)SLSkipDatesViewController:(SLSkipDatesViewController *)skipDatesViewController didUpdateCustomSkipDates:(NSArray *)customSkipDates holidaySkipDates:(NSDictionary *)holidaySkipDates
{
    self.SLAlarmPrefs.customSkipDates = customSkipDates;
    self.SLAlarmPrefs.holidaySkipDates = holidaySkipDates;

    // reload the cell that contains the skip dates
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSLQuickScheduleOverrideViewControllerAlarmOptionsSectionRowSkipDates
                                                                inSection:kSLQuickScheduleOverrideViewControllerSectionAlarmOptions]]
                          withRowAnimation:UITableViewRowAnimationNone];

    // force the footer title to update since the explanation to display might have changed
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView footerViewForSection:kSLQuickScheduleOverrideViewControllerSectionAlarmOptions].textLabel.text = [self.SLAlarmPrefs skipReasonExplanation];
    [[self.tableView footerViewForSection:kSLQuickScheduleOverrideViewControllerSectionAlarmOptions].textLabel sizeToFit];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS14) {
        // to enable compatibility with older versions of iOS, we need to manually load the new SleepHealthUI framework (introduced with iOS 14)
        NSBundle *sleepHealthUIBundle = [SLCompatibilityHelper sleepHealthUIBundle];
        if (sleepHealthUIBundle != nil) {
            [sleepHealthUIBundle load];
            if ([sleepHealthUIBundle isLoaded]) {
                %init();
            }
        }
    }
}