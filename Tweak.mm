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
#import "AppleInterfaces.h"

// define the constants that define where the snooze time row will be inserted
static int const kJSSnoozeTimeTableSection =    0;
static int const kJSSnoozeTimeTableRow =        4;

// static variable that is set when the snooze switch is toggled
static BOOL sJSSnoozeSwitchOn;

// Static variables that define the snooze time of the current alarm.  Only one alarm can be edited
// at a time, so we can get away with just single variables here that get overwritten as alarms are
// edited and changed
static NSInteger sJSHours;
static NSInteger sJSMinutes;
static NSInteger sJSSeconds;

// hook the view controller that allows the editing of alarms
%hook EditAlarmViewController

// override to get values to define the snooze time for this particular alarm
- (void)viewDidLoad
{
    // check if the alarm for this view controller has snooze enabled
    sJSSnoozeSwitchOn = self.alarm.allowsSnooze;
    
    // get the alarm prefs for the given alarm Id that this view is responsible for
    NSMutableDictionary *alarmInfo = [JSPrefsManager snoozeTimeForId:self.alarm.alarmId];
    if (alarmInfo) {
        // grab the attriburtes from the alarm info if we had some saved
        sJSHours = [[alarmInfo objectForKey:kJSHourKey] integerValue];
        sJSMinutes = [[alarmInfo objectForKey:kJSMinuteKey] integerValue];
        sJSSeconds = [[alarmInfo objectForKey:kJSSecondKey] integerValue];
    } else {
        // if snooze info was not previously saved for this alarm, then use the default values
        sJSHours = kJSDefaultHour;
        sJSMinutes = kJSDefaultMinute;
        sJSSeconds = kJSDefaultSecond;
    }
    
    %orig;
}

// override to add rows to the table
- (int)tableView:(id)view numberOfRowsInSection:(int)section
{
    // add a row to the section to allow the user to control the snooze time
    if (section == kJSSnoozeTimeTableSection && sJSSnoozeSwitchOn) {
        return %orig + 1;
    }
    
    return %orig;
}

// override to customize our added rows in the table
- (id)tableView:(id)view cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // grab the original cell that is defined for this table
    MoreInfoTableViewCell *cell = (MoreInfoTableViewCell *)%orig();
    
    // insert our custom cell if it is the appropriate section and row
    if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSnoozeTimeTableRow) {
        // customize the cell
        cell.textLabel.text = @"Snooze Time";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // format the cell of the text with the snooze time values
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)sJSHours, (long)sJSMinutes, (long)sJSSeconds];
    }
    
    return cell;
}

// override to handle row selection
- (void)tableView:(id)view didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // handle row selection for the custom cell
    if (indexPath.section == kJSSnoozeTimeTableSection && indexPath.row == kJSSnoozeTimeTableRow) {
        // push our custom view controller which will decide the snooze time
        JSSnoozeTimeViewController *snoozeController = [[JSSnoozeTimeViewController alloc] initWithHours:sJSHours
                                                                                                 minutes:sJSMinutes
                                                                                                 seconds:sJSSeconds];
        
        // set the delegate of the custom controller to self so that we can monitor changes to the
        // snooze time
        snoozeController.delegate = self;
        
        // push the controller to our stack
        [self.navigationController pushViewController:snoozeController animated:YES];
    } else {
        %orig;
    }
}

// override to handle when the snooze switch is enabled or disabled
- (void)_snoozeControlChanged:(UISwitch *)changed
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
}

// override to handle when an alarm gets saved
- (void)_doneButtonClicked:(id)arg1
{
    // perform the original save implementation
    %orig;

    // save the snooze time so that it can be read later
    [JSPrefsManager saveSnoozeTimeForAlarmId:self.alarm.alarmId
                                            hours:sJSHours
                                          minutes:sJSMinutes
                                          seconds:sJSSeconds];
}

#pragma mark - JSSnoozeTimeDelegate

// create the new delegate method that tells the editing view controller what snooze time was selected
%new
- (void)alarmDidUpdateWithHours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds
{
    if (hours == 0 && minutes == 0 && seconds == 0) {
        // if all values returned are 0, then reset them to the default
        sJSHours = kJSDefaultHour;
        sJSMinutes = kJSDefaultMinute;
        sJSSeconds = kJSDefaultSecond;
    } else {
        // otherwise save our returned values
        sJSHours = hours;
        sJSMinutes = minutes;
        sJSSeconds = seconds;
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
        NSInteger hours = [[alarmInfo objectForKey:kJSHourKey] integerValue];
        NSInteger minutes = [[alarmInfo objectForKey:kJSMinuteKey] integerValue];
        NSInteger seconds = [[alarmInfo objectForKey:kJSSecondKey] integerValue];
        
        // subtract the default snooze time from these values since they have already been added to
        // the fire date
        hours = hours - kJSDefaultHour;
        minutes = minutes - kJSDefaultMinute;
        seconds = seconds - kJSDefaultSecond;
        
        // convert the entire value into seconds
        NSTimeInterval timeInterval = hours * 60 * 60 + minutes * 60 + seconds;
        
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