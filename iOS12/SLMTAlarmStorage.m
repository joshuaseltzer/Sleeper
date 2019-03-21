//
//  SLMTAlarmStorage.x
//  Handles the modification of the snooze time for alarms on iOS 12.
//
//  Created by Joshua Seltzer on 3/20/2019.
//
//

#import "../SLCompatibilityHelper.h"

%hook MTAlarmStorage

// invoked when an alarm is snoozed
- (void)snoozeAlarmWithIdentifier:(NSString *)alarmId snoozeDate:(NSDate *)snoozeDate snoozeAction:(int)snoozeAction withCompletion:(id)completionHandler source:(id)source
{
    // check to see if a modified snooze date is available for this alarm
    NSDate *modifiedSnoozeDate = [SLCompatibilityHelper modifiedSnoozeDateForAlarmId:alarmId withOriginalDate:snoozeDate];
    if (modifiedSnoozeDate) {
        %orig(alarmId, modifiedSnoozeDate, snoozeAction, completionHandler, source);
    } else {
        %orig;
    }
}

%end

%ctor {
    // only initialize this file if we are on iOS 12
    if (kSLSystemVersioniOS12) {
        %init();
    }
}