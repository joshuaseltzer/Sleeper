//
//  SLMTUserNotificationCenter.x
//  Handles the posting of notifications for a scheduled alarm (iOS 12, iOS 13).
//
//  Created by Joshua Seltzer on 3/20/2019.
//
//

#import "../SLCompatibilityHelper.h"

// trigger object which signifies why an alarm was fired
@interface MTTrigger : NSObject

// signifies whether or not this trigger is for an alert
@property (readonly, nonatomic) BOOL isForAlert;

// signifies whether or not this trigger is from snooze
@property (readonly, nonatomic) BOOL isForSnooze;

@end

// protocol defining a schedulable object
@protocol MTScheduleable

// the identifier for the scheduleable object, which is the alarm Id
- (NSString *)identifier;

@end

// the scheduled object that will be fired when a notification is about to be posted
@interface MTScheduledObject : NSObject

// the trigger that invoked this scheduled object
@property (copy, nonatomic) MTTrigger *trigger;

// the schedulable object, in this case an MTAlarm
@property (copy, nonatomic) id <MTScheduleable> scheduleable;

@end

%hook MTUserNotificationCenter

// Invoked whenever the content for a scheduled alarm notification is going to be created.  Override this function
// to potentially set no content for the notification if we are to skip the alarm.
+ (void)_setSpecificContent:(UNMutableNotificationContent *)notificationContent forScheduledAlarm:(MTScheduledObject *)scheduledObject
{
    // check to see if the alarm's trigger is an alert (as opposed to a snooze alert or snooze countdown)
    if (scheduledObject.trigger.isForAlert && !scheduledObject.trigger.isForSnooze) {
        // get the identifier for the scheduled object, which is in fact the alarm Id
        NSString *alarmId = [scheduledObject.scheduleable identifier];

        // get the sleeper alarm preferences for this alarm
        SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
        if (alarmPrefs) {
            // only activate the actual alarm if we should not be skipping this alarm
            if (![alarmPrefs shouldSkipToday]) {
                %orig;
            }

            // save the alarm's skip activation state to unknown for this alarm
            if (alarmPrefs.skipActivationStatus != kSLSkipActivatedStatusUnknown) {
                [SLPrefsManager setSkipActivatedStatusForAlarmId:alarmId
                                            skipActivatedStatus:kSLSkipActivatedStatusUnknown];
            }
        } else {
            %orig;
        }
    } else {
        %orig;
    }
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
        %init();
    }
}