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
    // reset the skip activation status for this alarm
    [SLPrefsManager setSkipActivatedStatusForAlarmId:[alarm alarmIDString]
                                 skipActivatedStatus:kSLSkipActivatedStatusUnknown];

    return %orig;
}

%end

%ctor {
    // only initialize this file if we are on iOS 12
    if (kSLSystemVersioniOS12) {
        %init();
    }
}