//
//  SLMTAlarmStorage.x
//  Handles the modification of the snooze time for alarms on iOS 12 and iOS 13.
//
//  Created by Joshua Seltzer on 3/20/2019.
//
//

#import "../common/SLCompatibilityHelper.h"

@interface MTAlarmStorage : NSObject

// returns the currently active Sleep (i.e. "Wake Up") alarm (iOS 14)
- (MTAlarm *)activeSleepAlarm;

@end

%hook MTAlarmStorage

// invoked when an alarm is snoozed
- (void)snoozeAlarmWithIdentifier:(NSString *)alarmId snoozeDate:(NSDate *)snoozeDate snoozeAction:(int)snoozeAction withCompletion:(id)completionHandler source:(id)source
{
    // on iOS 14, the alarm ID for the "Wake Up" alarm might not be the same
    NSString *sleeperAlarmId = alarmId;
    if (kSLSystemVersioniOS14 && [[[self activeSleepAlarm] alarmIDString] isEqualToString:alarmId]) {
        sleeperAlarmId = [SLCompatibilityHelper wakeUpAlarmId];
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