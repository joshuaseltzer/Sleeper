//
//  AppleInterfaces.h
//  Contains all interfaces as defined by Apple that are utilized in the hooking code.
//
//  Created by Joshua Seltzer on 12/11/14.
//
//

@import UserNotifications;
#import "JSSnoozeTimeViewController.h"
#import "JSSkipTimeViewController.h"

// the notification that gets fired when the user decides to snooze an alarm (iOS8/iOS9)
@interface UIConcreteLocalNotification : UILocalNotification

// returns a date for a given notification that will happen after a date in a given time zone
- (NSDate *)nextFireDateAfterDate:(NSDate *)date localTimeZone:(NSTimeZone *)timeZone;

@end

// the alarm object that contains all of the information about the alarm
@interface Alarm : NSObject

// tells us if the given notification object was generated from a snooze notification
+ (BOOL)isSnoozeNotification:(UIConcreteLocalNotification *)notification;

// iOS8: the alarm Id corresponding to the alarm object
@property (readonly) NSString *alarmId;

// iOS9: the alarm Id corresponding to the alarm object
@property (nonatomic, retain) NSString *alarmID;

// the display title of the alarm
@property (readonly, nonatomic) NSString *uiTitle;

// returns the next date that this alarm will fire
- (NSDate *)nextFireDate;

// simulates when an alarm gets fired
- (void)handleAlarmFired:(UIConcreteLocalNotification *)notification;

@end

// the custom cell used to display information when editing an alarm
@interface MoreInfoTableViewCell : UITableViewCell
@end

// The primary view controller which recieves the ability to edit the snooze time.  This view controller
// conforms to custom delegates that are used to notify when alarm attributes change.
@interface EditAlarmViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
JSPickerSelectionDelegate>

// the alarm object associated with the controller
@property (readonly, assign, nonatomic) Alarm* alarm;

// override to make sure we forget the saved alarm Id when the user leaves this view
- (void)_cancelButtonClicked:(UIButton *)cancelButton;

// override to make sure we forget the saved alarm Id when the user leaves this view
- (void)_doneButtonClicked:(UIButton *)doneButton;

@end

// manager that governs all alarms on the system
@interface AlarmManager : NSObject

// the shared alarm manager
+ (id)sharedManager;

// loads the alarms on the system in the manager object
- (void)loadAlarms;

// override to save the properties for the given alarm
- (void)updateAlarm:(Alarm *)alarm active:(BOOL)active;

// override to remove snooze times for the given alarm from our preferences
- (void)removeAlarm:(Alarm *)alarm;

// invoked when an alarm is set or unset with an active states
- (void)setAlarm:(Alarm *)alarm active:(BOOL)active;

// simulates when an alarm gets fired
- (void)handleNotificationFired:(UIConcreteLocalNotification *)notification;

// returns an alarm object from a given alarm Id
- (Alarm *)alarmWithId:(NSString *)alarmId;

@end

// the view controller that controls the lock screen
@interface SBLockScreenViewController : UIViewController

// override to display a pop up allowing the user to skip an alarm
- (void)finishUIUnlockFromSource:(int)source;

@end

// a system alert item that we will subclass to create our own alert with
@interface SBAlertItem : NSObject

// the alert controlelr object that corresponds to this alert item (>iOS10)
- (UIAlertController *)alertController;

// allows us to set up the alert view or alert controller
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode;

// dismisses the alert item
- (void)dismiss;

@end

// the controller responsible for activating and displaying system alert items
@interface SBAlertItemsController : UIViewController

// the shared instance of this controller
+ (id)sharedInstance;

// activates (i.e. displays) an alert item to the user
- (void)activateAlertItem:(SBAlertItem *)alertItem animated:(BOOL)animated;

@end

// data provider which lets us know which alarms have notifications scheduled
@interface SBClockDataProvider : NSObject

// the shared instance of the clock data provider
+ (id)sharedInstance;

// iOS8: return all scheduled notifications that are held by the clock data provider
- (NSArray *)_scheduledNotifications;

// returns an alarm Id for a given notification
- (NSString *)_alarmIDFromNotification:(UIConcreteLocalNotification *)notification;

// iOS10: returns an alarm Id for a given notification request
- (NSString *)_alarmIDFromNotificationRequest:(UNNotificationRequest *)notificationRequest;

// lets us know whether or not a given notification is an alarm notification
// iOS8/iOS9: argument is a UIConcreteLocalNotification object
// iOS10: argument is a UNNotification object
- (BOOL)_isAlarmNotification:(id)notification;

// iOS10: lets us kow whether or not a given notification request is an alarm notification
- (BOOL)_isAlarmNotificationRequest:(UNNotificationRequest *)notificationRequest;

// iOS9: invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForLocalNotification:(UIConcreteLocalNotification *)notification;

// iOS10: invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForNotification:(id)notification;

@end

// iOS9/iOS10: manages the notifications for clocks and alarms
@interface SBClockNotificationManager : NSObject

// the shared instance of the notification manager
+ (id)sharedInstance;

// returns the array of scheduled local notifications (iOS8/iOS9)
- (NSArray *)scheduledLocalNotifications;

// returns pending notification request objects in the completion handler (iOS10)
- (void)getPendingNotificationRequestsWithCompletionHandler:(void (^)(NSArray<UNNotificationRequest *> *requests))completionHandler;

@end

// iOS8: handles the snoozing of local notifications (i.e. alarms)
@interface SBApplication : NSObject

// override to insert our custom snooze time if it was defined
- (void)scheduleSnoozeNotification:(UIConcreteLocalNotification *)notification;

@end

// iOS9: handles the snoozing of local notifications (i.e. alarms)
@interface UNLocalNotificationClient : NSObject

// invoked when the user snoozes a notification
- (void)scheduleSnoozeNotification:(UIConcreteLocalNotification *)notification;

@end

// the notification record object that gets fired when the user snoozes the alarm (iOS10)
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

// iOS10: private legacy notification trigger object used for alarm notifications
@interface UNLegacyNotificationTrigger : UNNotificationTrigger

// returns the next trigger date after the specified date and default time zone
- (NSDate *)_nextTriggerDateAfterDate:(NSDate *)afterDate withRequestedDate:(NSDate *)requestedDate defaultTimeZone:(NSTimeZone *)defaultTimeZone;

@end

// iOS10: private implementation header for the notification content
@interface UNNotificationContent (Private)

// returns whether or not this notification content is from a snooze notification
- (BOOL)isFromSnooze;

@end