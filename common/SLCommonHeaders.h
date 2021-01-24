//
//  SLUserInterfaceHeaders.h
//  Contains all interfaces that are shared among the various components.
//
//  Created by Joshua Seltzer on 2/15/20.
//
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UNNotificationTrigger.h>
#import <UserNotifications/UNNotificationServiceExtension.h>
#import <UserNotifications/UNNotificationRequest.h>
#import <UserNotifications/UNNotificationContent.h>
#import <UserNotifications/UNNotification.h>

// iOS 8 / iOS 9: the notification that gets fired when the user decides to snooze an alarm
@interface UIConcreteLocalNotification : UILocalNotification

// returns a date for a given notification that will happen after a date in a given time zone
- (NSDate *)nextFireDateAfterDate:(NSDate *)date localTimeZone:(NSTimeZone *)timeZone;

@end

// legacy notification trigger object which is a subclass of a standard notification trigger
@interface UNLegacyNotificationTrigger : UNNotificationTrigger

// returns a date for a given notification that will happen after a date in a given time zone
- (NSDate *)_nextTriggerDateAfterDate:(NSDate *)date withRequestedDate:(NSDate *)requestedDate defaultTimeZone:(NSTimeZone *)timeZone;

@end

// additional details/content associated with a notification request
@interface UNNotificationContent (Private)

// iOS 10: determines whether or not the notification is from a snooze notification
- (BOOL)isFromSnooze;

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

// iOS 8 - iOS 11: the alarm object that contains all of the information about the alarm
@interface Alarm : NSObject

// iOS 8: the alarm Id corresponding to the alarm object
@property (readonly) NSString *alarmId;

// iOS 9 / iOS 10 / iOS 11: the alarm Id corresponding to the alarm object
@property (nonatomic, retain) NSString *alarmID;

// the display title of the alarm
@property (readonly, nonatomic) NSString *uiTitle;

// tells us if the given notification object was generated from a snooze notification (iOS 8 / iOS 9)
+ (BOOL)isSnoozeNotification:(UIConcreteLocalNotification *)notification;

// returns the next date that this alarm will fire
- (NSDate *)nextFireDate;

// simulates when an alarm gets fired
- (void)handleAlarmFired:(UIConcreteLocalNotification *)notification;

// iOS 10 / iOS 11: determines whether or not the alarm is the sleep/bedtime alarm
- (BOOL)isSleepAlarm;

// updates the hour property of the alarm
- (void)setHour:(NSUInteger)hour;

// updates the minute property of the alarm
- (void)setMinute:(NSUInteger)minute;

// whether or not the alarm is active
- (BOOL)isActive;

// populates the editing proxy for the alarm
- (void)prepareEditingProxy;

// returns the editing proxy for this alarm
- (Alarm *)editingProxy;

// applies any changes to the editing proxy to the alarm itself
- (void)applyChangesFromEditingProxy;

@end

// iOS 8 - iOS 11: manager that governs all alarms on the system
@interface AlarmManager : NSObject

// iOS 10 / iOS 11: the special sleep alarm (i.e. Bedtime alarm)
@property (nonatomic, readonly) Alarm *sleepAlarm;

// the shared alarm manager
+ (id)sharedManager;

// loads the alarms on the system in the manager object
- (void)loadAlarms;

// simulates when an alarm gets fired
- (void)handleNotificationFired:(UIConcreteLocalNotification *)notification;

// returns an alarm object from a given alarm Id
- (Alarm *)alarmWithId:(NSString *)alarmId;

// updates a given alarm
- (void)updateAlarm:(Alarm *)alarm active:(BOOL)active;

@end

// iOS 12+: the alarm object
@interface MTAlarm : NSObject

// the title of the alarm
@property (readonly, nonatomic) NSString *displayTitle;

// signifies whether or not this alarm is snozoed
@property (readonly, nonatomic, getter=isSnoozed) BOOL snoozed;

// updates the hour property of the alarm
- (void)setHour:(NSInteger)hour;

// updates the minute property of the alarm
- (void)setMinute:(NSInteger)minute;

// returns a string representation of the alarm Id
- (NSString *)alarmIDString;

// returns the next fire date for the alarm given a start date
- (NSDate *)nextFireDateAfterDate:(NSDate *)date includeBedtimeNotification:(BOOL)includeBedtimeNotification;

// indicates whether or not this is the special Bedtime / sleep alarm
- (BOOL)isSleepAlarm;

@end

// custom interface for added properties
@interface MTAlarm (Sleeper)

// flag which indicates whether or not the alarm was updated by this tweak or not
@property (nonatomic, assign) BOOL SLWasUpdatedBySleeper;

@end

// iOS 12+: an extension to the MTAlarm interface indicating an editable alarm
@interface MTMutableAlarm : MTAlarm
@end

// iOS 12+: the data source corresponding to a particular alarm
@interface MTAlarmDataSource : NSObject

// the sleep alarm that corresponds to the alarm data source object
@property (retain, nonatomic) MTAlarm *sleepAlarm;

@end

// manager that governs all alarms on the system (iOS 12 - iOS 14)
@interface MTAlarmManager : NSObject

// invoked when an alarm is saved
- (id)updateAlarm:(MTMutableAlarm *)mutableAlarm;

// returns an array of MTAlarm objects for the given date and 
- (NSArray *)nextAlarmsForDateSync:(NSDate *)date maxCount:(int)maxCount includeSleepAlarm:(BOOL)includeSleepAlarm includeBedtimeNotification:(BOOL)includeBedtimeNotification;

// returns an alarm object given the corresponding alarm Id string
- (MTAlarm *)alarmWithIDString:(NSString *)alarmId;

@end

// iOS 8 - iOS 11: data provider which lets us know which alarms have notifications scheduled
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