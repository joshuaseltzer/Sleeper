//
//  SLAppleSharedInterfaces.h
//  Contains all shared interfaces as defined by Apple that are utilized in the hooking code.
//
//  Created by Joshua Seltzer on 12/11/14.
//
//

@import UserNotifications;
#import "SLAlarmPrefs.h"
#import "SLPickerTableViewController.h"
#import "SLSkipDatesViewController.h"

// iOS 8 / iOS 9: the notification that gets fired when the user decides to snooze an alarm
@interface UIConcreteLocalNotification : UILocalNotification

// returns a date for a given notification that will happen after a date in a given time zone
- (NSDate *)nextFireDateAfterDate:(NSDate *)date localTimeZone:(NSTimeZone *)timeZone;

@end

// the alarm object (introduced in iOS 12)
@interface MTAlarm : NSObject

// returns a string representation of the alarm Id
- (NSString *)alarmIDString;

@end

// an extension to the MTAlarm interface indicating an editable alarm (iOS 12)
@interface MTMutableAlarm : MTAlarm
@end

// the alarm object that contains all of the information about the alarm (iOS 8 - iOS 11)
@interface Alarm : NSObject

// tells us if the given notification object was generated from a snooze notification (iOS 8 / iOS 9)
+ (BOOL)isSnoozeNotification:(UIConcreteLocalNotification *)notification;

// iOS 8: the alarm Id corresponding to the alarm object
@property (readonly) NSString *alarmId;

// iOS 9 / iOS 10 / iOS 11: the alarm Id corresponding to the alarm object
@property (nonatomic, retain) NSString *alarmID;

// the display title of the alarm
@property (readonly, nonatomic) NSString *uiTitle;

// returns the next date that this alarm will fire
- (NSDate *)nextFireDate;

// simulates when an alarm gets fired
- (void)handleAlarmFired:(UIConcreteLocalNotification *)notification;

// iOS 10 / iOS 11: determines whether or not the alarm is the sleep/bedtime alarm
- (BOOL)isSleepAlarm;

@end

// table view controller which configures the settings for the sleep alarm
@interface MTABedtimeOptionsViewController : UITableViewController

// updates the status of the done button on the view controller
- (void)updateDoneButtonEnabled;

@end

// custom interface for added properties to the options controller
@interface MTABedtimeOptionsViewController (Sleeper) <SLPickerSelectionDelegate, SLSkipDatesDelegate>

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;
@property (nonatomic, assign) BOOL SLAlarmPrefsChanged;

@end

/*@interface MTAlarmCache : NSObject

@end

// manager that governs all alarms on the system (iOS 12)
@interface MTAlarmManager : NSObject

- (id)alarms;

+ (void)warmUp;

- (void)reconnect;
- (void)checkIn;

- (id)sleepAlarm;

- (void)_getCachedAlarmsWithFuture:(id)arg1 finishBlock:(void (^)(MTAlarmCache *))arg2;

@property(retain, nonatomic) MTAlarmCache *cache;

@end*/

// manager that governs all alarms on the system
@interface AlarmManager : NSObject

// the shared alarm manager
+ (id)sharedManager;

// loads the alarms on the system in the manager object
- (void)loadAlarms;

// simulates when an alarm gets fired
- (void)handleNotificationFired:(UIConcreteLocalNotification *)notification;

// returns an alarm object from a given alarm Id
- (Alarm *)alarmWithId:(NSString *)alarmId;

// iOS 10 / iOS 11: the special sleep alarm (i.e. Bedtime alarm)
@property (nonatomic, readonly) Alarm *sleepAlarm;

@end

// data provider which lets us know which alarms have notifications scheduled
@interface SBClockDataProvider : NSObject

// the shared instance of the clock data provider
+ (id)sharedInstance;

// iOS 8: return all scheduled notifications that are held by the clock data provider
- (NSArray *)_scheduledNotifications;

// returns an alarm Id for a given notification
- (NSString *)_alarmIDFromNotification:(UIConcreteLocalNotification *)notification;

// iOS 10 / iOS 11: returns an alarm Id for a given notification request
- (NSString *)_alarmIDFromNotificationRequest:(UNNotificationRequest *)notificationRequest;

// lets us know whether or not a given notification is an alarm notification
// iOS 8 / iOS 9: argument is a UIConcreteLocalNotification object
// iOS 10 / iOS 11: argument is a UNNotification object
- (BOOL)_isAlarmNotification:(id)notification;

// iOS 10 / iOS 11: whether or not a given notification request is an alarm notification
- (BOOL)_isAlarmNotificationRequest:(UNNotificationRequest *)notificationRequest;

// iOS 8 / iOS 9: invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForLocalNotification:(UIConcreteLocalNotification *)notification;

// iOS 10 / iOS 11: invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForNotification:(id)notification;

@end

// iOS 9 / iOS 10 / iOS 11: manages the notifications for clocks and alarms
@interface SBClockNotificationManager : NSObject

// the shared instance of the notification manager
+ (id)sharedInstance;

// iOS 9: returns the array of scheduled local notifications
- (NSArray *)scheduledLocalNotifications;

// iOS 10 / iOS 11: returns pending notification request objects in the completion handler
- (void)getPendingNotificationRequestsWithCompletionHandler:(void (^)(NSArray<UNNotificationRequest *> *requests))completionHandler;

@end

// iOS 10 / iOS 11: the notification record object that gets fired when the user snoozes the alarm
@interface UNSNotificationRecord : NSObject

// user information attached to this notification record
@property (nonatomic, copy) NSDictionary *userInfo;

// the trigger date for the notification
@property (nonatomic, copy) NSDate *triggerDate;

// sets the trigger date for this notification
- (void)setTriggerDate:(NSDate *)date;

// returns whether or not this notification record is from a snooze action
- (BOOL)isFromSnooze;

@end

// iOS 10 / iOS 11: private legacy notification trigger object used for alarm notifications
@interface UNLegacyNotificationTrigger : UNNotificationTrigger

// returns the next trigger date after the specified date and default time zone
- (NSDate *)_nextTriggerDateAfterDate:(NSDate *)afterDate withRequestedDate:(NSDate *)requestedDate defaultTimeZone:(NSTimeZone *)defaultTimeZone;

@end

// iOS 10 / iOS 11: private implementation header for the notification content
@interface UNNotificationContent (Private)

// returns whether or not this notification content is from a snooze notification
- (BOOL)isFromSnooze;

@end