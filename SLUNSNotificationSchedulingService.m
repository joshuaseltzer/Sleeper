//
//  SLUNSNotificationSchedulingService.x
//  Hook into the UNSNotificationSchedulingService class to modify the snooze notification on iOS 10 and iOS 11.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "SLCompatibilityHelper.h"

%hook UNSNotificationSchedulingService

// iOS 10 / iOS 11: function that adds new notification records to the scheduling service
- (void)addPendingNotificationRecords:(NSArray *)notificationRecords forBundleIdentifier:(NSString *)bundleId withCompletionHandler:(id)completionHandler
{
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

%end

%ctor {
    // only initialize this file if we are on iOS 10 or iOS 11
    if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11) {
        %init();
    }
}