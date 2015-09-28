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
static NSString *sJSCurrentAlarmId;
static NSInteger sJSSnoozeHours;
static NSInteger sJSSnoozeMinutes;
static NSInteger sJSSnoozeSeconds;
static NSInteger sJSSkipHours;
static NSInteger sJSSkipMinutes;
static NSInteger sJSSkipSeconds;

// helper function that will investigate an alarm notification and alarm Id to see if it is skippable
static BOOL isAlarmNotificationSkippable(UIConcreteLocalNotification *notification, NSString *alarmId)
{
    // grab the attributes for the alarm
    NSMutableDictionary *alarmInfo = [JSPrefsManager alarmInfoForAlarmId:alarmId];
    
    // check to see if the skip functionality has been enabled for the alarm
    if (alarmInfo && [JSPrefsManager skipEnabledForAlarmId:alarmId] &&
        [JSPrefsManager skipActivatedStatusForAlarmId:alarmId] == kJSSkipActivatedStatusUnknown) {
        // grab the skip attributes for the alarm
        NSInteger skipHours = [[alarmInfo objectForKey:kJSSkipHourKey] integerValue];
        NSInteger skipMinutes = [[alarmInfo objectForKey:kJSSkipMinuteKey] integerValue];
        NSInteger skipSeconds = [[alarmInfo objectForKey:kJSSkipSecondKey] integerValue];
        
        // create a date components object with the user's selected skip time to see if we are within
        // the threshold to ask the user to skip the alarm
        NSDateComponents *components= [[NSDateComponents alloc] init];
        [components setHour:skipHours];
        [components setMinute:skipMinutes];
        [components setSecond:skipSeconds];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // create a date that is the amount of time ahead of the current date
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

// Helper function that will return the next skippable alarm notification from the given clock data
// provider.  If no notification is found, return nil.
static UIConcreteLocalNotification *nextSkippableAlarmNotification(SBClockDataProvider *clockDataProvider)
{
    // create a comparator block to sort the array of notifications
    NSComparisonResult (^notificationComparator) (UIConcreteLocalNotification *, UIConcreteLocalNotification *) =
    ^(UIConcreteLocalNotification *lhs, UIConcreteLocalNotification *rhs) {
        // get the next fire date of the left hand side notification
        NSDate *lhsNextFireDate = [lhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        // get the next fire date of the right hand side notification
        NSDate *rhsNextFireDate = [rhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        return [lhsNextFireDate compare:rhsNextFireDate];
    };
    
    // take the scheduled notifications from the clock data provider and sort them by earliest date
    NSArray *sortedNotifications = [[clockDataProvider _scheduledNotifications] sortedArrayUsingComparator:notificationComparator];
    
    // iterate through all of the notifications that are scheduled
    for (UIConcreteLocalNotification *notification in sortedNotifications) {
        // only continue checking if the given notification is an alarm notification and did not
        // originate from a snooze action
        if ([clockDataProvider _isAlarmNotification:notification] && ![Alarm isSnoozeNotification:notification]) {
            // grab the alarm Id from the notification
            NSString *alarmId = [clockDataProvider _alarmIDFromNotification:notification];
            
            // check to see if this notification is skippable
            if (isAlarmNotificationSkippable(notification, alarmId)) {
                // since the array is sorted we know that this is the earliest skippable notification
                return notification;
            }
        }
    }
    
    // if no skippable notification was found, return nil
    return nil;
}

// helper function to save our static variables with the values from the preference manager
static void getSavedAlarmPreferences(Alarm *alarm)
{
    // save the current alarm Id so we know which alarm we just changed
    sJSCurrentAlarmId = alarm.alarmId;
    
    // check if the alarm has skip enabled
    sJSSkipSwitchOn = [JSPrefsManager skipEnabledForAlarmId:sJSCurrentAlarmId];
    
    // get the alarm prefs for the given alarm Id
    NSMutableDictionary *alarmInfo = [JSPrefsManager alarmInfoForAlarmId:sJSCurrentAlarmId];
    if (alarmInfo) {
        // grab the attributes from the alarm info if we had some saved
        sJSSnoozeHours = [[alarmInfo objectForKey:kJSSnoozeHourKey] integerValue];
        sJSSnoozeMinutes = [[alarmInfo objectForKey:kJSSnoozeMinuteKey] integerValue];
        sJSSnoozeSeconds = [[alarmInfo objectForKey:kJSSnoozeSecondKey] integerValue];
        sJSSkipHours = [[alarmInfo objectForKey:kJSSkipHourKey] integerValue];
        sJSSkipMinutes = [[alarmInfo objectForKey:kJSSkipMinuteKey] integerValue];
        sJSSkipSeconds = [[alarmInfo objectForKey:kJSSkipSecondKey] integerValue];
    } else {
        // if info was not previously saved for this alarm, then use the default values
        sJSSnoozeHours = kJSDefaultSnoozeHour;
        sJSSnoozeMinutes = kJSDefaultSnoozeMinute;
        sJSSnoozeSeconds = kJSDefaultSnoozeSecond;
        sJSSkipHours = kJSDefaultSkipHour;
        sJSSkipMinutes = kJSDefaultSkipMinute;
        sJSSkipSeconds = kJSDefaultSkipSecond;
    }
}

// hook the view controller that allows the editing of alarms
%hook EditAlarmViewController

// override to make sure that we have the correct properties for the alarm being shown in the controller
- (void)viewWillAppear:(BOOL)animated
{
    // grab the saved preferences for the given alarm if we need to
    if (!sJSCurrentAlarmId || ![self.alarm.alarmId isEqualToString:sJSCurrentAlarmId]) {
        getSavedAlarmPreferences(self.alarm);
    }
    
    // perform the original implementation
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
    MoreInfoTableViewCell *cell = (MoreInfoTableViewCell *)%orig;
    
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
        cell.textLabel.text = LZ_SKIP_TIME;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // format the cell of the text with the skip time values
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)sJSSkipHours,
                                     (long)sJSSkipMinutes, (long)sJSSkipSeconds];
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
        JSSkipTimeViewController *skipController = [[JSSkipTimeViewController alloc] initWithHours:sJSSkipHours
                                                                                           minutes:sJSSkipMinutes
                                                                                           seconds:sJSSkipSeconds];
        
        // set the delegate of the custom controller to self so that we can monitor changes to the
        // skip time
        skipController.delegate = self;
        
        // push the controller to our stack
        [self.navigationController pushViewController:skipController animated:YES];
    } else if ((indexPath.section == kJSEditAlarmViewSectionAttribute &&
               indexPath.row != kJSEditAlarmViewAttributeSectionRowSkipToggle) ||
               indexPath.section == kJSEditAlarmViewSectionDelete) {
        // perform the original implementation for row selections
        %orig;
    }
}

// handle when the skip switch is changed
%new
- (void)skipControlChanged:(UISwitch *)skipSwitch
{
    // update the static variable with the change of the skip control
    sJSSkipSwitchOn = skipSwitch.on;
}

#pragma mark - JSPickerSelectionDelegate

// create the new delegate method that tells the editing view controller what picker time was selected
%new
- (void)pickerTableViewController:(JSPickerTableViewController *)pickerTableViewController didUpdateWithHours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds
{
    // check to see if we are updating the snooze time or the skip time
    if ([pickerTableViewController isMemberOfClass:[JSSnoozeTimeViewController class]]) {
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
    } else if ([pickerTableViewController isMemberOfClass:[JSSkipTimeViewController class]]) {
        if (hours == 0 && minutes == 0 && seconds == 0) {
            // if all values returned are 0, then reset them to the default
            sJSSkipHours = kJSDefaultSkipHour;
            sJSSkipMinutes = kJSDefaultSkipMinute;
            sJSSkipSeconds = kJSDefaultSkipSecond;
        } else {
            // otherwise save our returned values
            sJSSkipHours = hours;
            sJSSkipMinutes = minutes;
            sJSSkipSeconds = seconds;
        }
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
    %orig(notification);
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
    %orig;
    
    // if the alarm is no longer active and the skip activation has already been decided for this
    // alarm, disable the skip activation now
    if ([JSPrefsManager skipActivatedStatusForAlarmId:alarm.alarmId] != kJSSkipActivatedStatusUnknown) {
        // save the alarm's skip activation state to our preferences
        [JSPrefsManager setSkipActivatedStatusForAlarmId:alarm.alarmId
                                     skipActivatedStatus:kJSSkipActivatedStatusUnknown];
    }
}

// override to save the properties for the given alarm
- (void)updateAlarm:(Alarm *)alarm active:(BOOL)active
{
    // perform the original implementation
    %orig;
    
    // grab the saved preferences for the given alarm if we need to
    if (!sJSCurrentAlarmId || ![alarm.alarmId isEqualToString:sJSCurrentAlarmId]) {
        getSavedAlarmPreferences(alarm);
    }
    
    // save the alarm attributes to our preferences
    [JSPrefsManager saveAlarmForAlarmId:alarm.alarmId
                            snoozeHours:sJSSnoozeHours
                          snoozeMinutes:sJSSnoozeMinutes
                          snoozeSeconds:sJSSnoozeSeconds
                            skipEnabled:sJSSkipSwitchOn
                              skipHours:sJSSkipHours
                            skipMinutes:sJSSkipMinutes
                            skipSeconds:sJSSkipSeconds];
}

%end

// hook into the lock screen view controller to check to see if we need to prompt the user to skip
// an alarm
%hook SBLockScreenViewController

// override to display a pop up allowing the user to skip an alarm
- (void)finishUIUnlockFromSource:(int)source
{
    // perform the original implementation
    %orig;
    
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = [%c(SBClockDataProvider) sharedInstance];
    
    // attempt to get the next skippable alarm notification from the data provider
    UIConcreteLocalNotification *nextAlarmNotification = nextSkippableAlarmNotification(clockDataProvider);
    
    // if we found a valid alarm, check to see if we should ask to skip it
    if (nextAlarmNotification) {
        // grab the alarm Id for this notification
        NSString *alarmId = [clockDataProvider _alarmIDFromNotification:nextAlarmNotification];
        
        // grab the shared instance of the alarm manager and load the alarms
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
            %orig;
        }
    } else {
        // if it is not an alarm notification, perform the original implementation
        %orig;
    }
}

%end