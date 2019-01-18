//
//  SLHolidaySelectionTableViewController.h
//  sleeper-test
//
//  Created by Joshua Seltzer on 1/12/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLPrefsManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLHolidaySelectionTableViewController : UITableViewController

// initialize this controller the list of available holidays and the selection criteria
- (instancetype)initWithHolidays:(NSMutableArray *)holidays forHolidayCountry:(SLHolidayCountry)holidayCountry;

@end

NS_ASSUME_NONNULL_END
