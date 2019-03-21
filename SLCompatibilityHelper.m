//
//  SLCompatibilityHelper.m
//  Functions that are used to maintain system compatibility between different iOS versions.
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

#import "SLCompatibilityHelper.h"
#import "SLPrefsManager.h"
#import <objc/runtime.h>

@implementation SLCompatibilityHelper

// iOS 8 / iOS 9: modifies a snooze UIConcreteLocalNotification object with the selected snooze time (if applicable)
+ (void)modifySnoozeNotificationForLocalNotification:(UIConcreteLocalNotification *)localNotification
{
    // grab the alarm Id from the notification
    NSString *alarmId = [localNotification.userInfo objectForKey:kSLAlarmIdKey];

    // check to see if a modified snooze time is available to set on this notification record
    NSDate *modifiedSnoozeDate = [SLCompatibilityHelper modifiedSnoozeDateForAlarmId:alarmId withOriginalDate:localNotification.fireDate];
    if (modifiedSnoozeDate) {
        localNotification.fireDate = modifiedSnoozeDate;
    }
}

// iOS 10 / iOS 11: modifies a snooze UNSNotificationRecord object with the selected snooze time (if applicable)
+ (void)modifySnoozeNotificationForNotificationRecord:(UNSNotificationRecord *)notificationRecord
{
    // grab the alarm Id from the notification record
    NSString *alarmId = [notificationRecord.userInfo objectForKey:kSLAlarmIdKey];

    // check to see if a modified snooze time is available to set on this notification record
    NSDate *modifiedSnoozeDate = [SLCompatibilityHelper modifiedSnoozeDateForAlarmId:alarmId withOriginalDate:notificationRecord.triggerDate];
    if (modifiedSnoozeDate) {
        [notificationRecord setTriggerDate:modifiedSnoozeDate];
    }
}

// Returns a modified NSDate object with an appropriately modified snooze time for a given alarm Id and original date
// Returns nil if no modified snooze date is available
+ (NSDate *)modifiedSnoozeDateForAlarmId:(NSString *)alarmId withOriginalDate:(NSDate *)originalDate
{
    // check to see if we have an updated snooze time for this alarm
    NSDate *modifiedSnoozeDate = nil;
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs != nil) {
        // subtract the default snooze time from these values since they have already been added to
        // the fire date
        NSInteger hours = alarmPrefs.snoozeTimeHour - kSLDefaultSnoozeHour;
        NSInteger minutes = alarmPrefs.snoozeTimeMinute - kSLDefaultSnoozeMinute;
        NSInteger seconds = alarmPrefs.snoozeTimeSecond - kSLDefaultSnoozeSecond;
        
        // convert the entire value into seconds
        NSTimeInterval timeInterval = hours * 3600 + minutes * 60 + seconds;
        
        // create the modified date from the original date
        modifiedSnoozeDate = [originalDate dateByAddingTimeInterval:timeInterval];
    }
    return modifiedSnoozeDate;
}

