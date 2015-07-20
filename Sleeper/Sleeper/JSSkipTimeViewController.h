//
//  JSSkipTimeViewController.h
//  Sleeper
//
//  Created by Joshua Seltzer on 7/19/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>

// delegate that tells the parent view controller to update the alarm with the skip time
@protocol JSSkipTimeDelegate <NSObject>

// passes the updated skip time to the delegate
- (void)alarmDidUpdateWithSkipHours:(NSInteger)skipHours;

@end

// table view controller which presents the user with different options to select a skip time
@interface JSSkipTimeViewController : UITableViewController

// custom initialization method that sets the default hours
- (id)initWithHours:(NSInteger)hours;

// the delegate of this view controller
@property (nonatomic, weak) id <JSSkipTimeDelegate> delegate;

@end
