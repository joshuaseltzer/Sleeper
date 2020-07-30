//
//  SLEditAlarmViewController.x
//  The view controller responsible for editing an iOS alarm.
//
//  Created by Joshua Seltzer on 2/21/17.
//
//

#import "SLUserInterfaceHeaders.h"
#import "custom/SLSnoozeTimeViewController.h"
#import "custom/SLAutoSetOptionsTableViewController.h"
#import "../common/SLPrefsManager.h"
#import "../common/SLLocalizedStrings.h"
#import "../common/SLCompatibilityHelper.h"

// define an enum to reference the sections of the table view
typedef enum SLEditAlarmViewSection : NSUInteger {
    kSLEditAlarmViewSectionAttribute,
    kSLEditAlarmViewSectionAutoSet,
    kSLEditAlarmViewSectionDelete,
    kSLEditAlarmViewNumSections
} SLEditAlarmViewSection;

// define an enum to reference the rows in the attributes section of the table view
typedef enum SLEditAlarmViewAttributeSectionRow : NSUInteger {
    kSLEditAlarmViewAttributeSectionRowRepeat,
    kSLEditAlarmViewAttributeSectionRowLabel,
    kSLEditAlarmViewAttributeSectionRowSound,
    kSLEditAlarmViewAttributeSectionRowSnoozeToggle,
    kSLEditAlarmViewAttributeSectionRowSnoozeTime,
    kSLEditAlarmViewAttributeSectionRowSkipToggle,
    kSLEditAlarmViewAttributeSectionRowSkipTime,
    kSLEditAlarmViewAttributeSectionRowSkipDates,
    kSLEditAlarmViewAttributeSectionNumRows
} SLEditAlarmViewAttributeSectionRow;

// the editing alarm view which contains the main tableview for this controller
@interface EditAlarmView : UIView

// the date picker used to set the alarm's time
@property (readonly, nonatomic) UIDatePicker *timePicker;

@end

// The primary view controller which recieves the ability to edit the snooze time.  This view controller
// conforms to custom delegates that are used to notify when alarm attributes change.
@interface EditAlarmViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
SLPickerSelectionDelegate, SLSkipDatesDelegate, SLAutoSetOptionsDelegate> {
    EditAlarmView *_editAlarmView;
}

// the alarm object associated with the controller
@property (readonly, assign, nonatomic) Alarm *alarm;

@end

// custom interface for added properties to the edit alarm view controller
@interface EditAlarmViewController (Sleeper)

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;
@property (nonatomic, assign) BOOL SLAlarmPrefsChanged;
@property (nonatomic, assign) BOOL SLCanEnableAutoSet;

- (void)SLUpdateTimePickerEnabled;

@end

%hook EditAlarmViewController

// the Sleeper preferences for the alarm being displayed
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

// boolean property to signify whether or not changes were made to the Sleeper preferences
%property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

// boolean that indicates whether or not auto-set can be enabled for this alarm
%property (nonatomic, assign) BOOL SLCanEnableAutoSet;

- (void)viewDidLoad
{
    // get the alarm Id from the alarm for this controller
    NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:self.alarm];

    // check whether or not we can enable auto-set
    self.SLCanEnableAutoSet = [SLCompatibilityHelper canEnableAutoSet];

    // load the preferences for the alarm
    self.SLAlarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (self.SLAlarmPrefs == nil) {
        self.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
        self.SLAlarmPrefsChanged = YES;
    } else {
        // if auto-set was enabled for this alarm but it cannot be enabled, disable it
        if (!self.SLCanEnableAutoSet && self.SLAlarmPrefs.autoSetOption != kSLAutoSetOptionOff) {
            self.SLAlarmPrefs.autoSetOption = kSLAutoSetOptionOff;
            self.SLAlarmPrefsChanged = YES;
        } else {
            self.SLAlarmPrefsChanged = NO;
        }
    }

    // update the enabled status of the time picker, which will depend on the auto-set option
    [self SLUpdateTimePickerEnabled];

    %orig;
}

- (void)dealloc
{
    // clear out the alarm preferences
    self.SLAlarmPrefs = nil;

    %orig;
}

// updates the ability for the user to interact with the time picker that is included in this controller
%new
- (void)SLUpdateTimePickerEnabled
{
    // grab the edit alarm view which contains the timer picker
    EditAlarmView *editAlarmView = MSHookIvar<EditAlarmView *>(self, "_editAlarmView");

    // the time picker will be disabled if any auto-set option is selected
    if (self.SLAlarmPrefs.autoSetOption == kSLAutoSetOptionOff) {
        editAlarmView.timePicker.enabled = YES;
    } else {
        editAlarmView.timePicker.enabled = NO;
    }
}

