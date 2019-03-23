//
//  SLSBClockDataProvider.x
//  Hook into the SBClockDataProvider class to potentially skip an alarm notification.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "../SLCompatibilityHelper.h"
#import "../SLPrefsManager.h"
#import "../SLAppleSharedInterfaces.h"

%group iOS10iOS11

%hook SBClockDataProvider

// iOS 10 / iOS 11: invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForNotification:(UNNotification *)notification
{
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = [objc_getClass("SBClockDataProvider") sharedInstance];
    
    // check to see if this notification is an alarm notification
    if ([clockDataProvider _isAlarmNotification:notification]) {
        // get the alarm Id from the notification
        NSString *alarmId = [clockDataProvider _alarmIDFromNotificationRequest:notification.request];

        // get the sleeper alarm preferences for this alarm
        SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
        if (alarmPrefs) {
            // only activate the actual alarm if we should not be skipping this alarm
            if (![alarmPrefs shouldSkip]) {
                %orig;
            }

            // save the alarm's skip activation state to unknown for this alarm
            [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                         skipActivatedStatus:kSLSkipActivatedStatusUnknown];
        } else {
            %orig;
        }
    } else {
        %orig;
    }
}

%end

%end // %group iOS10iOS11

%group iOS8iOS9

%hook SBClockDataProvider

// iOS 8 / iOS 9: invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForLocalNotification:(UIConcreteLocalNotification *)notification
{
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = [objc_getClass("SBClockDataProvider") sharedInstance];
    
    // check to see if this notification is an alarm notification
    if ([clockDataProvider _isAlarmNotification:notification]) {
        // get the alarm Id from the notification
        NSString *alarmId = [clockDataProvider _alarmIDFromNotification:notification];

        // get the sleeper alarm preferences for this alarm
        SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
        if (alarmPrefs) {
            // check to see if this alarm should be skipped
            if ([alarmPrefs shouldSkip]) {
                // grab the alarm that we are going to ask to skip from the shared alarm manager
                AlarmManager *alarmManager = (AlarmManager *)[objc_getClass("AlarmManager") sharedManager];
                [alarmManager loadAlarms];
                Alarm *alarm = [alarmManager alarmWithId:alarmId];
                
                // simulate the alarm going off
                [alarm handleAlarmFired:notification];
                [alarmManager handleNotificationFired:notification];
            } else {
                %orig;
            }

            // save the alarm's skip activation state to unknown for this alarm
            [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                         skipActivatedStatus:kSLSkipActivatedStatusUnknown];
        } else {
            %orig;
        }
    } else {
        %orig;
    }
}

%end

%end // %group iOS8iOS9

%ctor {
    // check which version we are running to determine which group to initialize
    if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11) {
        %init(iOS10iOS11);
    } else if (kSLSystemVersioniOS8 || kSLSystemVersioniOS9) {
        %init(iOS8iOS9);
    }
}