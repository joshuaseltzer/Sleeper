//
//  SLMTAlarmManager.x
//  Modify Apple's internal class for managing alarms (iOS 12 and iOS 13).
//
//  Created by Joshua Seltzer on 3/16/2019.
//
//

#import "../common/SLCompatibilityHelper.h"
#import "../common/SLPrefsManager.h"

// alarm manager used in modern versions of iOS
%hook MTAlarmManager

- (id)removeAlarm:(MTMutableAlarm *)alarm
{
    // delete the attributes for this given alarm
    [SLPrefsManager deleteAlarmForAlarmId:[alarm alarmIDString]];

    return %orig;
}

- (id)updateAlarm:(MTMutableAlarm *)alarm
{
    // proceed to potentially update the alarm's Sleeper preferences if the update wasn't initiated by the tweak itself
    if (!alarm.SLWasUpdatedBySleeper) {
        // check if we have alarm preferences for this alarm
        NSString *alarmId = [alarm alarmIDString];
        SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
        if (alarmPrefs && alarmPrefs.skipActivationStatus != kSLSkipActivatedStatusUnknown) {
            // reset the skip activation status for this alarm
            [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                        skipActivatedStatus:kSLSkipActivatedStatusUnknown];
        } else if (!alarmPrefs) {
            alarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
            [SLPrefsManager saveAlarmPrefs:alarmPrefs];
        }
    }
    

    return %orig;
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS13 || kSLSystemVersioniOS12) {
        %init();
    }
}