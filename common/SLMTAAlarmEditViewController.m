//
//  SLMTAAlarmEditViewController.x
//  The view controller responsible for editing an iOS alarm (introduced in iOS 11, also used in iOS 12).
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
typedef enum SLMTAAlarmEditViewControllerSection : NSUInteger {
    kSLMTAAlarmEditViewControllerSectionAttribute,
    kSLMTAAlarmEditViewControllerSectionDelete,
    kSLMTAAlarmEditViewControllerNumSections
} SLMTAAlarmEditViewControllerSection;

// define an enum to reference the rows in SLMTAAlarmEditViewControllerSection
typedef enum SLMTAAlarmEditViewControllerAttributeSectionRow : NSUInteger {
    kSLMTAAlarmEditViewControllerAttributeSectionRowRepeat,
    kSLMTAAlarmEditViewControllerAttributeSectionRowLabel,
    kSLMTAAlarmEditViewControllerAttributeSectionRowSound,
    kSLMTAAlarmEditViewControllerAttributeSectionRowSnoozeToggle,
    kSLMTAAlarmEditViewControllerAttributeSectionRowSnoozeTime,
    kSLMTAAlarmEditViewControllerAttributeSectionRowSkipToggle,
    kSLMTAAlarmEditViewControllerAttributeSectionRowSkipTime,
    kSLMTAAlarmEditViewControllerAttributeSectionRowSkipDates,
    kSLMTAAlarmEditViewControllerAttributeSectionNumRows
} SLMTAAlarmEditViewControllerAttributeSectionRow;

// the custom cell used to display information when editing an alarm
@interface MoreInfoTableViewCell : UITableViewCell
@end

// The primary view controller which recieves the ability to edit the snooze time.  This view controller
// conforms to custom delegates that are used to notify when alarm attributes change.
@interface MTAAlarmEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
SLPickerSelectionDelegate, SLSkipDatesDelegate>

// the edited alarm object for this view controller (iOS 12)
@property (retain, nonatomic) MTMutableAlarm *editedAlarm;

// the alarm object associated with the controller (iOS 11)
@property (readonly, nonatomic) Alarm *alarm;

@end

// custom interface for added properties to the edit alarm view controller
@interface MTAAlarmEditViewController (Sleeper)

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

@end

%hook MTAAlarmEditViewController

// the Sleeper preferences for the alarm being displayed
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

- (void)viewDidLoad
{
    // get the alarm Id from the alarm for this controller
    NSString *alarmId = nil;
    if (kSLSystemVersioniOS12) {
        alarmId = [self.editedAlarm alarmIDString];
    } else {
        alarmId = [SLCompatibilityHelper alarmIdForAlarm:self.alarm];
    }

    // load the preferences for the alarm
    self.SLAlarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (self.SLAlarmPrefs == nil) {
        self.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
    }

    %orig;
}

- (void)dealloc
{
    // clear out the alarm preferences
    self.SLAlarmPrefs = nil;

    %orig;
}

