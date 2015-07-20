//
//  AppleInterfaces.h
//  Contains all interfaces as defined by Apple that are utilized in the hooking code.
//
//  Created by Joshua Seltzer on 12/11/14.
//
//

// the alarm object that contains all of the information about the alarm
@interface Alarm : NSObject

@property BOOL allowsSnooze;
@property (readonly) NSString *alarmId;

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
@interface UIConcreteLocalNotification : UILocalNotification {
    NSDate *fireDate;
}

@end

// manager that governs all alarms on the system
@interface AlarmManager : NSObject

- (void)removeAlarm:(Alarm *)alarm;

@end