//
//  SLMTABedtimeViewController.x
//  The view controller that lets a user configure the sleep alarm (used in iOS 11).
//
//  Created by Joshua Seltzer on 4/1/18.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLPrefsManager.h"
#import "../SLCompatibilityHelper.h"

// interface for the sleep alarm view controller
@interface MTABedtimeViewController : UIViewController

// reset the skip activation status for the sleep alarm when any preferences are changed
- (void)SLResetSkipActivatedStatus;

@end

%hook MTABedtimeViewController

%new
- (void)SLResetSkipActivatedStatus
{
    // get the alarm ID for the special sleep alarm
    AlarmManager *alarmManager = [AlarmManager sharedManager];
    NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarmManager.sleepAlarm];
    
    // reset the skip activation status for this alarm
    [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                 skipActivatedStatus:kSLSkipActivatedStatusUnknown];
}

- (void)circleViewDidEndEditing:(id)sleepAlarmClockView
{
    // reset the skip activation status
    [self SLResetSkipActivatedStatus];

    %orig;
}

- (void)enableSwitchToggled:(UISwitch *)enableSwitch
{
    // reset the skip activation status
    [self SLResetSkipActivatedStatus];

    %orig;
}

%end

%ctor {
    // only initialize this file if we are on iOS 11
    if (kSLSystemVersioniOS11) {
        %init();
    }
}