- (void)_doneButtonClicked:(id)doneButton
{
    // save our preferences
    [SLPrefsManager saveAlarmPrefs:self.SLAlarmPrefs];

    %orig;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = %orig;
    
    // add custom rows to allow the user to edit the snooze time and configure skipping
    if (section == kSLMTAAlarmEditViewControllerSectionAttribute) {
        numRows = kSLMTAAlarmEditViewControllerAttributeSectionNumRows;
    }
    
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // grab the original cell that is defined for this table
    MoreInfoTableViewCell *cell = (MoreInfoTableViewCell *)%orig;
    
    // configure the custom cells
    if (indexPath.section == kSLMTAAlarmEditViewControllerSectionAttribute) {
        // if we are not editing the snooze alarm switch row, we must destroy the accessory view for the
        // cell so that it is not reused on the wrong cell
        if (indexPath.row != kSLMTAAlarmEditViewControllerAttributeSectionRowSnoozeToggle) {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        if (indexPath.row == kSLMTAAlarmEditViewControllerAttributeSectionRowSnoozeTime) {
            cell.textLabel.text = kSLSnoozeTimeString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            // format the cell of the text with the snooze time values
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.snoozeTimeHour,
                                        (long)self.SLAlarmPrefs.snoozeTimeMinute, (long)self.SLAlarmPrefs.snoozeTimeSecond];
        } else if (indexPath.row == kSLMTAAlarmEditViewControllerAttributeSectionRowSkipToggle) {
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
        } else if (indexPath.row == kSLMTAAlarmEditViewControllerAttributeSectionRowSkipTime) {
            cell.textLabel.text = kSLSkipTimeString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            // format the cell of the text with the skip time values
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.skipTimeHour,
                                        (long)self.SLAlarmPrefs.skipTimeMinute, (long)self.SLAlarmPrefs.skipTimeSecond];
        } else if (indexPath.row == kSLMTAAlarmEditViewControllerAttributeSectionRowSkipDates) {
            cell.textLabel.text = kSLSkipDatesString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            // customize the detail text label depending on whether or not we have skip dates enabled
            cell.detailTextLabel.text = [self.SLAlarmPrefs totalSelectedDatesString];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // handle row selection for the custom cells
    if (indexPath.section == kSLMTAAlarmEditViewControllerSectionAttribute) {
        if (indexPath.row == kSLMTAAlarmEditViewControllerAttributeSectionRowSnoozeTime) {
            // create a custom view controller which will decide the snooze time
            SLSnoozeTimeViewController *snoozeController = [[SLSnoozeTimeViewController alloc] initWithHours:self.SLAlarmPrefs.snoozeTimeHour
                                                                                                     minutes:self.SLAlarmPrefs.snoozeTimeMinute
                                                                                                     seconds:self.SLAlarmPrefs.snoozeTimeSecond];
            snoozeController.delegate = self;
            [self.navigationController pushViewController:snoozeController animated:YES];
        } else if (indexPath.row == kSLMTAAlarmEditViewControllerAttributeSectionRowSkipTime) {
            // create a custom view controller which will decide the skip time
            SLSkipTimeViewController *skipTimeController = [[SLSkipTimeViewController alloc] initWithHours:self.SLAlarmPrefs.skipTimeHour
                                                                                                   minutes:self.SLAlarmPrefs.skipTimeMinute
                                                                                                   seconds:self.SLAlarmPrefs.skipTimeSecond];
            skipTimeController.delegate = self;
            [self.navigationController pushViewController:skipTimeController animated:YES];
        } else if (indexPath.row == kSLMTAAlarmEditViewControllerAttributeSectionRowSkipDates) {
            // create a custom view controller which will display the skip dates for this alarm
            SLSkipDatesViewController *skipDatesController = [[SLSkipDatesViewController alloc] initWithAlarmPrefs:self.SLAlarmPrefs];
            skipDatesController.delegate = self;
            [self.navigationController pushViewController:skipDatesController animated:YES];
        } else if (indexPath.row != kSLMTAAlarmEditViewControllerAttributeSectionRowSkipToggle) {
            %orig;
        }
    } else {
        %orig;
    }
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

#pragma mark - SLSkipDatesDelegate

// create a new delegate method for when the skip dates controller has updated skip dates
%new
- (void)SLSkipDatesViewController:(SLSkipDatesViewController *)skipDatesViewController didUpdateCustomSkipDates:(NSArray *)customSkipDates holidaySkipDates:(NSDictionary *)holidaySkipDates
{
    self.SLAlarmPrefs.customSkipDates = customSkipDates;
    self.SLAlarmPrefs.holidaySkipDates = holidaySkipDates;
}

%end

%ctor {
    // only initialize this file if we are on iOS 11 or iOS 12
    if (kSLSystemVersioniOS11 || kSLSystemVersioniOS12) {
        %init();
    }
}