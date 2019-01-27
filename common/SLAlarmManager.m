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
    
    // reset the skip activation status for this alarm
    [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                 skipActivatedStatus:kSLSkipActivatedStatusUnknown];
}

%end