//
//  Tweak.mm
//  Contains all hooks into Apple's code which handles saving, deleting, and changing the snooze time.
//
//  Created by Joshua Seltzer on 12/15/14.
//
//

#import <UIKit/UIKit.h>
#import "Sleeper/Sleeper/JSSnoozeTimeViewController.h"
#import "Sleeper/Sleeper/JSSkipTimeViewController.h"
#import "Sleeper/Sleeper/JSPrefsManager.h"
#import "Sleeper/Sleeper/JSLocalizedStrings.h"
#import "AppleInterfaces.h"

// define an enum to reference the sections of the table view
typedef enum JSEditAlarmViewSection : NSUInteger {
    kJSEditAlarmViewSectionAttribute,
    kJSEditAlarmViewSectionDelete
} JSEditAlarmViewSection;

// define an enum to reference the rows in the attributes section of the table view
typedef enum JSEditAlarmViewAttributeSectionRow : NSUInteger {
    kJSEditAlarmViewAttributeSectionRowRepeat,
    kJSEditAlarmViewAttributeSectionRowLabel,
    kJSEditAlarmViewAttributeSectionRowSound,
    kJSEditAlarmViewAttributeSectionRowSnoozeToggle,
    kJSEditAlarmViewAttributeSectionRowSnoozeTime,
    kJSEditAlarmViewAttributeSectionRowSkipToggle,
    kJSEditAlarmViewAttributeSectionRowSkipTime
} JSEditAlarmViewAttributeSectionRow;

// static variable that is set when the skip switch is enabled
static BOOL sJSSkipSwitchOn;

// Static variables that define the alarm attributes of the current alarm.  Only one alarm can be
// edited at a time, so we can get away with just single variables here that get overwritten as
// alarms are edited and changed
static NSInteger sJSSnoozeHours;
static NSInteger sJSSnoozeMinutes;
static NSInteger sJSSnoozeSeconds;
static NSInteger sJSSkipHours;

// hook the view controller that allows the editing of alarms
%hook EditAlarmViewController

// override to get values to define the snooze time for this particular alarm
- (void)viewDidLoad
{
    // check if the alarm for this view controller has skip enabled
    sJSSkipSwitchOn = [JSPrefsManager skipEnabledForAlarmId:self.alarm.alarmId];
    
    // grab the skip hours that are saved for this given alarm
    sJSSkipHours = [JSPrefsManager skipHoursForAlarmId:self.alarm.alarmId];
    
    // get the alarm prefs for the given alarm Id that this view is responsible for
    NSMutableDictionary *alarmInfo = [JSPrefsManager alarmInfoForAlarmId:self.alarm.alarmId];
    if (alarmInfo) {
        // grab the attributes from the alarm info if we had some saved
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
    if (section == kJSEditAlarmViewSectionAttribute) {
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
    if (indexPath.section == kJSEditAlarmViewSectionAttribute &&
        indexPath.row != kJSEditAlarmViewAttributeSectionRowSnoozeToggle) {
        cell.accessoryView = nil;
    }
    
    // insert our custom cell if it is the appropriate section and row
    if (indexPath.section == kJSEditAlarmViewSectionAttribute &&
        indexPath.row == kJSEditAlarmViewAttributeSectionRowSnoozeTime) {
        // customize the cell
        cell.textLabel.text = LZ_SNOOZE_TIME;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // format the cell of the text with the snooze time values
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)sJSSnoozeHours,
                                     (long)sJSSnoozeMinutes, (long)sJSSnoozeSeconds];
    } else if (indexPath.section == kJSEditAlarmViewSectionAttribute &&
               indexPath.row == kJSEditAlarmViewAttributeSectionRowSkipToggle) {
        // customize the cell
        cell.textLabel.text = LZ_SKIP;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.text = nil;
        
        // create a switch to allow the user to toggle on and off the skip functionality
        UISwitch *skipControl = [[UISwitch alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
        [skipControl addTarget:self
                        action:@selector(skipControlChanged:)
              forControlEvents:UIControlEventValueChanged];
        skipControl.on = sJSSkipSwitchOn;
        
        // set the switch to the custom view in the cell
        cell.accessoryView = skipControl;
    } else if (indexPath.section == kJSEditAlarmViewSectionAttribute &&
               indexPath.row == kJSEditAlarmViewAttributeSectionRowSkipTime) {
        // customize the cell
        cell.textLabel.text = LZ_ASK_TO_SKIP;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Format the cell with the skip hours.  Show "hour" or "hours" depending on how many we have
        NSString *hourString = nil;
        if (sJSSkipHours == 1) {
            hourString = LZ_HOUR;
        } else {
            hourString = LZ_HOURS;
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)sJSSkipHours, hourString];
    }
    
    return cell;
}

// override to handle row selection
- (void)tableView:(id)view didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // handle row selection for the custom cells
    if (indexPath.section == kJSEditAlarmViewSectionAttribute &&
        indexPath.row == kJSEditAlarmViewAttributeSectionRowSnoozeTime) {
        // create a custom view controller which will decide the snooze time
        JSSnoozeTimeViewController *snoozeController = [[JSSnoozeTimeViewController alloc] initWithHours:sJSSnoozeHours
                                                                                                 minutes:sJSSnoozeMinutes
                                                                                                 seconds:sJSSnoozeSeconds];
        
        // set the delegate of the custom controller to self so that we can monitor changes to the
        // snooze time
        snoozeController.delegate = self;
        
        // push the controller to our stack
        [self.navigationController pushViewController:snoozeController animated:YES];
    } else if (indexPath.section == kJSEditAlarmViewSectionAttribute &&
               indexPath.row == kJSEditAlarmViewAttributeSectionRowSkipTime) {
        // create a custom view controller which will decide the skip time
        JSSkipTimeViewController *skipController = [[JSSkipTimeViewController alloc] initWithHours:sJSSkipHours];
        
        // set the delegate of the custom controller to self so that we can monitor changes to the
        // skip time
        skipController.delegate = self;
        
        // push the controller to our stack
        [self.navigationController pushViewController:skipController animated:YES];
    } else if (indexPath.section == kJSEditAlarmViewSectionAttribute &&
               indexPath.row != kJSEditAlarmViewAttributeSectionRowSkipToggle) {
        // perform the original implementation for row selections
        %orig;
    }
}

