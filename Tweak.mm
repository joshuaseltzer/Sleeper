//
//  Tweak.mm
//  Contains all hooks into Apple's code which handles saving, deleting, and changing the snooze time.
//
//  Created by Joshua Seltzer on 12/15/14.
//
//

#import <UIKit/UIKit.h>
#import "Sleeper/Sleeper/JSSnoozeTimeViewController.h"
#import "Sleeper/Sleeper/JSPrefsManager.h"
#import "Sleeper/Sleeper/JSLocalizedStrings.h"
#import "AppleInterfaces.h"

// define the constants that define where the custom rows will be inserted
static int const kJSSnoozeTimeTableSection =    0;
static int const kJSSnoozeAlarmTableRow =       3;
static int const kJSSnoozeTimeTableRow =        4;
static int const kJSSkipAlarmTableRow =         5;
static int const kJSSkipTimeTableRow =          6;

// static variables that are set when the switches are toggled
//static BOOL sJSSnoozeSwitchOn;
//static BOOL sJSSkipSwitchOn;

// Static variables that define the snooze time of the current alarm.  Only one alarm can be edited
// at a time, so we can get away with just single variables here that get overwritten as alarms are
// edited and changed
static NSInteger sJSSnoozeHours;
static NSInteger sJSSnoozeMinutes;
static NSInteger sJSSnoozeSeconds;

// hook the view controller that allows the editing of alarms
%hook EditAlarmViewController

// override to get values to define the snooze time for this particular alarm
- (void)viewDidLoad
{
    // check if the alarm for this view controller has snooze enabled
    //sJSSnoozeSwitchOn = self.alarm.allowsSnooze;
    
    // get the alarm prefs for the given alarm Id that this view is responsible for
    NSMutableDictionary *alarmInfo = [JSPrefsManager snoozeTimeForId:self.alarm.alarmId];
    if (alarmInfo) {
        // grab the attriburtes from the alarm info if we had some saved
        sJSSnoozeHours = [[alarmInfo objectForKey:kJSSnoozeHourKey] integerValue];
        sJSSnoozeMinutes = [[alarmInfo objectForKey:kJSSnoozeMinuteKey] integerValue];
        sJSSnoozeSeconds = [[alarmInfo objectForKey:kJSSnoozeSecondKey] integerValue];
    } else {
        // if snooze info was not previously saved for this alarm, then use the default values
        sJSSnoozeHours = kJSDefaultSnoozeHour;
        sJSSnoozeMinutes = kJSDefaultSnoozeMinute;
        sJSSnoozeSeconds = kJSDefaultSnoozeSecond;
    }
    
    %orig;
}

// override to add rows to the table
- (int)tableView:(id)view numberOfRowsInSection:(int)section
{
    // keep track of the number of rows to return
    NSInteger numRows = %orig;
    
    // add custom rows to allow the user to edit the snooze time and configure skipping
    // add a row to the section to allow the user to control the snooze time
    if (section == kJSSnoozeTimeTableSection) {
        numRows = numRows + 3;
    }
    
    return numRows;
}

// override to customize our added rows in the table
- (id)tableView:(id)view cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // grab the original cell that is defined for this table
    MoreInfoTableViewCell *cell = (MoreInfoTableViewCell *)%orig();
    
    // if we are not editing the snooze alarm switch row, we must destroy the accessory view for the
    // cell so that it is not reused on the wrong cell
    if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row != kJSSnoozeAlarmTableRow) {
        cell.accessoryView = nil;
    }
    
    // insert our custom cell if it is the appropriate section and row
    if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSnoozeTimeTableRow) {
        // customize the cell
        cell.textLabel.text = LZ_SNOOZE_TIME;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // format the cell of the text with the snooze time values
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)sJSSnoozeHours,
                                     (long)sJSSnoozeMinutes, (long)sJSSnoozeSeconds];
    } else if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSkipAlarmTableRow) {
        // customize the cell
        cell.textLabel.text = LZ_SKIP;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.text = nil;
        
        // create a switch to allow the user to toggle on and off the skip functionality
        UISwitch *skipSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
        skipSwitch.on = YES;
        
        // set the switch to the custom view in the cell
        cell.accessoryView = skipSwitch;
    } else if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSkipTimeTableRow) {
        // customize the cell
        cell.textLabel.text = LZ_SKIP_TIME;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

// override to handle row selection
- (void)tableView:(id)view didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // handle row selection for the custom cells
    if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSnoozeTimeTableRow) {
        // push our custom view controller which will decide the snooze time
        JSSnoozeTimeViewController *snoozeController = [[JSSnoozeTimeViewController alloc] initWithHours:sJSSnoozeHours
                                                                                                 minutes:sJSSnoozeMinutes
                                                                                                 seconds:sJSSnoozeSeconds];
        
        // set the delegate of the custom controller to self so that we can monitor changes to the
        // snooze time
        snoozeController.delegate = self;
        
        // push the controller to our stack
        [self.navigationController pushViewController:snoozeController animated:YES];
    } else if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSkipAlarmTableRow) {
        
    } else if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSkipTimeTableRow) {
        
    } else {
        // perform the original implementation for row selections
        %orig;
    }
}

