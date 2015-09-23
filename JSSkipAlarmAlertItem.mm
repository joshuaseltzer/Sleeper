//
//  JSSkipAlarmAlertItem.mm
//  Custom system alert item to ask the user if he or she would like to skip a given alarm.
//
//  Created by Joshua Seltzer on 8/9/15.
//
//

#import "JSSkipAlarmAlertItem.h"
#import "Sleeper/Sleeper/JSPrefsManager.h"
#import <UIKit/UIKit.h>

// the alarm object that is going to be alerted to the user
static Alarm *alertAlarm;

// the fire date for the alert that is being displayed
static NSDate *alertFireDate;

// keep a hold of the date formatter that will be used to display the time to the user
static NSDateFormatter *alertDateFormatter;

%subclass JSSkipAlarmAlertItem : SBAlertItem

// enum to define the different options a user can select from the alert sheet
typedef enum JSSkipAlarmAlertButtonIndex : NSInteger {
    kJSSkipAlarmAlertButtonIndexYes,
    kJSSkipAlarmAlertButtonIndexNo
} JSSkipAlarmAlertButtonIndex;

// create a new alert item with a given alarm and fire date
%new
- (id)initWithAlarm:(Alarm *)alarm nextFireDate:(NSDate *)nextFireDate
{
    self = [self init];
    if (self) {
        // set the alarm and date that we will present to the user
        alertAlarm = alarm;
        alertFireDate = nextFireDate;
        
        // Create the date formatter object once since date formatters are expensive
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
    // perform the original implementation to configure this alert
    %orig;
    
    // configure the alert sheet
    self.alertSheet.delegate = self;
    self.alertSheet.title = @"Skip Alarm";
    self.alertSheet.message = [NSString stringWithFormat:@"Would you like to skip \"%@\" that is scheduled to go off at %@?", alertAlarm.uiTitle, [alertDateFormatter stringFromDate:alertFireDate]];
    
    // add alert sheet buttons
    [self.alertSheet addButtonWithTitle:@"Yes"];
    [self.alertSheet addButtonWithTitle:@"No"];
}

// invoked when a button of the alert is pressed
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
    // determine the activation status depending on which button was pressed
    JSPrefsSkipActivatedStatus activatedStatus = kJSSkipActivatedStatusUnknown;
    if (index == kJSSkipAlarmAlertButtonIndexYes) {
        activatedStatus = kJSSkipActivatedStatusActivated;
    } else if (index == kJSSkipAlarmAlertButtonIndexNo) {
        activatedStatus = kJSSkipActivatedStatusDisabled;
    }
    
    // save the alarm's skip activation state to our preferences
    [JSPrefsManager setSkipActivatedStatusForAlarmId:alertAlarm.alarmId
                                 skipActivatedStatus:activatedStatus];
    
    // dismiss the alert regardless of the selection
    [self dismiss];
}

// do not allow the alert to be shown on the lock screen
- (BOOL)shouldShowInLockScreen
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