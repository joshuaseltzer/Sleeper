//
//  AppleInterfaces.h
//  Contains all interfaces as defined by Apple that are utilized in the hooking code.
//
//  Created by Joshua Seltzer on 12/11/14.
//
//

#import "Sleeper/Sleeper/JSSnoozeTimeViewController.h"
#import "Sleeper/Sleeper/JSSkipTimeViewController.h"

// the notification that gets fired when the user decides to snooze an alarm
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

// ignore UIAlertView deprecations
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

// a system alert item that we will subclass to create our own alert with
@interface SBAlertItem : NSObject <UIAlertViewDelegate>

// the alert view object that corresponds to this alert item
- (UIAlertView *)alertSheet;

// allows us to set up the alert view
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode;

// delegate method that is invoked when a button is clicked from the alert
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)index;

// dismisses the alert item
- (void)dismiss;

@end

#pragma clang diagnostic pop

// the controller responsible for activating and displaying system alert items
@interface SBAlertItemsController : UIViewController

// the shared instance of this controller
+ (id)sharedInstance;

// activates (i.e. displays) an alert item to the user
- (void)activateAlertItem:(SBAlertItem *)alertItem;

@end

// data provider which lets us know which alarms have notifications scheduled
@interface SBClockDataProvider : NSObject

// the shared instance of the clock data provider
+ (id)sharedInstance;

// iOS8: return all scheduled notifications that are held by the clock data provider
- (NSArray *)_scheduledNotifications;

// returns an alarm Id for a given notifications
- (NSString *)_alarmIDFromNotification:(UIConcreteLocalNotification *)notification;

// lets us know whether or not a given notification is an alarm notification
- (BOOL)_isAlarmNotification:(UIConcreteLocalNotification *)notification;

// invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForLocalNotification:(UIConcreteLocalNotification *)notification;

@end

// iOS9: manages the notifications for clocks and alarms
@interface SBClockNotificationManager : NSObject

// the shared instance of the notification manager
+ (id)sharedInstance;

// returns the array of scheduled local notifications
- (NSArray *)scheduledLocalNotifications;

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