//
//  SLSBLockScreenViewController.x
//  Hook into the SBLockScreenViewController class to potentially show an alert after unlocking the device for iOS 8 or iOS 9.
//
//  Created by Joshua Seltzer on 2/23/17.
//
//

#import "../common/SLSkipAlarmAlertItem.h"
#import "../common/SLCompatibilityHelper.h"

%hook SBLockScreenViewController

// iOS 8 / iOS 9: override to display a pop up allowing the user to skip an alarm
- (void)finishUIUnlockFromSource:(int)source
{
    %orig;

    // check first to see if an existing skip alarm alert is being shown
    SBAlertItemsController *alertItemsController = (SBAlertItemsController *)[objc_getClass("SBAlertItemsController") sharedInstance];
    if (![alertItemsController hasAlertOfClass:objc_getClass("SLSkipAlarmAlertItem")]) {
        // grab the shared instance of the clock data provider
        SBClockDataProvider *clockDataProvider = [objc_getClass("SBClockDataProvider") sharedInstance];
        
        // attempt to get the next skippable alarm notification
        UIConcreteLocalNotification *nextAlarmNotification = [SLCompatibilityHelper nextSkippableAlarmLocalNotification];
        
        // if we found a valid alarm, check to see if we should ask to skip it
        if (nextAlarmNotification != nil) {
            // grab the alarm Id for this notification
            NSString *alarmId = [clockDataProvider _alarmIDFromNotification:nextAlarmNotification];
            
            // grab the shared instance of the alarm manager and load the alarms
            AlarmManager *alarmManager = (AlarmManager *)[objc_getClass("AlarmManager") sharedManager];
            [alarmManager loadAlarms];
            Alarm *alarm = [alarmManager alarmWithId:alarmId];
            
            // after a slight delay, show an alert that will ask the user to skip the alarm
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                // get the fire date of the alarm we are going to display
                NSDate *alarmFireDate = [nextAlarmNotification nextFireDateAfterDate:[NSDate date]
                                                                       localTimeZone:[NSTimeZone localTimeZone]];
                
                // create and display the custom alert item
                SLSkipAlarmAlertItem *alert = [[objc_getClass("SLSkipAlarmAlertItem") alloc] initWithTitle:[SLCompatibilityHelper alarmTitleForAlarm:alarm]
                                                                                                   alarmId:alarmId
                                                                                              nextFireDate:alarmFireDate];
                [alertItemsController activateAlertItem:alert animated:YES];
            });
        }
    }
}

%end

%ctor {
    // only initialize this file if we are on iOS 8 or iOS 9
    if (kSLSystemVersioniOS8 || kSLSystemVersioniOS9) {
        %init();
    }
}