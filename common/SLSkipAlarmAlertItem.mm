//
//  SLSkipAlarmAlertItem.xm
//  Custom system alert item to ask the user if he or she would like to skip a given alarm.
//
//  Created by Joshua Seltzer on 8/9/15.
//
//

#import "SLSkipAlarmAlertItem.h"
#import "SLPrefsManager.h"
#import "SLLocalizedStrings.h"
#import "SLCompatibilityHelper.h"

// private interface definition to define some properties
@interface SLSkipAlarmAlertItem (Sleeper)

@property (nonatomic, retain) Alarm *SLAlertAlarm;
@property (nonatomic, retain) NSDate *SLAlertFireDate;

@end

// keep a single static instance of the date formatter that will be used to display the time to the user
static NSDateFormatter *sSLSAlertDateFormatter;

%subclass SLSkipAlarmAlertItem : SBAlertItem

// the alarm object associated with this alert
%property (nonatomic, retain) Alarm *SLAlertAlarm;

// the fire date for the alarm in this alert
%property (nonatomic, retain) NSDate *SLAlertFireDate;

// create a new alert item with a given alarm and fire date
%new
- (id)initWithAlarm:(Alarm *)alarm nextFireDate:(NSDate *)nextFireDate
{
    self = [self init];
    if (self) {
        // set the alarm and date that we will present to the user
        self.SLAlertAlarm = alarm;
        self.SLAlertFireDate = nextFireDate;
        
        // create the date formatter object once since date formatters are expensive
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            sSLSAlertDateFormatter = [[NSDateFormatter alloc] init];
            sSLSAlertDateFormatter.dateFormat = @"h:mm a";
        });
    }
    return self;
}

- (void)dealloc
{
    // clear out some properties associated with this alert
    self.SLAlertAlarm = nil;
    self.SLAlertFireDate = nil;

    %orig;
}

// configure the alert with the alarm properties
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode
{
    %orig;

    // determine the title of the alarm
    NSString *alarmTitle = nil;
    if ((kSLSystemVersioniOS10 || kSLSystemVersioniOS11) && [self.SLAlertAlarm isSleepAlarm]) {
        alarmTitle = kSLSleepAlarmString;
    } else {
        alarmTitle = self.SLAlertAlarm.uiTitle;
    }

    // customize the alert controller
    self.alertController.title = kSLSkipAlarmString;
    self.alertController.message = kSLSkipQuestionString(alarmTitle, [sSLSAlertDateFormatter stringFromDate:self.SLAlertFireDate]);

    // add yes and no actions to the alert controller
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:kSLYesString
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                         // save the alarm's skip activation state to our preferences
                                                         [SLPrefsManager setSkipActivatedStatusForAlarmId:[SLCompatibilityHelper alarmIdForAlarm:self.SLAlertAlarm]
                                                                                      skipActivatedStatus:kSLSkipActivatedStatusActivated];
                                                         [self dismiss];
                                                      }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:kSLNoString
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         // save the alarm's skip activation state to our preferences
                                                         [SLPrefsManager setSkipActivatedStatusForAlarmId:[SLCompatibilityHelper alarmIdForAlarm:self.SLAlertAlarm]
                                                                                      skipActivatedStatus:kSLSkipActivatedStatusDisabled];
                                                         [self dismiss];
                                                     }];
    
    // add the actions to the alert controller
    [self.alertController addAction:yesAction];
    [self.alertController addAction:noAction];

    // if the alert still exists, be sure to dismiss the alert just before the alarm will fire
    __weak typeof(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(([self.SLAlertFireDate timeIntervalSinceDate:[NSDate date]] - 1.0f) * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        // if the alert still exists, then automatically dismiss the alert
        if (weakSelf) {
            [weakSelf dismiss];
        }
    });
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

%end
