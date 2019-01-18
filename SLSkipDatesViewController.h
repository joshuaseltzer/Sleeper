//
//  SLSkipDatesViewController.h
//
//  Created by Joshua Seltzer on 1/2/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLEditDateViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLSkipDatesViewController : UITableViewController <SLEditDateViewControllerDelegate, UIViewControllerTransitioningDelegate>

// initialize this controller with optional custom skip dates and holiday skip dates
- (instancetype)initWithCustomSkipDates:(NSArray *)customSkipDates holidaySkipDates:(NSDictionary *)holidaySkipDates;

@end

NS_ASSUME_NONNULL_END