// override to handle when the snooze switch is enabled or disabled
/*- (void)_snoozeControlChanged:(UISwitch *)changed
{
    // grab the alarm view from the controller
    EditAlarmView *editAlarmView = MSHookIvar<EditAlarmView *>(self, "_editAlarmView");
    
    // check the value of the switch to see if we need to add/remove rows
    if (changed.on && !sJSSnoozeSwitchOn) {
        // update our static varible to signify that the switch is on
        sJSSnoozeSwitchOn = YES;

        // insert the snooze time row into the table
        [editAlarmView.settingsTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kJSSnoozeTimeTableRow
                                                                                 inSection:kJSSnoozeTimeTableSection]]
                                           withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (!changed.on && sJSSnoozeSwitchOn) {
        // update our static varible to signify that the switch is off
        sJSSnoozeSwitchOn = NO;
        
        // delete the snooze time row from the table
        [editAlarmView.settingsTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kJSSnoozeTimeTableRow
                                                                                 inSection:kJSSnoozeTimeTableSection]]
                                           withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    %orig;
}*/

// override to handle when an alarm gets saved
- (void)_doneButtonClicked:(id)arg1
{
    // perform the original save implementation
    %orig;

    // save the snooze time so that it can be read later
    [JSPrefsManager saveSnoozeTimeForAlarmId:self.alarm.alarmId
                                            hours:sJSSnoozeHours
                                          minutes:sJSSnoozeMinutes
                                          seconds:sJSSnoozeSeconds];
}

#pragma mark - JSSnoozeTimeDelegate

// create the new delegate method that tells the editing view controller what snooze time was selected
%new
- (void)alarmDidUpdateWithHours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds
{
    if (hours == 0 && minutes == 0 && seconds == 0) {
        // if all values returned are 0, then reset them to the default
        sJSSnoozeHours = kJSDefaultSnoozeHour;
        sJSSnoozeMinutes = kJSDefaultSnoozeMinute;
        sJSSnoozeSeconds = kJSDefaultSnoozeSecond;
    } else {
        // otherwise save our returned values
        sJSSnoozeHours = hours;
        sJSSnoozeMinutes = minutes;
        sJSSnoozeSeconds = seconds;
    }
}

%end

// hook the SpringBoard process which handles local notifications
%hook SBApplication

// override to insert our custom snooze time if it was defined
- (void)scheduleSnoozeNotification:(UIConcreteLocalNotification *)notification
{
    // grab the alarm Id from the notification
    NSString *alarmId = [notification.userInfo objectForKey:kJSAlarmIdKey];
    
    // check to see if we have an updated snooze time for this alarm
    NSMutableDictionary *alarmInfo = [JSPrefsManager snoozeTimeForId:alarmId];
    if (alarmInfo) {
        // grab the saved values
        NSInteger hours = [[alarmInfo objectForKey:kJSSnoozeHourKey] integerValue];
        NSInteger minutes = [[alarmInfo objectForKey:kJSSnoozeMinuteKey] integerValue];
        NSInteger seconds = [[alarmInfo objectForKey:kJSSnoozeSecondKey] integerValue];
        
        // subtract the default snooze time from these values since they have already been added to
        // the fire date
        hours = hours - kJSDefaultSnoozeHour;
        minutes = minutes - kJSDefaultSnoozeMinute;
        seconds = seconds - kJSDefaultSnoozeSecond;
        
        // convert the entire value into seconds
        NSTimeInterval timeInterval = hours * 3600 + minutes * 60 + seconds;
        
        // modify the fire date of the notification
        notification.fireDate = [notification.fireDate dateByAddingTimeInterval:timeInterval];
    }
    
    // perform the original implementation
    %orig;
}

%end

// hook into the alarm manager so that we can remove any saved snooze times when an alarm is deleted
%hook AlarmManager

// override to remove snooze times for the given alarm from our preferences
- (void)removeAlarm:(Alarm *)alarm
{
    // perform the original remove implementation
    %orig;

    // delete the snooze time for this given alarm
    [JSPrefsManager deleteSnoozeTimeForAlarmId:alarm.alarmId];
}

%end