//
//  SLMTAlarmStorage.x
//  Handles the modification of the snooze time for alarms on iOS 12 and iOS 13.
//
//  Created by Joshua Seltzer on 3/20/2019.
//
//

#import "../common/SLCompatibilityHelper.h"

%hook MTAlarmStorage

// invoked when an alarm is snoozed
- (void)snoozeAlarmWithIdentifier:(NSString *)alarmId snoozeDate:(NSDate *)snoozeDate snoozeAction:(int)snoozeAction withCompletion:(id)completionHandler source:(id)source
{
    // on iOS 14, the alarm ID for the "Wake Up" alarm might not be the same
    NSString *sleeperAlarmId = alarmId;
    if (kSLSystemVersioniOS14) {
        sleeperAlarmId = [SLCompatibilityHelper sleeperAlarmIdForAlarmId:alarmId];
    }

    // check to see if a modified snooze date is available for this alarm
    NSDate *modifiedSnoozeDate = [SLCompatibilityHelper modifiedSnoozeDateForAlarmId:sleeperAlarmId withOriginalDate:snoozeDate];
    if (modifiedSnoozeDate) {
        %orig(alarmId, modifiedSnoozeDate, snoozeAction, completionHandler, source);
    } else {
        %orig;
    }
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS14 || kSLSystemVersioniOS13 || kSLSystemVersioniOS12) {
        %init();
    }
}