// override to handle when an alarm gets saved
- (void)_doneButtonClicked:(id)arg1
{
    // perform the original save implementation
    %orig;

    // save the alarm attributes to our preferences
    [JSPrefsManager saveAlarmForAlarmId:self.alarm.alarmId
                            snoozeHours:sJSSnoozeHours
                          snoozeMinutes:sJSSnoozeMinutes
                          snoozeSeconds:sJSSnoozeSeconds
                            skipEnabled:sJSSkipSwitchOn
                              skipHours:sJSSkipHours];
}

// handle when the skip switch is changed
%new
- (void)skipControlChanged:(UISwitch *)skipSwitch
{
    // update the static variable with the change of the skip control
    sJSSkipSwitchOn = skipSwitch.on;
}

#pragma mark - JSSnoozeTimeDelegate

// create the new delegate method that tells the editing view controller what snooze time was selected
%new
- (void)alarmDidUpdateWithSnoozeHours:(NSInteger)snoozeHours snoozeMinutes:(NSInteger)snoozeMinutes snoozeSeconds:(NSInteger)snoozeSeconds
{
    if (snoozeHours == 0 && snoozeMinutes == 0 && snoozeSeconds == 0) {
        // if all values returned are 0, then reset them to the default
        sJSSnoozeHours = kJSDefaultSnoozeHour;
        sJSSnoozeMinutes = kJSDefaultSnoozeMinute;
        sJSSnoozeSeconds = kJSDefaultSnoozeSecond;
    } else {
        // otherwise save our returned values
        sJSSnoozeHours = snoozeHours;
        sJSSnoozeMinutes = snoozeMinutes;
        sJSSnoozeSeconds = snoozeSeconds;
    }
}

#pragma mark - JSSkipTimeDelegate

// create the new delegate method that tells the editing view controller what skip time was selected
%new
- (void)alarmDidUpdateWithSkipHours:(NSInteger)skipHours
{
    // save the skip hour static variable
    sJSSkipHours = skipHours;
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
    NSMutableDictionary *alarmInfo = [JSPrefsManager alarmInfoForAlarmId:alarmId];
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

    // delete the attributes for this given alarm
    [JSPrefsManager deleteAlarmForAlarmId:alarm.alarmId];
}

%end

// hook into the lock screen view controller to check to see if we need to prompt the user to skip
// an alarm
%hook SBLockScreenViewController

// override to display a pop up allowing the user to skip an alarm
- (void)finishUIUnlockFromSource:(int)source
{
    %orig(source);
    
    /*Class SBAlertItem64 = %c(SBAlertItem);
    SBAlertItem *alert = [[SBAlertItem64 alloc] init];
    
    UIAlertView *alertView = MSHookIvar<UIAlertView *>(alert, "_alertSheet");
    alertView = [[UIAlertView alloc] initWithTitle:@"Really reset?" message:@"Do you really want to reset this game?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [SBAlertItem64 activateAlertItem:alert];*/
}

%end

/*%subclass JSSkipAlarmAlertItem : SBAlertItem

%new
- (id)initWithAlarm:(Alarm *)alarm
{
    // perform the original initialization method
    self = [self init];
    
    if (self) {
        
    }
    
    return self;
}

// override to configure the alert item
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode
{
    // perform the original implementation
    %orig;
    
    self.alertSheet.title = @"Test";
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)index
{
    
}

%end*/