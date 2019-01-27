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

// forward delcare the view controller class so that we can define it in the delegate
@class SLHolidaySelectionTableViewController;

// delegate that will notify the object that holidays have been updated
@protocol SLHolidaySelectionDelegate <NSObject>

// passes the updated holiday holidays for the holiday country
- (void)SLHolidaySelectionTableViewController:(SLHolidaySelectionTableViewController *)holidaySelectionTableViewController
                            didUpdateHolidays:(NSArray *)holidays
                            forHolidayCountry:(SLHolidayCountry)holidayCountry;

@end

@interface SLHolidaySelectionTableViewController : UITableViewController

// initialize this controller the list of available holidays and the selection criteria
- (instancetype)initWithHolidays:(NSArray *)holidays forHolidayCountry:(SLHolidayCountry)holidayCountry;

// the delegate of this view controller
@property (nonatomic, weak) id <SLHolidaySelectionDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
