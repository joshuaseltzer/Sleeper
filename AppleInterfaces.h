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

// the alarm Id corresponding to the alarm object
@property (readonly) NSString *alarmId;

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
JSSnoozeTimeDelegate, JSSkipTimeDelegate>

// the alarm object associated with the controller
@property (readonly, assign, nonatomic) Alarm* alarm;

@end

// manager that governs all alarms on the system
@interface AlarmManager : NSObject

// the shared alarm manager
+ (id)sharedManager;

// loads the alarms on the system in the manager object
- (void)loadAlarms;

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

// the controller responsible for activating and displaying system alert items
@interface SBAlertItemsController : UIViewController

// the shared instance of this controller
+ (id)sharedInstance;

// activates (i.e. displays) an alert item to the user
- (void)activateAlertItem:(SBAlertItem *)alertItem;

@end

// data provider which lets us know which alarms have notifications scheduled
@interface SBClockDataProvider : NSObject {
    // next alarm notifications that we will use to see if an alarm is scheduled
    UIConcreteLocalNotification* _nextAlarmForToday;
    UIConcreteLocalNotification* _firstAlarmForTomorrow;
}

// the shared instance of the clock data provider
+ (id)sharedInstance;

// returns an alarm Id for a given notifications
- (NSString *)_alarmIDFromNotification:(UIConcreteLocalNotification *)notification;

// lets us know whether or not a given notification is an alarm notification
- (BOOL)_isAlarmNotification:(UIConcreteLocalNotification *)notification;

// invoked when an alarm alert (i.e. bulletin) is about to be displayed
- (void)_publishBulletinForLocalNotification:(UIConcreteLocalNotification *)notification;

@end