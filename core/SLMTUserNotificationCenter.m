//
//  SLMTUserNotificationCenter.x
//  Handles the posting of notifications for a scheduled alarm (iOS 12, iOS 13).
//
//  Created by Joshua Seltzer on 3/20/2019.
//
//

#import "../common/SLPrefsManager.h"
#import "../common/SLAlarmPrefs.h"
#import "../common/SLCompatibilityHelper.h"

// trigger object which signifies why an alarm was fired
@interface MTTrigger : NSObject

// signifies whether or not this trigger is for an alert
@property (readonly, nonatomic) BOOL isForAlert;

// signifies whether or not this trigger is from snooze
@property (readonly, nonatomic) BOOL isForSnooze;

@end

// protocol defining a schedulable object
@protocol MTScheduleable

// the identifier for the scheduleable object, which is the alarm Id in this case
- (NSString *)identifier;

@end

// the scheduled object that will be fired when a notification is about to be posted
@interface MTScheduledObject : NSObject

// the trigger that invoked this scheduled object
@property (copy, nonatomic) MTTrigger *trigger;

// the schedulable object, which in this case is an MTAlarm object
@property (copy, nonatomic) id <MTScheduleable> scheduleable;

@end



@interface MTSleepModeManager : NSObject

-(id)initWithDelegate:(id)arg1 ;

-(id)initWithDelegate:(id)arg1 isSynchronous:(BOOL)arg2 ;

-(void)setEnabled:(BOOL)arg1 ;

@end

@interface MTSleepModeStateMachine : NSObject

@end

@interface MTSleepModeMonitor : NSObject

-(void)userDisengagedSleepMode;

-(MTSleepModeStateMachine *)stateMachine;

-(BOOL)stateMachine:(id)arg1 disengageSleepModeUserRequested:(BOOL)arg2;

@end

@interface MTSleepCoordinator : NSObject

-(MTSleepModeMonitor *)sleepModeMonitor;

@end

@interface MTSleepSessionManager : NSObject

@end

@interface MTAgent : NSObject

+(id)agent;

-(void)_setupSync;

-(MTSleepSessionManager *)sleepSessionManager;

-(MTSleepCoordinator *)sleepCoordinator;

-(MTSleepModeMonitor *)sleepModeMonitor;

@end

@interface HDSPEnvironment : NSObject

+(id)standardEnvironment;

@end

%hook MTUserNotificationCenter

// Invoked whenever the content for a scheduled alarm notification is going to be created.  Override this function
// to potentially set no content for the notification if we are to skip the alarm.
+ (void)_setSpecificContent:(UNMutableNotificationContent *)notificationContent forScheduledAlarm:(MTScheduledObject *)scheduledObject
{
    // check to see if the alarm's trigger is an alert (as opposed to a snooze alert or snooze countdown)
    if (scheduledObject.trigger.isForAlert && !scheduledObject.trigger.isForSnooze && scheduledObject.scheduleable != nil) {
        // get the identifier for the scheduled object, which is in fact the alarm Id
        NSString *alarmId = [scheduledObject.scheduleable identifier];

        // on iOS 14, the alarm ID for the "Wake Up" alarm might not be the same
        NSString *sleeperAlarmId = alarmId;
        if (kSLSystemVersioniOS14) {
            sleeperAlarmId = [SLCompatibilityHelper sleeperAlarmIdForAlarmId:alarmId withAlarm:(MTAlarm *)scheduledObject.scheduleable];
        }

        // get the sleeper alarm preferences for this alarm
        SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:sleeperAlarmId];
        if (alarmPrefs) {
            // only activate the actual alarm if we should not be skipping this alarm
            if (![alarmPrefs shouldSkipToday]) {
                %orig;
            }

            /*MTAgent *timerAgent = [objc_getClass("MTAgent") agent];
            [timerAgent _setupSync];
            NSLog(@"SELTZER - timerAgent: %@", timerAgent);
            NSLog(@"SELTZER - sleepSessionManager: %@", [timerAgent sleepSessionManager]);
            NSLog(@"SELTZER - sleepCoordinator: %@", [timerAgent sleepCoordinator]);
            NSLog(@"SELTZER - sleepModeMonitor: %@", [timerAgent sleepModeMonitor]);
            //[sleepModeMonitor stateMachine:[sleepModeMonitor stateMachine] disengageSleepModeUserRequested:YES];
            */

            /*
            MTSleepModeManager *sleepModeManager = (MTSleepModeManager *)[[objc_getClass("MTSleepModeManager") alloc] initWithDelegate:nil isSynchronous:YES];
            NSLog(@"SELTZER - sleepModeManager: %@", sleepModeManager);
            [sleepModeManager setEnabled:NO];
            */

            /*HDSPEnvironment *hdspEnv = [objc_getClass("HDSPEnvironment") standardEnvironment];
            NSLog(@"SELTZER - HDSPEnvironment: %@", hdspEnv);*/

            // save the alarm's skip activation state to unknown for this alarm
            if (alarmPrefs.skipActivationStatus != kSLSkipActivatedStatusUnknown) {
                [SLPrefsManager setSkipActivatedStatusForAlarmId:sleeperAlarmId
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

%hook MTSleepModeManager

-(void)setEnabled:(BOOL)arg1
{
    NSLog(@"SELTZER - sleepModeManager setEnabled");
    %orig;
}

%end

%hook MTSleepModeMonitor

-(void)userDisengagedSleepModeOnDate:(id)arg1
{
    NSLog(@"SELTZER - userDisengagedSleepModeOnDate");
    %orig;
}

-(BOOL)stateMachine:(id)arg1 disengageSleepModeUserRequested:(BOOL)arg2
{
    NSLog(@"SELTZER - stateMachine disengageSleepModeUserRequested");
    return %orig;
}

-(void)userDisengagedSleepMode
{
    NSLog(@"SELTZER - userDisengagedSleepMode");
    %orig;
}

-(void)sleepCoordinator:(id)arg1 userWokeUp:(id)arg2 sleepAlarm:(id)arg3
{
    NSLog(@"SELTZER - sleepCoordinator userWokeUp");
    %orig;
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS14 || kSLSystemVersioniOS13 || kSLSystemVersioniOS12) {
        %init();
    }
}