- (void)_doneButtonClicked:(id)doneButton
{
    // save our preferences if needed
    if (self.SLAlarmPrefsChanged || self.SLAlarmPrefs.skipActivationStatus != kSLSkipActivatedStatusUnknown) {
        self.SLAlarmPrefs.skipActivationStatus = kSLSkipActivatedStatusUnknown;
        [SLPrefsManager saveAlarmPrefs:self.SLAlarmPrefs];
    }

    %orig;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numSections = %orig;

    // add a section for the sunrise/sunset option if we are on iOS 10
    if (kSLSystemVersioniOS10) {
        ++numSections;
    }

    return numSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Grab the number of rows originally returned for this table.  The sunrise/sunset section and delete sections will
    // both have 1 row, so we only need to modify the attribute section.
    NSInteger numRows = %orig;
    
    // add custom rows to allow the user to edit the snooze time and configure skipping
    if (section == kSLEditAlarmViewSectionAttribute) {
        numRows = kSLEditAlarmViewAttributeSectionNumRows;
    }
    
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // forward declare the cell that is to be returned
    UITableViewCell *cell = nil;
    
    // configure the custom cells
    if (indexPath.section == kSLEditAlarmViewSectionAttribute) {
        // grab the original cell that is defined for this section
        cell = %orig;

        // if we are not editing the snooze alarm switch row, we must destroy the accessory view for the
        // cell so that it is not reused on the wrong cell
        if (indexPath.row != kSLEditAlarmViewAttributeSectionRowSnoozeToggle) {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        if (indexPath.row == kSLEditAlarmViewAttributeSectionRowSnoozeTime) {
            cell.textLabel.text = kSLSnoozeTimeString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            // format the cell of the text with the snooze time values
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.snoozeTimeHour,
                                        (long)self.SLAlarmPrefs.snoozeTimeMinute, (long)self.SLAlarmPrefs.snoozeTimeSecond];
        } else if (indexPath.row == kSLEditAlarmViewAttributeSectionRowSkipToggle) {
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
        } else if (indexPath.row == kSLEditAlarmViewAttributeSectionRowSkipTime) {
            cell.textLabel.text = kSLSkipTimeString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            // format the cell of the text with the skip time values
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.skipTimeHour,
                                        (long)self.SLAlarmPrefs.skipTimeMinute, (long)self.SLAlarmPrefs.skipTimeSecond];
        } else if (indexPath.row == kSLEditAlarmViewAttributeSectionRowSkipDates) {
            cell.textLabel.text = kSLSkipDatesString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            // customize the detail text label depending on whether or not we have skip dates enabled
            cell.detailTextLabel.text = [self.SLAlarmPrefs totalSelectedDatesString];
        }
    } else if (kSLSystemVersioniOS10 && indexPath.section == kSLEditAlarmViewSectionAutoSet) {
        // grab a cell from the attribute section to customize
        cell = %orig(tableView, [NSIndexPath indexPathForRow:0 inSection:kSLEditAlarmViewSectionAttribute]);

        // customize the cell that will be used to allow the user to customize the sun options
        cell.textLabel.text = kSLAutoSetString;
        cell.detailTextLabel.text = [SLPrefsManager friendlyNameForAutoSetOption:self.SLAlarmPrefs.autoSetOption];
    } else if (kSLSystemVersioniOS10 && indexPath.section == kSLEditAlarmViewSectionDelete) {
        // grab the cell that would originally be returned for the delete section
        cell = %orig(tableView, [NSIndexPath indexPathForRow:0 inSection:kSLEditAlarmViewSectionAutoSet]);
    } else {
        cell = %orig;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // handle row selection for the custom cells
    if (indexPath.section == kSLEditAlarmViewSectionAttribute) {
        if (indexPath.row == kSLEditAlarmViewAttributeSectionRowSnoozeTime) {
            // create a custom view controller which will decide the snooze time
            SLSnoozeTimeViewController *snoozeController = [[SLSnoozeTimeViewController alloc] initWithHours:self.SLAlarmPrefs.snoozeTimeHour
                                                                                                     minutes:self.SLAlarmPrefs.snoozeTimeMinute
                                                                                                     seconds:self.SLAlarmPrefs.snoozeTimeSecond];
            snoozeController.delegate = self;
            [self.navigationController pushViewController:snoozeController animated:YES];
        } else if (indexPath.row == kSLEditAlarmViewAttributeSectionRowSkipTime) {
            // create a custom view controller which will decide the skip time
            SLSkipTimeViewController *skipController = [[SLSkipTimeViewController alloc] initWithHours:self.SLAlarmPrefs.skipTimeHour
                                                                                               minutes:self.SLAlarmPrefs.skipTimeMinute
                                                                                               seconds:self.SLAlarmPrefs.skipTimeSecond];
            skipController.delegate = self;
            [self.navigationController pushViewController:skipController animated:YES];
        } else if (indexPath.row == kSLEditAlarmViewAttributeSectionRowSkipDates) {
            // create a custom view controller which will display the skip dates for this alarm
            SLSkipDatesViewController *skipDatesController = [[SLSkipDatesViewController alloc] initWithAlarmPrefs:self.SLAlarmPrefs];
            skipDatesController.delegate = self;
            [self.navigationController pushViewController:skipDatesController animated:YES];
        } else if (indexPath.row != kSLEditAlarmViewAttributeSectionRowSkipToggle) {
            %orig;
        }
    } else if (kSLSystemVersioniOS10 && indexPath.section == kSLEditAlarmViewSectionAutoSet) {
        // check to see if the user can enable auto-set before proceeding
        if (self.SLCanEnableAutoSet) {
            // create a custom view controller which will display the auto-set options
            SLAutoSetOptionsTableViewController *autoSetOptionsController = [[SLAutoSetOptionsTableViewController alloc] initWithAutoSetOption:self.SLAlarmPrefs.autoSetOption
                                                                                                                           autoSetOffsetOption:self.SLAlarmPrefs.autoSetOffsetOption
                                                                                                                             autoSetOffsetHour:self.SLAlarmPrefs.autoSetOffsetHour
                                                                                                                           autoSetOffsetMinute:self.SLAlarmPrefs.autoSetOffsetMinute];
            autoSetOptionsController.delegate = self;
            [self.navigationController pushViewController:autoSetOptionsController animated:YES];
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            // display an alert notifying the user that the Weather application is required to enable auto-set
            UIAlertController *autoSetDisabledAlertController = [UIAlertController alertControllerWithTitle:kSLAutoSetString
                                                                                                    message:kSLAutoSetDisabledExplanationString
                                                                                             preferredStyle:UIAlertControllerStyleAlert];

            // create an action that will close the alert
            UIAlertAction *okAlertAction = [UIAlertAction actionWithTitle:kSLOkString
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:nil];
            [autoSetDisabledAlertController addAction:okAlertAction];
            
            // modify the subviews of the alert controller if necessary
            [SLCompatibilityHelper updateSubviewsForAlertController:autoSetDisabledAlertController];

            // present the alert
            [self presentViewController:autoSetDisabledAlertController animated:YES completion:nil];
        }
    } else if (kSLSystemVersioniOS10 && indexPath.section == kSLEditAlarmViewSectionDelete) {
        // perform the logic that was originally for the delete section
        %orig(tableView, [NSIndexPath indexPathForRow:0 inSection:kSLEditAlarmViewSectionAutoSet]);
    } else {
        %orig;
    }
}

