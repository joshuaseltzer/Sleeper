//
//  SLMTABedtimeViewController.x
//  The view controller that lets a user configure the sleep alarm (used in iOS 11 and iOS 12).
//
//  Created by Joshua Seltzer on 4/1/18.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLPrefsManager.h"
#import "../SLCompatibilityHelper.h"

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

%group iOS12

%hook MTABedtimeViewController

- (void)showOptions:(UIBarButtonItem *)optionsBarButtonItem
{
    // If the options controller does not have the Sleeper properties set, set them now (iOS 12).  On iOS 11,
    // the preferences are set when the options view is loaded from the Alarm Manager.
    NSString *alarmId = [self.dataSource.sleepAlarm alarmIDString];
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs == nil) {
        self.optionsController.SLAlarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
    } else {
        self.optionsController.SLAlarmPrefs = alarmPrefs;
    }
    self.optionsController.SLAlarmPrefsChanged = NO;
    [self.optionsController updateDoneButtonEnabled];

    %orig;
}

%end

%end // %group iOS12

%group iOS11

%hook MTABedtimeViewController

// Method that will set the reset the skip activation status when various views are edited.  This is not needed
// on iOS 12 since the MTAlarmManager's updateAlarm will be called anytime the sleep timer is edited.
%new
- (void)SLResetSkipActivatedStatus
{
    // get the alarm ID for the special sleep alarm
    AlarmManager *alarmManager = (AlarmManager *)[objc_getClass("AlarmManager") sharedManager];
    NSString *alarmId = [SLCompatibilityHelper alarmIdForAlarm:alarmManager.sleepAlarm];

    // check if we have alarm preferences for this alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs || alarmPrefs.skipActivationStatus != kSLSkipActivatedStatusUnknown) {
        // reset the skip activation status for this alarm
        [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                     skipActivatedStatus:kSLSkipActivatedStatusUnknown];
    } else if (!alarmPrefs) {
        alarmPrefs = [[SLAlarmPrefs alloc] initWithAlarmId:alarmId];
        [SLPrefsManager saveAlarmPrefs:alarmPrefs];
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

%end // %group iOS11

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS12) {
        %init(iOS12)
    } else if (kSLSystemVersioniOS11) {
        %init(iOS11);
    }
}