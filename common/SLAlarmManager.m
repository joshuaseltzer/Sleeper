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

// used for multiple versions of iOS
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
    
    // if the alarm is no longer active and the skip activation has already been decided for this
    // alarm, disable the skip activation now
    SLPrefsSkipActivatedStatus skipActivatedStatus = [SLPrefsManager skipActivatedStatusForAlarmId:alarmId];
    if (skipActivatedStatus == kSLSkipActivatedStatusActivated || skipActivatedStatus == kSLSkipActivatedStatusDisabled) {
        // save the alarm's skip activation state to our preferences
        [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                     skipActivatedStatus:kSLSkipActivatedStatusUnknown];
    }
}

%end