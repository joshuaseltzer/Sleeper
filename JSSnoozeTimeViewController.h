//
//  JSSnoozeTimeViewController.h
//  Sleeper
//
//  Created by Joshua Seltzer on 10/12/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "JSPickerTableViewController.h"

// view controller which will return the user's selected snooze time and also present an option
// in the table to reset the default snooze time
@interface JSSnoozeTimeViewController : JSPickerTableViewController <UITableViewDataSource, UITableViewDelegate>

@end