// iOS 8 / iOS 9: Returns the next skippable alarm local notification.  If there is no skippable notification found, return nil.
+ (UIConcreteLocalNotification *)nextSkippableAlarmLocalNotification
{
    // create a comparator block to sort the array of notifications
    NSComparisonResult (^notificationComparator) (UIConcreteLocalNotification *, UIConcreteLocalNotification *) =
    ^(UIConcreteLocalNotification *lhs, UIConcreteLocalNotification *rhs) {
        // get the next fire date of the left hand side notification
        NSDate *lhsNextFireDate = [lhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        // get the next fire date of the right hand side notification
        NSDate *rhsNextFireDate = [rhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        return [lhsNextFireDate compare:rhsNextFireDate];
    };
    
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = (SBClockDataProvider *)[objc_getClass("SBClockDataProvider") sharedInstance];
    
    // get the scheduled notifications from the SBClockDataProvider (iOS 8) or the SBClockNotificationManager (iOS 9)
    NSArray *scheduledNotifications = nil;
    if (kSLSystemVersioniOS9) {
        // grab the shared instance of the clock notification manager for the scheduled notifications
        SBClockNotificationManager *clockNotificationManager = (SBClockNotificationManager *)[objc_getClass("SBClockNotificationManager") sharedInstance];
        scheduledNotifications = [clockNotificationManager scheduledLocalNotifications];
    } else {
        // get the scheduled notifications from the clock data provider
        scheduledNotifications = [clockDataProvider _scheduledNotifications];
    }
    
    // take the scheduled notifications and sort them by earliest date
    NSArray *sortedNotifications = [scheduledNotifications sortedArrayUsingComparator:notificationComparator];
    
    // iterate through all of the notifications that are scheduled
    UIConcreteLocalNotification *nextLocalNotification = nil;
    for (UIConcreteLocalNotification *notification in sortedNotifications) {
        // only continue checking if the given notification is an alarm notification and did not
        // originate from a snooze action
        if ([clockDataProvider _isAlarmNotification:notification] && ![Alarm isSnoozeNotification:notification]) {
            // grab the alarm Id from the notification
            NSString *alarmId = [clockDataProvider _alarmIDFromNotification:notification];
            
            // check to see if this notification is skippable
            if ([SLCompatibilityHelper isAlarmLocalNotificationSkippable:notification forAlarmId:alarmId]) {
                // since the array is sorted we know that this is the earliest skippable notification
                nextLocalNotification = notification;
                break;
            }
        }
    }
    
    return nextLocalNotification;
}

// iOS 10 / iOS 11: Returns the next skippable alarm notification request given an array of notification requests.
// If there is no skippable notification found, return nil.
+ (UNNotificationRequest *)nextSkippableAlarmNotificationRequestForNotificationRequests:(NSArray *)notificationRequests
{
    // create a comparator block to sort the array of notification requests
    NSComparisonResult (^notificationRequestComparator) (UNNotificationRequest *, UNNotificationRequest *) =
    ^(UNNotificationRequest *lhs, UNNotificationRequest *rhs) {
        // get the next trigger date of the left hand side notification request
        if ([lhs.trigger isKindOfClass:objc_getClass("UNLegacyNotificationTrigger")] && [rhs.trigger isKindOfClass:objc_getClass("UNLegacyNotificationTrigger")]) {
            NSDate *lhsTriggerDate = [((UNLegacyNotificationTrigger *)lhs.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                           withRequestedDate:nil
                                                                                             defaultTimeZone:[NSTimeZone localTimeZone]];
            
            // get the next trigger date of the right hand side notification request
            NSDate *rhsTriggerDate = [((UNLegacyNotificationTrigger *)rhs.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                           withRequestedDate:nil
                                                                                             defaultTimeZone:[NSTimeZone localTimeZone]];

            return [lhsTriggerDate compare:rhsTriggerDate];
        } else {
            return NSOrderedSame;
        }
    };

    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = (SBClockDataProvider *)[objc_getClass("SBClockDataProvider") sharedInstance];
    
    // take the scheduled notifications and sort them by earliest date by using the sort descriptor
    NSArray *sortedNotificationRequests = [notificationRequests sortedArrayUsingComparator:notificationRequestComparator];

    // iterate through all of the notifications that are scheduled
    UNNotificationRequest *nextNotificationRequest = nil;
    for (UNNotificationRequest *notificationRequest in sortedNotificationRequests) {
        // only continue checking if the given notification is an alarm notification and did not
        // originate from a snooze action
        if ([clockDataProvider _isAlarmNotificationRequest:notificationRequest] && ![notificationRequest.content isFromSnooze]) {
            // grab the alarm Id from the notification request
            NSString *alarmId = [clockDataProvider _alarmIDFromNotificationRequest:notificationRequest];

            // check to see if this notification request is skippable
            if ([SLCompatibilityHelper isAlarmNotificationRequestSkippable:notificationRequest forAlarmId:alarmId]) {
                // since the array is sorted we know that this is the earliest skippable notification
                nextNotificationRequest = notificationRequest;
                break;
            }
        }
    }

    return nextNotificationRequest;
}

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm
{
    // the alarm Id we will return
    NSString *alarmId = nil;
    
    // check the version of iOS that the device is running to determine where to get the alarm Id
    if (kSLSystemVersioniOS9 || kSLSystemVersioniOS10 || kSLSystemVersioniOS11) {
        alarmId = alarm.alarmID;
    } else {
        alarmId = alarm.alarmId;
    }
    
    return alarmId;
}

// returns the picker view's background color, which will depend on the iOS version
+ (UIColor *)pickerViewBackgroundColor
{
    // the color to return
    UIColor *color = nil;

    // check the version of iOS that the device is running to determine which color to pick
    if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11 || kSLSystemVersioniOS12) {
        color = [UIColor blackColor];
    } else {
        color = [UIColor whiteColor];
    }
    
    return color;
}

// returns the color of the standard labels used throughout the tweak
+ (UIColor *)defaultLabelColor
{
    // the color to return
    UIColor *color = nil;

    // check the version of iOS that the device is running to determine which color to pick
    if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11 || kSLSystemVersioniOS12) {
        color = [UIColor whiteColor];
    } else {
        color = [UIColor blackColor];
    }
    
    return color;
}

// returns the color of the destructive labels used throughout the tweak
+ (UIColor *)destructiveLabelColor
{
    return [UIColor colorWithRed:1.0
                           green:0.231373
                            blue:0.188235
                           alpha:1.0];
}

// iOS 10 / iOS 11 / iOS 12: returns the cell selection background color for cells
+ (UIColor *)tableViewCellSelectedBackgroundColor
{
    return [UIColor colorWithRed:52.0 / 255.0
                           green:52.0 / 255.0
                            blue:52.0 / 255.0
                           alpha:1.0];
}

// iOS 8 / iOS 9: helper function that will investigate an alarm local notification and alarm Id to see if it is skippable
+ (BOOL)isAlarmLocalNotificationSkippable:(UIConcreteLocalNotification *)localNotification
                               forAlarmId:(NSString *)alarmId
{
    // grab the attributes for the alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    
    // check to see if the skip functionality has been enabled for the alarm
    BOOL skippable = NO;
    if (alarmPrefs && ![alarmPrefs shouldSkip] && alarmPrefs.skipEnabled && alarmPrefs.skipActivationStatus == kSLSkipActivatedStatusUnknown) {
        // create a date components object with the user's selected skip time to see if we are within
        // the threshold to ask the user to skip the alarm
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setHour:alarmPrefs.skipTimeHour];
        [components setMinute:alarmPrefs.skipTimeMinute];
        [components setSecond:alarmPrefs.skipTimeSecond];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // create a date that is the amount of time ahead of the current date
        NSDate *thresholdDate = [calendar dateByAddingComponents:components
                                                          toDate:[NSDate date]
                                                         options:0];
        
        // get the fire date of the alarm we are checking
        NSDate *alarmFireDate = [localNotification nextFireDateAfterDate:[NSDate date]
                                                           localTimeZone:[NSTimeZone localTimeZone]];
        
        // compare the dates to see if this notification is skippable
        skippable = [alarmFireDate compare:thresholdDate] == NSOrderedAscending;
    }

    return skippable;
}

// iOS 10 / iOS 11: helper function that will investigate an alarm notification request and alarm Id to see if it is skippable
+ (BOOL)isAlarmNotificationRequestSkippable:(UNNotificationRequest *)notificationRequest
                                 forAlarmId:(NSString *)alarmId
{
    // grab the attributes for the alarm
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    
    // check to see if the skip functionality has been enabled for the alarm
    BOOL skippable = NO;
    if ([notificationRequest.trigger isKindOfClass:objc_getClass("UNLegacyNotificationTrigger")] && alarmPrefs && ![alarmPrefs shouldSkip] && alarmPrefs.skipEnabled && alarmPrefs.skipActivationStatus == kSLSkipActivatedStatusUnknown) {
        // create a date components object with the user's selected skip time to see if we are within
        // the threshold to ask the user to skip the alarm
        NSDateComponents *components= [[NSDateComponents alloc] init];
        [components setHour:alarmPrefs.skipTimeHour];
        [components setMinute:alarmPrefs.skipTimeMinute];
        [components setSecond:alarmPrefs.skipTimeSecond];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // create a date that is the amount of time ahead of the current date
        NSDate *thresholdDate = [calendar dateByAddingComponents:components
                                                          toDate:[NSDate date]
                                                         options:0];
        
        // get the fire date of the alarm we are checking
        NSDate *nextTriggerDate = [((UNLegacyNotificationTrigger *)notificationRequest.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                                        withRequestedDate:nil
                                                                                                          defaultTimeZone:[NSTimeZone localTimeZone]];
        
        // compare the dates to see if this notification is skippable
        skippable = [nextTriggerDate compare:thresholdDate] == NSOrderedAscending;
    }
    
    return skippable;
}

@end