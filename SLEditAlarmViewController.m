//
//  SLEditAlarmViewController.x
//  The view controller responsible for editing an iOS alarm.
//
//  Created by Joshua Seltzer on 2/21/17.
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
typedef enum SLEditAlarmViewSection : NSUInteger {
    kSLEditAlarmViewSectionAttribute,
    kSLEditAlarmViewSectionDelete
} SLEditAlarmViewSection;

// define an enum to reference the rows in the attributes section of the table view
typedef enum SLEditAlarmViewSectionAttributeRow : NSUInteger {
    kSLEditAlarmViewSectionAttributeRowRepeat,
    kSLEditAlarmViewSectionAttributeRowLabel,
    kSLEditAlarmViewSectionAttributeRowSound,
    kSLEditAlarmViewSectionAttributeRowSnoozeToggle,
    kSLEditAlarmViewSectionAttributeRowSnoozeTime,
    kSLEditAlarmViewSectionAttributeRowSkipToggle,
    kSLEditAlarmViewSectionAttributeRowSkipTime
} SLEditAlarmViewSectionAttributeRow;

// the custom cell used to display information when editing an alarm
@interface MoreInfoTableViewCell : UITableViewCell
@end

// The primary view controller which recieves the ability to edit the snooze time.  This view controller
// conforms to custom delegates that are used to notify when alarm attributes change.
@interface EditAlarmViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
SLPickerSelectionDelegate>

// the alarm object associated with the controller
@property (readonly, assign, nonatomic) Alarm *alarm;

@end

// custom interface for added properties to the edit alarm view controller
@interface EditAlarmViewController (Sleeper)

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

@end

%hook EditAlarmViewController

// the Sleeper preferences for the alarm being displayed
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

- (void)viewDidLoad
{
    // get the alarm Id from the alarm for this controller
    NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:self.alarm];

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
    if (section == kSLEditAlarmViewSectionAttribute) {
        numRows = numRows + 3;
    }
    
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // grab the original cell that is defined for this table
    MoreInfoTableViewCell *cell = (MoreInfoTableViewCell *)%orig;
    
    // configure the custom cells
    if (indexPath.section == kSLEditAlarmViewSectionAttribute) {
        // if we are not editing the snooze alarm switch row, we must destroy the accessory view for the
        // cell so that it is not reused on the wrong cell
        if (indexPath.row != kSLEditAlarmViewSectionAttributeRowSnoozeToggle) {
            cell.accessoryView = nil;
        }

        if (indexPath.row == kSLEditAlarmViewSectionAttributeRowSnoozeTime) {
            cell.textLabel.text = kSLSnoozeTimeString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            // format the cell of the text with the snooze time values
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.snoozeTimeHour,
                                        (long)self.SLAlarmPrefs.snoozeTimeMinute, (long)self.SLAlarmPrefs.snoozeTimeSecond];
        } else if (indexPath.row == kSLEditAlarmViewSectionAttributeRowSkipToggle) {
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
        } else if (indexPath.row == kSLEditAlarmViewSectionAttributeRowSkipTime) {
            cell.textLabel.text = kSLSkipTimeString;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            // format the cell of the text with the skip time values
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)self.SLAlarmPrefs.skipTimeHour,
                                        (long)self.SLAlarmPrefs.skipTimeMinute, (long)self.SLAlarmPrefs.skipTimeSecond];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // handle row selection for the custom cells
    if (indexPath.section == kSLEditAlarmViewSectionAttribute) {
        if (indexPath.row == kSLEditAlarmViewSectionAttributeRowSnoozeTime) {
            // create a custom view controller which will decide the snooze time
            SLSnoozeTimeViewController *snoozeController = [[SLSnoozeTimeViewController alloc] initWithHours:self.SLAlarmPrefs.snoozeTimeHour
                                                                                                     minutes:self.SLAlarmPrefs.snoozeTimeMinute
                                                                                                     seconds:self.SLAlarmPrefs.snoozeTimeSecond];
            snoozeController.delegate = self;
            
            // push the controller to our stack
            [self.navigationController pushViewController:snoozeController animated:YES];
        } else if (indexPath.row == kSLEditAlarmViewSectionAttributeRowSkipTime) {
            // create a custom view controller which will decide the skip time
            SLSkipTimeViewController *skipController = [[SLSkipTimeViewController alloc] initWithHours:self.SLAlarmPrefs.skipTimeHour
                                                                                               minutes:self.SLAlarmPrefs.skipTimeMinute
                                                                                               seconds:self.SLAlarmPrefs.skipTimeSecond];
            skipController.delegate = self;
            
            // push the controller to our stack
            [self.navigationController pushViewController:skipController animated:YES];
        } else if (indexPath.row != kSLEditAlarmViewSectionAttributeRowSkipToggle) {
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

%end