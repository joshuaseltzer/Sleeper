//
//  SLUNLocalNotificationClient.x
//  Hook into the UNLocalNotificationClient class to modify the snooze notification on iOS 9.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "SLCompatibilityHelper.h"

%hook UNLocalNotificationClient

// iOS 9: override to insert our custom snooze time if it was defined
- (void)scheduleSnoozeNotification:(UIConcreteLocalNotification *)notification
{
    // attempt to modify the notification with a custom snooze time
    [SLCompatibilityHelper modifySnoozeNotificationForLocalNotification:notification];

    %orig;
}

%end

%ctor {
    // only initialize this file if we are on iOS 9
    if (kSLSystemVersioniOS9) {
        %init();
    }
}