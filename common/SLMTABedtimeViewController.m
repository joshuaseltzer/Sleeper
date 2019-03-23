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

// the data source corresponding to a particular alarm
@interface MTAlarmDataSource : NSObject

// the sleep alarm that corresponds to the alarm data source object
@property (retain, nonatomic) MTAlarm *sleepAlarm;

@end

// interface for the sleep alarm (i.e. Bedtime) view controller
@interface MTABedtimeViewController : UIViewController

// the options view controller that is used to configure the Bedtime alarm (iOS 12)
@property (retain, nonatomic) MTABedtimeOptionsViewController *optionsController;

// the data source corresponding to the alarm (iOS 12)
@property (retain, nonatomic) MTAlarmDataSource *dataSource;

@end

// custom interface for added properties and methods
@interface MTABedtimeViewController (Sleeper)

// reset the skip activation status for the sleep alarm when any preferences are changed
- (void)SLResetSkipActivatedStatus;

@end

%hook MTABedtimeViewController

%new
- (void)SLResetSkipActivatedStatus
{
    // get the alarm ID for the special sleep alarm
    NSString *alarmId = nil;
    if (kSLSystemVersioniOS12) {
        alarmId = [self.dataSource.sleepAlarm alarmIDString];
    } else if (kSLSystemVersioniOS11) {
        AlarmManager *alarmManager = (AlarmManager *)[objc_getClass("AlarmManager") sharedManager];
        alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarmManager.sleepAlarm];
    }

    // reset the skip activation status for this alarm
    [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                 skipActivatedStatus:kSLSkipActivatedStatusUnknown];
}

- (void)showOptions:(UIBarButtonItem *)optionsBarButtonItem
{
    // If the options controller does not have the Sleeper properties set, set them now (iOS 12).  On iOS 11,
    // the preferences are set when the options view is loaded from the Alarm Manager.
    if (kSLSystemVersioniOS12) {
        NSString *alarmId = [self.dataSource.sleepAlarm alarmIDString];
        SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
        if (alarmPrefs == nil) {
            self.optionsController.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
        } else {
            self.optionsController.SLAlarmPrefs = alarmPrefs;
        }
        self.optionsController.SLAlarmPrefsChanged = NO;
        [self.optionsController updateDoneButtonEnabled];
    }

    %orig;
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
    // only initialize this file if we are on iOS 11 or iOS 12
    if (kSLSystemVersioniOS11 || kSLSystemVersioniOS12) {
        %init();
    }
}