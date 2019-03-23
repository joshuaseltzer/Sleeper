//
//  SLSkipAlarmAlertItem.h
//  Custom system alert item to ask the user if he or she would like to skip a given alarm.
//
//  Created by Joshua Seltzer on 8/9/15.
//
//

#import "../SLAppleSharedInterfaces.h"

// a system alert item
@interface SBAlertItem : NSObject

// the alert controlelr object that corresponds to this alert item
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

// activates/displays an alert item to the user
- (void)activateAlertItem:(SBAlertItem *)alertItem animated:(BOOL)animated;

@end

// system alert for skipping alarms
@interface SLSkipAlarmAlertItem : SBAlertItem

// create a new alert item with a given title, alarmId, and next fire date
- (id)initWithTitle:(NSString *)title alarmId:(NSString *)alarmId nextFireDate:(NSDate *)nextFireDate;

@end