//
//  JSSnoozeTimeViewController.h
//  Sleeper
//
//  Created by Joshua Seltzer on 10/12/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>

// delegate that tells the parent view controller to update the alarm with the given times
@protocol JSSnoozeTimeDelegate <NSObject>

// passes the updated snooze time to the delegate
- (void)alarmDidUpdateWithSnoozeHours:(NSInteger)snoozeHours
                        snoozeMinutes:(NSInteger)snoozeMinutes
                        snoozeSeconds:(NSInteger)snoozeSeconds;

@end

// custom view controller which presents the user with a time picker to pick the snooze time along with
// a table view for additional options
@interface JSSnoozeTimeViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource,
UITableViewDataSource, UITableViewDelegate>

// custom initialization method that sets the picker to the given times
- (id)initWithHours:(NSInteger)hours
            minutes:(NSInteger)minutes
            seconds:(NSInteger)seconds;

// the delegate of this view controller
@property (nonatomic, weak) id <JSSnoozeTimeDelegate> delegate;

@end
