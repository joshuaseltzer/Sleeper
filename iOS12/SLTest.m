//
//  .x
//  
//
//  Created by Joshua Seltzer on 3/16/2019.
//
//

#import "../SLCompatibilityHelper.h"

// MTAlarmScheduler, mobiletimerd??
%hook MTAgentNotificationManager

- (void)_handleNotification:(id)arg1
{
    NSLog(@"**** SLEEPER ****");
    %log;
    %orig;
}

%end

/*%hook UNSNotificationSchedulingService

// iOS 10 / iOS 11: function that adds new notification records to the scheduling service
- (void)addPendingNotificationRecords:(NSArray *)notificationRecords forBundleIdentifier:(NSString *)bundleId withCompletionHandler:(id)completionHandler
{
    %log;
    // check to see if the notification is for the timer application
    if ([bundleId isEqualToString:@"com.apple.mobiletimer"]) {
        // iterate through the notification records
        for (UNSNotificationRecord *notification in notificationRecords) {
            // check to see if the notification is a snooze notification
            if ([notification isFromSnooze]) {
                // modify the snooze notifications with the updated snooze times
                [SLCompatibilityHelper modifySnoozeNotificationForNotificationRecord:notification];
            }
        }
    }

    %orig;
}

%end*/

%ctor {
    // only initialize this file if we are on iOS 12
    if (kSLSystemVersioniOS12) {
        %init();
    }
}