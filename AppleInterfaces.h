//
//  AppleInterfaces.h
//  Contains all interfaces as defined by Apple that are utilized in the hooking code.
//
//  Created by Joshua Seltzer on 12/11/14.
//
//

#import "Sleeper/Sleeper/JSSnoozeTimeViewController.h"
#import "Sleeper/Sleeper/JSSkipTimeViewController.h"

@interface AppController : UIApplication {
    UIViewController *_alarmViewController;
}
@end

@interface AlarmViewController : UIViewController
@end

// the alarm object that contains all of the information about the alarm
@interface Alarm : NSObject

@property BOOL allowsSnooze;
@property (readonly) NSString *alarmId;
@property(readonly, nonatomic, getter=isActive) BOOL active;
@property(readonly, nonatomic) Alarm *editingProxy;
@property(readonly, nonatomic) NSDictionary *settings;

// returns the next date that this alarm will fire
- (NSDate *)nextFireDate;

- (void)refreshActiveState;
- (void)prepareEditingProxy;
- (BOOL)isActive;
- (void)handleAlarmFired:(id)arg1;
- (unsigned int)_notificationsCount;
- (void)dropNotifications;
- (void)cancelNotifications;
- (void)scheduleNotifications;
- (void)prepareNotifications;

@end

// the custom cell used to display information when editing an alarm
@interface MoreInfoTableViewCell : UITableViewCell

@property(retain, nonatomic) NSString* _contentString;

@end

// the custom view in the edit alarm view controller that contains the table of buttons
@interface EditAlarmView : UIView

@property(readonly, assign, nonatomic) UITableView* settingsTable;

@end

// The primary view controller which recieves the ability to edit the snooze time.  This view controller
// conforms to custom delegates that are used to notify when alarm attributes change
@interface EditAlarmViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
JSSnoozeTimeDelegate, JSSkipTimeDelegate> {
    EditAlarmView* _editAlarmView;
}

@property(readonly, assign, nonatomic) Alarm* alarm;

@end

// the notification that gets fired when the user decides to snooze an alarm
@interface UIConcreteLocalNotification : UILocalNotification

- (int)remainingRepeatCount;

@end

// manager that governs all alarms on the system
@interface AlarmManager : NSObject

@property(readonly, retain, nonatomic) NSArray *alarms;

// invoked when an alarm is removed
- (void)removeAlarm:(Alarm *)alarm;

// loads the alarms on the system in the manager object
- (void)loadAlarms;
- (void)loadScheduledNotifications;
- (void)setAlarm:(Alarm *)alarm active:(BOOL)active;
- (void)updateAlarm:(Alarm *)alarm active:(BOOL)active;
- (Alarm *)nextAlarmForDate:(NSDate *)arg1 activeOnly:(BOOL)arg2 allowRepeating:(BOOL)arg3;
- (void)handleNotificationFired:(id)arg1;
+ (BOOL)isAlarmNotification:(id)arg1;
- (void)handleAnyNotificationChanges;

- (id)alarmWithId:(id)arg1;

// the shared alarm manager
+ (AlarmManager *)sharedManager;

@end

@interface ClockManager : NSObject

+ (id)sharedManager;
+ (void)loadUserPreferences;
- (void)refreshScheduledLocalNotificationsCache;

@property(readonly, nonatomic) NSArray *scheduledLocalNotificationsCache;

@end

// the view controller that controls the lock screen
@interface SBLockScreenViewController : UIViewController

// override to display a pop up allowing the user to skip an alarm
- (void)finishUIUnlockFromSource:(int)source;

@end

@interface SBAlertItem : NSObject <UIAlertViewDelegate> {
    UIAlertView *_alertSheet;
}

- (id)init;
- (UIAlertView *)alertSheet;
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)index;
- (void)dismiss;

@end

@interface SBAlertItemsController : UIViewController

+ (id)sharedInstance;
- (void)activateAlertItem:(id)item;

@end

@interface SBApplication : NSObject

-(void)cancelLocalNotification:(id)notification;
-(NSArray *)scheduledLocalNotifications;

@end

@interface SBApplicationController : NSObject

+(id)sharedInstance;
-(SBApplication *)applicationWithBundleIdentifier:(id)bundleIdentifier;

@end