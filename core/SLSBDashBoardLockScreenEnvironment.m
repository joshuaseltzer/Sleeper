//
//  SLSBDashBoardLockScreenEnvironment.x
//  Hooks into this class allow for actions to be performed upon unlocking the device (iOS 13).
//
//  Created by Joshua Seltzer on 11/17/19.
//
//

#import "SLSkipAlarmAlertItem.h"
#import "../common/SLAlarmPrefs.h"
#import "../common/SLCompatibilityHelper.h"

%hook SBDashBoardLockScreenEnvironment

// iOS 13: override to display a pop up allowing the user to skip an alarm
- (void)prepareForUIUnlock
{
    %orig;

    // get dates for today and tomorrow so we can properly determine if any of those alarms need to be skipped
    NSDate *today = [NSDate date];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = 1;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *tomorrow = [calendar dateByAddingComponents:dateComponents toDate:[calendar startOfDayForDate:today] options:0];

    // get the list of next alarms for today and tomorrow from the alarm manager
    MTAlarmManager *alarmManager = [[objc_getClass("MTAlarmManager") alloc] init];
    NSArray *nextAlarmsToday = [alarmManager nextAlarmsForDateSync:today maxCount:500 includeSleepAlarm:YES includeBedtimeNotification:NO];
    NSArray *nextAlarmsTomorrow = [alarmManager nextAlarmsForDateSync:tomorrow maxCount:500 includeSleepAlarm:YES includeBedtimeNotification:NO];
    NSArray *nextAlarms = @[];
    nextAlarms = [nextAlarms arrayByAddingObjectsFromArray:nextAlarmsToday];
    nextAlarms = [nextAlarms arrayByAddingObjectsFromArray:nextAlarmsTomorrow];
    
    // Iterate through the MTAlarm (and MTMutableAlarm) objects to see if any are skippable.  The alarm objects should already be sorted.
    NSString *alarmTitle = nil;
    NSString *alarmId = nil;
    NSDate *nextFireDate = nil;
    BOOL foundSkippableAlarm = NO;
    for (MTAlarm *alarm in nextAlarms) {
        // check first if this alarm is being snoozed
        if (!alarm.snoozed) {
            alarmId = [alarm alarmIDString];
            nextFireDate = [alarm nextFireDateAfterDate:[NSDate date] includeBedtimeNotification:NO];
            BOOL isAlarmSkippable = [SLCompatibilityHelper isAlarmSkippableForAlarmId:alarmId withNextFireDate:nextFireDate];
            if (isAlarmSkippable) {
                foundSkippableAlarm = YES;
                alarmTitle = alarm.displayTitle;
                break;
            }
        }
    }
    if (foundSkippableAlarm) {
        // after a slight delay, show an alert that will ask the user to skip the alarm on the main thread
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            // create and display the custom alert item
            SLSkipAlarmAlertItem *alert = [[objc_getClass("SLSkipAlarmAlertItem") alloc] initWithTitle:alarmTitle
                                                                                            alarmId:alarmId
                                                                                        nextFireDate:nextFireDate];
            [(SBAlertItemsController *)[objc_getClass("SBAlertItemsController") sharedInstance] activateAlertItem:alert animated:YES];
        });
    }
}

%end

%ctor {
    // check which version we are running to determine which group to initialize
    if (kSLSystemVersioniOS13) {
        %init();
    }
}