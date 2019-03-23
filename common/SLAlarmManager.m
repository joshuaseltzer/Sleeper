//
//  SLAlarmManager.x
//  Modify Apple's internal class for managing alarms.
//
//  Created by Joshua Seltzer on 2/22/17.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLCompatibilityHelper.h"
#import "../SLPrefsManager.h"

// utilized in iOS 8, iOS 9, iOS 10, and iOS 11
%hook AlarmManager

- (void)removeAlarm:(Alarm *)alarm
{
    %orig;

    // delete the attributes for this given alarm
    [SLPrefsManager deleteAlarmForAlarmId:[SLCompatibilityHelper alarmIdForAlarm:alarm]];
}

- (void)setAlarm:(Alarm *)alarm active:(BOOL)active
{
    %orig;
    
    // get the alarm Id for the alarm
    NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarm];
    
    // check if we have alarm preferences for this alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs) {
        // reset the skip activation status for this alarm
        [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                     skipActivatedStatus:kSLSkipActivatedStatusUnknown];
    } else {
        alarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
        [SLPrefsManager saveAlarmPrefs:alarmPrefs];
    }
}

%end

%ctor {
    // only initialize this file if we are on iOS 8, iOS 9, iOS 10, or iOS 11
    if (kSLSystemVersioniOS8 || kSLSystemVersioniOS9 || kSLSystemVersioniOS10 || kSLSystemVersioniOS11) {
        %init();
    }
}