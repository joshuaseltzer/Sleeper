//
//  JSSkipAlarmAlertItem.mm
//  Custom system alert item to ask the user if he or she would like to skip a given alarm.
//
//  Created by Joshua Seltzer on 8/9/15.
//
//

#import "JSSkipAlarmAlertItem.h"
#import "JSPrefsManager.h"
#import "JSLocalizedStrings.h"
#import "JSCompatibilityHelper.h"

// the alarm object that is going to be alerted to the user
static Alarm *alertAlarm;

// the fire date for the alert that is being displayed
static NSDate *alertFireDate;

// keep a hold of the date formatter that will be used to display the time to the user
static NSDateFormatter *alertDateFormatter;

// enum to define the different options a user can select from the alert sheet
typedef enum JSSkipAlarmAlertButtonIndex : NSInteger {
    kJSSkipAlarmAlertButtonIndexYes,
    kJSSkipAlarmAlertButtonIndexNo
} JSSkipAlarmAlertButtonIndex;

%subclass JSSkipAlarmAlertItem : SBAlertItem

// create a new alert item with a given alarm and fire date
%new
- (id)initWithAlarm:(Alarm *)alarm nextFireDate:(NSDate *)nextFireDate
{
    self = [self init];
    if (self) {
        // set the alarm and date that we will present to the user
        alertAlarm = alarm;
        alertFireDate = nextFireDate;
        
        // create the date formatter object once since date formatters are expensive
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            alertDateFormatter = [[NSDateFormatter alloc] init];
            alertDateFormatter.dateFormat = @"h:mm a";
        });
    }
    return self;
}

// configure the alert with the alarm properties
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode
{
    %orig;

    // customize the alert controller
    self.alertController.title = LZ_SKIP_ALARM;
    self.alertController.message = LZ_SKIP_QUESTION(alertAlarm.uiTitle, [alertDateFormatter stringFromDate:alertFireDate]);

    // add yes and no actions to the alert controller
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:LZ_YES
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         // save the alarm's skip activation state to our preferences
                                                         [JSPrefsManager setSkipActivatedStatusForAlarmId:[JSCompatibilityHelper alarmIdForAlarm:alertAlarm]
                                                                                      skipActivatedStatus:kJSSkipActivatedStatusActivated];
                                                         
                                                         // deactivate the alert
                                                         [self dismiss];
                                                     }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:LZ_NO
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         // save the alarm's skip activation state to our preferences
                                                         [JSPrefsManager setSkipActivatedStatusForAlarmId:[JSCompatibilityHelper alarmIdForAlarm:alertAlarm]
                                                                                      skipActivatedStatus:kJSSkipActivatedStatusDisabled];
                                                         
                                                         // deactivate the alert
                                                         [self dismiss];
                                                     }];
    
    // add the actions to the alert controller
    [self.alertController addAction:yesAction];
    [self.alertController addAction:noAction];
}

// do no allow the alert to be shown during an emergency call
- (BOOL)shouldShowInEmergencyCall
{
    return NO;
}

// do not allow the alert to be shown on the lock screen
- (BOOL)shouldShowInLockScreen
{
    return NO;
}

// do not allow the alert to be shown in Apple CarPlay
- (BOOL)allowInCar
{
    return NO;
}

// always return YES so that the alert is automatically dismissed if the user locks the phone
- (BOOL)dismissOnLock
{
    return YES;
}

// dismiss this alert automatically after a particular time interval (see below)
- (BOOL)dismissesAutomatically
{
    return YES;
}

// make sure to automatically dismiss the alert before the alarm is going to be fired
- (double)autoDismissInterval
{
    return [alertFireDate timeIntervalSinceDate:[NSDate date]] - 1.0f;
}

%end
