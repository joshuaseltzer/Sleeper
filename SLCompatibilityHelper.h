//
//  SLCompatibilityHelper.h
//  Functions that are used to maintain system compatibility between different iOS versions.
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

// define the core foundation version numbers if they have not already been defined
#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1240.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_10_0
#define kCFCoreFoundationVersionNumber_iOS_10_0 1348.00
#endif

// create definitions for the different versions of iOS that are supported by Sleeper
#define kSLSystemVersioniOS10 kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0
#define kSLSystemVersioniOS9 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)
#define kSLSystemVersioniOS8 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)

#import "SLAppleSharedInterfaces.h"

// interface for version compatibility functions throughout the application
@interface SLCompatibilityHelper : NSObject

// iOS8/iOS9: returns a modified snooze UIConcreteLocalNotification object with the selected snooze time (if applicable)
+ (UIConcreteLocalNotification *)modifiedSnoozeNotificationForLocalNotification:(UIConcreteLocalNotification *)localNotification;

// iOS10: returns a modified snooze UNSNotificationRecord object with the selected snooze time (if applicable)
+ (UNSNotificationRecord *)modifiedSnoozeNotificationForNotificationRecord:(UNSNotificationRecord *)notificationRecord;

// iOS8/iOS9: Returns the next skippable alarm local notification.  If there is no skippable notification found, return nil.
+ (UIConcreteLocalNotification *)nextSkippableAlarmLocalNotification;

// iOS10: Returns the next skippable alarm notification request given an array of notification requests.
// If there is no skippable notification found, return nil.
+ (UNNotificationRequest *)nextSkippableAlarmNotificationRequestForNotificationRequests:(NSArray *)notificationRequests;

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm;

// returns the picker view's background color, which will depend on the iOS version
+ (UIColor *)pickerViewBackgroundColor;

// returns the color of the labels in the picker view
+ (UIColor *)pickerViewLabelColor;

@end