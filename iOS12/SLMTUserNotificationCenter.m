//
//  SLMTUserNotificationCenter.x
//  Handles the posting of notifications for a scheduled alarm (iOS 12).
//
//  Created by Joshua Seltzer on 3/20/2019.
//
//

#import "../SLCompatibilityHelper.h"

%hook MTUserNotificationCenter

// invoked when the given scheduled alarm is fired
- (void)postNotificationForScheduledAlarm:(MTAlarm *)alarm completionBlock:(id)completionBlock
{
    %log;
    %orig;
}

%end

%ctor {
    // only initialize this file if we are on iOS 12
    if (kSLSystemVersioniOS12) {
        %init();
    }
}