//
//  SLMTSleepAlarmViewController.x
//  The view controller that lets a user configure the sleep alarm on iOS 10.
//
//  Created by Joshua Seltzer on 2/26/17.
//
//

#import "SLAppleSharedInterfaces.h"
#import "SLPrefsManager.h"
#import "SLCompatibilityHelper.h"

// interface for the sleep alarm view controller
@interface MTSleepAlarmViewController : UIViewController

// reset the skip activation status for the sleep alarm when any preferences are changed
- (void)SLResetSkipActivatedStatus;

@end

%hook MTSleepAlarmViewController

%new
- (void)SLResetSkipActivatedStatus
{
    // get the alarm ID for the special sleep alarm
    AlarmManager *alarmManager = [AlarmManager sharedManager];
    NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarmManager.sleepAlarm];
    
    // if the alarm is no longer active and the skip activation has already been decided for this
    // alarm, disable the skip activation now
    SLPrefsSkipActivatedStatus skipActivatedStatus = [SLPrefsManager skipActivatedStatusForAlarmId:alarmId];
    if (skipActivatedStatus == kSLSkipActivatedStatusActivated || skipActivatedStatus == kSLSkipActivatedStatusDisabled) {
        // save the alarm's skip activation state to our preferences
        [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                     skipActivatedStatus:kSLSkipActivatedStatusUnknown];
    }
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
    // only initialize this file if we are on iOS 10
    if (kSLSystemVersioniOS10) {
        %init();
    }
}