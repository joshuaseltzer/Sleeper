//
//  SLMTABedtimeViewController.x
//  The view controller that lets a user configure the sleep alarm (used in iOS 11, iOS 12, and iOS 13).
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
    if (kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
        alarmId = [self.dataSource.sleepAlarm alarmIDString];
    } else if (kSLSystemVersioniOS11) {
        AlarmManager *alarmManager = (AlarmManager *)[objc_getClass("AlarmManager") sharedManager];
        alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarmManager.sleepAlarm];
    }

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

- (void)showOptions:(UIBarButtonItem *)optionsBarButtonItem
{
    // If the options controller does not have the Sleeper properties set, set them now (iOS 12).  On iOS 11,
    // the preferences are set when the options view is loaded from the Alarm Manager.
    if (kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
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
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS11 || kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
        %init();
    }
}