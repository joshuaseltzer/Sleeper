//
//  Tweak.mm
//  Contains all hooks into Apple's code which handles saving, deleting, and changing the snooze time.
//
//  Created by Joshua Seltzer on 12/15/14.
//
//

#import <UIKit/UIKit.h>
#import "Sleeper/Sleeper/JSPrefsManager.h"
#import "Sleeper/Sleeper/JSLocalizedStrings.h"
#import "AppleInterfaces.h"
#import "JSSkipAlarmAlertItem.h"

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

// helper function that will investigate a notification and alarm to see if it is skippable
static BOOL isNotificationSkippable(UIConcreteLocalNotification *notification, NSString *alarmId)
{
    // grab the skip hours for the alarm
    NSInteger skipHours = [JSPrefsManager skipHoursForAlarmId:alarmId];
    
    // check to see if the skip functionality has been enabled for the alarm
    if (skipHours != NSNotFound && [JSPrefsManager skipEnabledForAlarmId:alarmId]) {
        // create a date components object with the user's selected skip hours to see if we are within
        // the threshold to ask the user to skip the alarm
        NSDateComponents *components= [[NSDateComponents alloc] init];
        [components setHour:skipHours];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // create a date that is the amount of hours ahead of the current date
        NSDate *thresholdDate = [calendar dateByAddingComponents:components
                                                          toDate:[NSDate date]
                                                         options:0];
        
        // get the fire date of the alarm we are checking
        NSDate *alarmFireDate = [notification nextFireDateAfterDate:[NSDate date]
                                                      localTimeZone:[NSTimeZone localTimeZone]];
        
        // compare the dates to see if this notification is skippable
        return [alarmFireDate compare:thresholdDate] == NSOrderedAscending;
    } else {
        // skip is not even enabled, so we know it is not skippable
        return NO;
    }
}

// hook the view controller that allows the editing of alarms
%hook EditAlarmViewController

// override to get values to define the snooze time for this particular alarm
- (void)viewDidLoad
{
    // check if the alarm for this view controller has skip enabled
    sJSSkipSwitchOn = [JSPrefsManager skipEnabledForAlarmId:self.alarm.alarmId];
    
    // grab the skip hours that are saved for this given alarm
    sJSSkipHours = [JSPrefsManager skipHoursForAlarmId:self.alarm.alarmId];
    if (sJSSkipHours == NSNotFound) {
        // set the skip hours to the default if none were found
        sJSSkipHours = kJSDefaultSkipHours;
    }
    
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
    %orig(arg1);
    
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
    // save the updated skip hour static variable
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

// override to make changes when the alarm is set
- (void)setAlarm:(Alarm *)alarm active:(BOOL)active
{
    // perform the original implementation
    %orig(alarm, active);
    
    // if the alarm is no longer active and the skip activation has already been decided for this
    // alarm, disable the skip activation now
    if ([JSPrefsManager skipActivatedStatusForAlarmId:alarm.alarmId] != kJSSkipActivatedStatusUnknown) {
        // save the alarm's skip activation state to our preferences
        [JSPrefsManager setSkipActivatedStatusForAlarmId:alarm.alarmId
                                     skipActivatedStatus:kJSSkipActivatedStatusUnknown];
    }
}

%end

// hook into the lock screen view controller to check to see if we need to prompt the user to skip
// an alarm
%hook SBLockScreenViewController

// override to display a pop up allowing the user to skip an alarm
- (void)finishUIUnlockFromSource:(int)source
{
    // perform the original implementation
    %orig(source);
    
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = [%c(SBClockDataProvider) sharedInstance];
    
    // grab the next alarm for today
    UIConcreteLocalNotification *nextAlarmNotification = MSHookIvar<UIConcreteLocalNotification *>(clockDataProvider, "_nextAlarmForToday");
    NSString *alarmId = nil;
    
    // check to see if a valid alarm was returned
    if (nextAlarmNotification) {
        // grab the alarm's Id
        alarmId = [clockDataProvider _alarmIDFromNotification:nextAlarmNotification];
    }
    
    // if there was no alarm for today or that alarm is not skippable, then check tomorrow
    if (!nextAlarmNotification || (alarmId && !isNotificationSkippable(nextAlarmNotification, alarmId))) {
        // grab the first alarm for tomorrow
        nextAlarmNotification = MSHookIvar<UIConcreteLocalNotification *>(clockDataProvider, "_firstAlarmForTomorrow");
        
        // check to see if a valid alarm was returned
        if (nextAlarmNotification) {
            // grab the alarm's Id
            alarmId = [clockDataProvider _alarmIDFromNotification:nextAlarmNotification];
            
            // check to see if this alarm is skippable
            if (!isNotificationSkippable(nextAlarmNotification, alarmId)) {
                nextAlarmNotification = nil;
            }
        }
    }
    
    // if we found a valid alarm, check to see if we should ask to skip it
    if (nextAlarmNotification && alarmId) {
        // if skip has not already been activated for this alarm, then present an alert to ask the
        // user to skip it
        if ([JSPrefsManager skipActivatedStatusForAlarmId:alarmId] == kJSSkipActivatedStatusUnknown) {
            // grab the alarm that we are going to ask to skip from the shared alarm manager
            AlarmManager *alarmManager = [AlarmManager sharedManager];
            [alarmManager loadAlarms];
            Alarm *alarm = [alarmManager alarmWithId:alarmId];
            
            // after a slight delay, show an alert that will ask the user to skip the alarm
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                // get the fire date of the alarm we are going to display
                NSDate *alarmFireDate = [nextAlarmNotification nextFireDateAfterDate:[NSDate date]
                                                                       localTimeZone:[NSTimeZone localTimeZone]];
                
                // create and display the custom alert item
                JSSkipAlarmAlertItem *alert = [[%c(JSSkipAlarmAlertItem) alloc] initWithAlarm:alarm
                                                                                 nextFireDate:alarmFireDate];
                [(SBAlertItemsController *)[%c(SBAlertItemsController) sharedInstance] activateAlertItem:alert];
            });
        }
    }
}

%end

// hook into the clock data provider to perform the skipping of an alarm
%hook SBClockDataProvider

// invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForLocalNotification:(UIConcreteLocalNotification *)notification
{
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = [%c(SBClockDataProvider) sharedInstance];
    
    // check to see if this notification is an alarm notification
    if ([clockDataProvider _isAlarmNotification:notification]) {
        // get the alarm Id from the notification
        NSString *alarmId = [clockDataProvider _alarmIDFromNotification:notification];
        
        // check to see if skip is activated for this alarm
        if ([JSPrefsManager skipActivatedStatusForAlarmId:alarmId] == kJSSkipActivatedStatusActivated) {
            // grab the alarm that we are going to ask to skip from the shared alarm manager
            AlarmManager *alarmManager = [AlarmManager sharedManager];
            [alarmManager loadAlarms];
            Alarm *alarm = [alarmManager alarmWithId:alarmId];
            
            // simulate the alarm going off
            [alarm handleAlarmFired:notification];
            [alarmManager handleNotificationFired:notification];
            
            // save the alarm's skip activation state to unknown for this alarm
            [JSPrefsManager setSkipActivatedStatusForAlarmId:alarm.alarmId
                                         skipActivatedStatus:kJSSkipActivatedStatusUnknown];
        } else {
            // if we did not activate skip for this alarm, perform the original implementation
            %orig(notification);
        }
    } else {
        // if it is not an alarm notification, perform the original implementation
        %orig(notification);
    }
}

%end