//
//  SLHolidaySelectionTableViewController.h
//  Table view controller that allows the user to pick from a list of holidays.
//
//  Created by Joshua Seltzer on 1/12/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../common/SLPrefsManager.h"

NS_ASSUME_NONNULL_BEGIN

// forward delcare the view controller class so that we can define it in the delegate
@class SLHolidaySelectionTableViewController;

// delegate that will notify the object that holidays have been updated
@protocol SLHolidaySelectionDelegate <NSObject>

// passes the updated holiday selections for the holiday country
- (void)SLHolidaySelectionTableViewController:(SLHolidaySelectionTableViewController *)holidaySelectionTableViewController
                    didUpdateSelectedHolidays:(NSArray *)selectedHolidays
                            forHolidayCountry:(SLHolidayCountry)holidayCountry;

@end

@interface SLHolidaySelectionTableViewController : UITableViewController

// initialize this controller with the selected holidays and available holidays for a given holiday country
- (instancetype)initWithSelectedHolidays:(NSArray *)selectedHolidays holidayResource:(NSDictionary *)holidayResource inHolidayCountry:(SLHolidayCountry)holidayCountry;

// the delegate of this view controller
@property (nonatomic, weak) id <SLHolidaySelectionDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
