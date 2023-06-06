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

@property (nonatomic, retain) NSString *SLTitle;
@property (nonatomic, retain) NSString *SLAlarmId;
@property (nonatomic, retain) NSDate *SLAlertFireDate;

@end

// keep a single static instance of the date formatter that will be used to display the time to the user
static NSDateFormatter *sSLSAlertDateFormatter;

%subclass SLSkipAlarmAlertItem : SBAlertItem

// the title associated with this alert
%property (nonatomic, retain) NSString *SLTitle;

// the alarmId associated with the alarm being displayed in this alert
%property (nonatomic, retain) NSString *SLAlarmId;

// the fire date for the alarm in this alert
%property (nonatomic, retain) NSDate *SLAlertFireDate;

// create a new alert item with a given title, alarmId, and next fire date
%new
- (id)initWithTitle:(NSString *)title alarmId:(NSString *)alarmId nextFireDate:(NSDate *)nextFireDate
{
    self = [self init];
    if (self) {
        self.SLTitle = title;
        self.SLAlarmId = alarmId;
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
    self.SLTitle = nil;
    self.SLAlarmId = nil;
    self.SLAlertFireDate = nil;

    %orig;
}

// configure the alert with the alarm properties
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode
{
    %orig;

    // customize the alert controller
    self.alertController.title = kSLSkipAlarmString;
    self.alertController.message = kSLSkipQuestionString(self.SLTitle, [sSLSAlertDateFormatter stringFromDate:self.SLAlertFireDate]);

    // add yes, no, and cancel actions to the alert controller
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:kSLYesString
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                         // save the alarm's skip activation state to our preferences
                                                         [SLPrefsManager setSkipActivatedStatusForAlarmId:self.SLAlarmId
                                                                                      skipActivatedStatus:kSLSkipActivatedStatusActivated];
                                                         [self dismiss];
                                                      }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:kSLNoString
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         // save the alarm's skip activation state to our preferences
                                                         [SLPrefsManager setSkipActivatedStatusForAlarmId:self.SLAlarmId
                                                                                      skipActivatedStatus:kSLSkipActivatedStatusDisabled];
                                                         [self dismiss];
                                                     }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:kSLCancelString
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self dismiss];
                                                     }];
    
    // add the actions to the alert controller
    [self.alertController addAction:yesAction];
    [self.alertController addAction:noAction];
    [self.alertController addAction:cancelAction];

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

// do not allow the alert to be shown during setup
- (BOOL)allowInSetup
{
    return NO;
}

// always return YES so that the alert is automatically dismissed if the user locks the phone
- (BOOL)dismissOnLock
{
    return YES;
}

%end
