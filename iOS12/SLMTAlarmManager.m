//
//  SLMTAlarmManager.x
//  Modify Apple's internal class for managing alarms (iOS 12).
//
//  Created by Joshua Seltzer on 3/16/2019.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLCompatibilityHelper.h"
#import "../SLPrefsManager.h"

// alarm manager used in iOS 12
%hook MTAlarmManager

- (id)removeAlarm:(MTMutableAlarm *)alarm
{
    // delete the attributes for this given alarm
    [SLPrefsManager deleteAlarmForAlarmId:[alarm alarmIDString]];

    return %orig;
}

- (id)updateAlarm:(MTMutableAlarm *)alarm
{
    // check if we have alarm preferences for this alarm
    NSString *alarmId = [alarm alarmIDString];
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs) {
        // reset the skip activation status for this alarm
        [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                     skipActivatedStatus:kSLSkipActivatedStatusUnknown];
    } else {
        alarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
        [SLPrefsManager saveAlarmPrefs:alarmPrefs];
    }

    return %orig;
}

%end

%ctor {
    // only initialize this file if we are on iOS 12
    if (kSLSystemVersioniOS12) {
        %init();
    }
}