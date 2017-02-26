//
//  SBLockScreenManager.x
//  Hook into the SBLockScreenManager class to potentially show an alert after unlocking the device.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "SLCompatibilityHelper.h"
#import "SLAppleSharedInterfaces.h"
#import "SLSkipAlarmAlertItem.h"

%hook SBLockScreenManager

// iOS10: override to display a pop up allowing the user to skip an alarm
- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options
{
    %orig;

    // create the block that will be used to inspect the notification requests from the clock notification manager
    void (^clockNotificationManagerNotificationRequests) (NSArray *) = ^(NSArray *notificationRequests) {
        // only continue if valid notification requests were returned
        if (notificationRequests.count > 0) {
            /*SBClockDataProvider *clockDataProvider = (SBClockDataProvider *)[objc_getClass("SBClockDataProvider") sharedInstance];

            if ([clockDataProvider _isWakeNotificationRequest:notificationRequests[0]]) {
                // create and display the custom alert item
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    AlarmManager *alarmManager = [AlarmManager sharedManager];
                    [alarmManager loadAlarms];
                    SLSkipAlarmAlertItem *alert = [[%c(SLSkipAlarmAlertItem) alloc] initWithString:[NSString stringWithFormat:@"%@\n\n%@", alarmManager.sleepAlarm.alarmID, notificationRequests]];
                    [(SBAlertItemsController *)[%c(SBAlertItemsController) sharedInstance] activateAlertItem:alert animated:YES];
                });
            }*/
            

            // attempt to get the next skippable alarm notification request from the notification requests returned
            /*UNNotificationRequest *nextAlarmNotificationRequest = [SLCompatibilityHelper nextSkippableAlarmNotificationRequestForNotificationRequests:notificationRequests];

            // if we found a valid alarm, check to see if we should ask to skip it
            if (nextAlarmNotificationRequest != nil) {
                // grab the shared instance of the clock data provider
                SBClockDataProvider *clockDataProvider = [%c(SBClockDataProvider) sharedInstance];

                // grab the alarm Id for this notification request
                NSString *alarmId = [clockDataProvider _alarmIDFromNotificationRequest:nextAlarmNotificationRequest];
                
                // grab the shared instance of the alarm manager, load the alarms, and get the alarm object
                // that is associated with this notification request
                AlarmManager *alarmManager = [AlarmManager sharedManager];
                [alarmManager loadAlarms];
                Alarm *alarm = [alarmManager alarmWithId:alarmId];
                
                // after a slight delay, show an alert that will ask the user to skip the alarm on the main thread
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    // get the fire date of the alarm we are going to display
                    NSDate *nextTriggerDate = [((UNLegacyNotificationTrigger *)nextAlarmNotificationRequest.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                                                             withRequestedDate:nil
                                                                                                                               defaultTimeZone:[NSTimeZone localTimeZone]];
                    
                    // create and display the custom alert item
                    SLSkipAlarmAlertItem *alert = [[%c(SLSkipAlarmAlertItem) alloc] initWithAlarm:alarm
                                                                                     nextFireDate:nextTriggerDate];
                    [(SBAlertItemsController *)[%c(SBAlertItemsController) sharedInstance] activateAlertItem:alert animated:YES];
                });
            }*/
        }
    };

    // get the clock notification manager and get the notification requests
    SBClockNotificationManager *clockNotificationManager = [%c(SBClockNotificationManager) sharedInstance];
    [clockNotificationManager getPendingNotificationRequestsWithCompletionHandler:clockNotificationManagerNotificationRequests];
}

%end

%ctor {
    // only initialize this file if we are on iOS10
    if (kSLSystemVersioniOS10) {
        %init();
    }
}