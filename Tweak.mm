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

// static variable to keep an instance of the shared AlarmManager
static AlarmManager *alarmManager;

static ClockManager *clockManager;

// constructor
%ctor
{
    // get the instance of the shared alarm manager
    alarmManager = [AlarmManager sharedManager];
    clockManager = [ClockManager sharedManager];
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

- (void)_fireNotification:(UIConcreteLocalNotification *)notification
{
    %orig(notification);
    /*
    if ([AlarmManager isAlarmNotification:notification]) {
        //[self cancelLocalNotification:notification];
        
        NSString *alarmId = [notification.userInfo objectForKey:kJSAlarmIdKey];
        
        [alarmManager loadAlarms];
        Alarm *alarm = [alarmManager alarmWithId:alarmId];
        [alarm handleAlarmFired:notification];
        [alarmManager handleNotificationFired:notification];
    } else {
        %orig(notification);
    }*/
    
    // grab the alarm Id from the notification
    /*NSString *alarmId = [notification.userInfo objectForKey:kJSAlarmIdKey];
    
    [alarmManager loadAlarms];
    Alarm *alarm = [alarmManager alarmWithId:alarmId];
    [alarm handleAlarmFired:notification];
    [alarmManager handleNotificationFired:notification];
    
    
    // we know that if this alarm is not set to repeat that is will no longer be enabled
    if ([notification remainingRepeatCount] == 0) {
        [JSPrefsManager setAlarmActiveForAlarmId:alarmId
                                          active:NO];
    }*/
    
    %log;
    NSLog(@"*** SELTZER - SBApplication: Notification Fired ***");
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

- (void)setAlarm:(Alarm *)alarm active:(BOOL)active
{
    NSLog(@"*** SELTZER - AlarmManager: SET ALARM *** ");
    
    // perform the original set implementation
    %orig(alarm, active);
    
    // set the alarm's active state to our preferences
    [JSPrefsManager setAlarmActiveForAlarmId:alarm.alarmId
                                      active:active];
}

- (void)updateAlarm:(Alarm *)alarm active:(BOOL)active
{
    NSLog(@"*** SELTZER - AlarmManager: UPDATE ALARM *** ");
    
    // perform the original update implementation
    %orig(alarm, active);
    
    // save the alarm attributes to our preferences
    [JSPrefsManager saveAlarmForAlarmId:alarm.alarmId
                            snoozeHours:sJSSnoozeHours
                          snoozeMinutes:sJSSnoozeMinutes
                          snoozeSeconds:sJSSnoozeSeconds
                            skipEnabled:sJSSkipSwitchOn
                              skipHours:sJSSkipHours
                            alarmActive:active];
}

- (void)addAlarm:(id)arg1 active:(BOOL)arg2
{
    NSLog(@"*** SELTZER - AlarmManager: ADD ALARM *** ");
    %orig(arg1, arg2);
    
    %log;
    
    
}

- (void)handleNotificationFired:(id)arg1
{
    %orig(arg1);
    
    %log;
    NSLog(@"*** SELTZER - AlarmManager: NOTIFICATION FIRED ***");
}

+ (id)copyReadAlarmsFromPreferences
{
    NSLog(@"*** SELTZER - AlarmManager: READ ALARMS FROM PREFS ***");
    //CFPreferencesAppSynchronize(CFSTR("com.apple.mobiletimer"));
    return %orig;
}


%end

%hook Alarm

/*- (void)refreshActiveState
{
    %orig();
    
    NSLog(@"*** REFRESH ACTIVE STATE ***");
    %log;
}*/

- (void)dropNotifications
{
    %orig();
    
    NSLog(@"*** SELTZER - Alarm: NOTIFICATIONS DROPPED ***");
    %log;
}

- (void)cancelNotifications
{
    %orig();
    
    NSLog(@"*** SELTZER - Alarm: NOTIFICATIONS Cancelled ***");
    %log;
}

- (void)scheduleNotifications
{
    %orig();
    
    NSLog(@"*** SELTZER - Alarm: NOTIFICATIONS SCHEDULED ***");
    %log;
}

- (void)prepareNotifications
{
    %orig();
    
    NSLog(@"*** SELTZER - Alarm: NOTIFICATIONS PREPARED ***");
    %log;
}

- (void)handleNotificationSnoozed:(id)arg1 notifyDelegate:(BOOL)arg2
{
    %orig(arg1, arg2);
    
    %log;
    NSLog(@"*** SELTZER - Alarm: NOTIFICATION SNOOZED ***");
}

- (void)handleAlarmFired:(id)arg1
{
    %orig(arg1);
    
    %log;
    NSLog(@"*** SELTZER - Alarm: Alarm FIRED ***");
}

- (void)markModified
{
    %orig;
    
    NSLog(@"*** SELTZER - Alarm: MARKED MODIFIED ***");
}
          
%end

%hook ClockManager

- (void)scheduleLocalNotification:(id)arg1
{
    %orig(arg1);
    
    %log;
    NSLog(@"*** SELTZER - Clock Manager: scheduled ***");
}

- (void)cancelLocalNotification:(id)arg1
{
    %orig(arg1);
    
    %log;
    NSLog(@"*** SELTZER - Clock Manager: canceled ***");
}

%end

%hook AlarmViewController

- (void)activeChangedForAlarm:(id)arg1 active:(_Bool)arg2
{
    %orig(arg1, arg2);
    
    %log;
    NSLog(@"*** SELTZER - AlarmViewController: ACTIVE CHANGED ***");
}

- (void)alarmDidUpdate:(id)arg1
{
    %orig(arg1);
    
    %log;
    NSLog(@"*** SELTZER - AlarmViewController: ALARM DID UPDATE ***");
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
    
    NSLog(@"*** SELTZER - UNLOCKED ***");
    // reload the alarms from the shared alarm manager
    
    //[ClockManager loadUserPreferences];
    //[alarmManager loadAlarms];
    //[alarmManager loadScheduledNotifications];
    //[clockManager refreshScheduledLocalNotificationsCache];
    
    // iterate through the alarms on the device to see if we need to skip any
    AlarmManager *alarmManager2 = [AlarmManager sharedManager];
    [alarmManager2 loadAlarms];
    
    /*NSDateComponents *components= [[NSDateComponents alloc] init];
    [components setHour:3];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *myNewDate=[calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    NSLog(@"NEW DATE: %@", myNewDate.description);
    Alarm *alarmWithDate = [alarmManager2 nextAlarmForDate:myNewDate activeOnly:YES allowRepeating:YES];
    NSLog(@"Alarm: %@", alarmWithDate.description);
    
    NSMutableArray *scheduledLocalNotifications = MSHookIvar<NSMutableArray *>(clockManager, "_scheduledLocalNotifications");
    NSLog(@"%@", scheduledLocalNotifications.description);*/
    for (Alarm *alarm in [alarmManager2 alarms]) {
        // grab the alarm information saved for this given alarm
        NSMutableDictionary *alarmInfo = [JSPrefsManager alarmInfoForAlarmId:alarm.alarmId];
        
        /*[alarm cancelNotifications];
        [alarm prepareNotifications];
        [alarm scheduleNotifications];*/
        [alarm refreshActiveState];
        
        //UILocalNotification *notification = MSHookIvar<UILocalNotification *>(alarm, "_notification");
        NSLog(@"*** SELTZER - Next Fire Date: %@", [alarm nextFireDate].description);
        //[alarm refreshActiveState];
        NSLog(@"*** SELTZER - Alarm %@ is enabled: %d ***", [alarmInfo objectForKey:kJSAlarmIdKey], [alarm isActive]);
        
        /*if ([[alarmInfo objectForKey:kJSAlarmActiveKey] boolValue]) {
            NSLog(@"Alarm Enabled!");
        } else {
            NSLog(@"Alarm disabled!");
        }
        
        NSLog(@"Fire Date: %@", [alarm nextFireDate].description);
        // if the skip is enabled for the given alarm, check to see if it is within the skip time
        if ([[alarmInfo objectForKey:kJSSkipEnabledKey] boolValue]) {
            NSLog(@"Skip Enabled!");
        }*/
    }
    
    // after a slight delay, show
    /*dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        JSSkipAlarmAlertItem *alert = [[%c(JSSkipAlarmAlertItem) alloc] init];
        [(SBAlertItemsController *)[%c(SBAlertItemsController) sharedInstance] activateAlertItem:alert];
    });*/
}

%end