// potentially customize the footer text depending on whether or not the alarm is going to be skipped
%new
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerTitle = nil;
    if (section == kSLEditAlarmViewSectionAttribute) {
        footerTitle = [self.SLAlarmPrefs skipReasonExplanation];
    } else if (kSLSystemVersioniOS10 && section == kSLEditAlarmViewSectionAutoSet) {
        footerTitle = [self.SLAlarmPrefs autoSetExplanation];
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

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
}

#pragma mark - SLAutoSetOptionsDelegate

// update this alarm's preferences with the selections from the auto-set options controller
%new
- (void)SLAutoSetOptionsTableViewController:(SLAutoSetOptionsTableViewController *)autoSetOptionsTableViewController
                     didUpdateAutoSetOption:(SLAutoSetOption)autoSetOption
                    withAutoSetOffsetOption:(SLAutoSetOffsetOption)autoSetOffsetOption
                      withAutoSetOffsetHour:(NSInteger)autoSetOffsetHour
                    withAutoSetOffsetMinute:(NSInteger)autoSetOffsetMinute
{
    self.SLAlarmPrefs.autoSetOption = autoSetOption;
    self.SLAlarmPrefs.autoSetOffsetOption = autoSetOffsetOption;
    self.SLAlarmPrefs.autoSetOffsetHour = autoSetOffsetHour;
    self.SLAlarmPrefs.autoSetOffsetMinute = autoSetOffsetMinute;

    // update the enabled status of the time picker, which will depend on the auto-set option
    [self SLUpdateTimePickerEnabled];

    // signify that changes were made to the Sleeper preferences
    self.SLAlarmPrefsChanged = YES;
}

%end

%ctor {
    // only initialize this file if we are on iOS 8, iOS 9, or iOS 10
    if (kSLSystemVersioniOS8 || kSLSystemVersioniOS9 || kSLSystemVersioniOS10) {
        %init();
    }
}