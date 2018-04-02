//
//  SLSBClockDataProvider.x
//  Hook into the SBClockDataProvider class to potentially skip an alarm notification.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "SLCompatibilityHelper.h"
#import "SLPrefsManager.h"
#import "SLAppleSharedInterfaces.h"

%group iOS10iOS11

%hook SBClockDataProvider

// invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForNotification:(UNNotification *)notification
{
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = [%c(SBClockDataProvider) sharedInstance];
    
    // check to see if this notification is an alarm notification
    if ([clockDataProvider _isAlarmNotification:notification]) {
        // get the alarm Id from the notification
        NSString *alarmId = [clockDataProvider _alarmIDFromNotificationRequest:notification.request];
        
        // check to see if skip is activated for this alarm
        if ([SLPrefsManager skipActivatedStatusForAlarmId:alarmId] == kSLSkipActivatedStatusActivated) {
            // save the alarm's skip activation state to unknown for this alarm
            [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                         skipActivatedStatus:kSLSkipActivatedStatusUnknown];
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

%end // %group iOS10iOS11

%group iOS8iOS9

%hook SBClockDataProvider

// iOS 8 / iOS 9: invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForLocalNotification:(UIConcreteLocalNotification *)notification
{
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = [%c(SBClockDataProvider) sharedInstance];
    
    // check to see if this notification is an alarm notification
    if ([clockDataProvider _isAlarmNotification:notification]) {
        // get the alarm Id from the notification
        NSString *alarmId = [clockDataProvider _alarmIDFromNotification:notification];
        
        // check to see if skip is activated for this alarm
        if ([SLPrefsManager skipActivatedStatusForAlarmId:alarmId] == kSLSkipActivatedStatusActivated) {
            // grab the alarm that we are going to ask to skip from the shared alarm manager
            AlarmManager *alarmManager = [AlarmManager sharedManager];
            [alarmManager loadAlarms];
            Alarm *alarm = [alarmManager alarmWithId:alarmId];
            
            // simulate the alarm going off
            [alarm handleAlarmFired:notification];
            [alarmManager handleNotificationFired:notification];
            
            // save the alarm's skip activation state to unknown for this alarm
            [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                         skipActivatedStatus:kSLSkipActivatedStatusUnknown];
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

%end // %group iOS8iOS9

%ctor {
    // check which version we are running to determine which group to initialize
    if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11) {
        %init(iOS10iOS11);
    } else {
        %init(iOS8iOS9);
    }
}