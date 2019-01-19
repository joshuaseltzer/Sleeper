//
//  SLSkipDatesViewController.h
//
//  Created by Joshua Seltzer on 1/2/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLEditDateViewController.h"

NS_ASSUME_NONNULL_BEGIN

// forward delcare the view controller class so that we can define it in the delegate
@class SLSkipDatesViewController;

// delegate that will notify the object that skip dates have been updated
@protocol SLSkipDatesDelegate <NSObject>

// passes the updated picker times to the delegate
- (void)SLSkipDatesViewController:(SLSkipDatesViewController *)skipDatesViewController
         didUpdateCustomSkipDates:(NSArray *)customSkipDates
                 holidaySkipDates:(NSDictionary *)holidaySkipDates;

@end

@interface SLSkipDatesViewController : UITableViewController <SLEditDateViewControllerDelegate, UIViewControllerTransitioningDelegate>

// initialize this controller with optional custom skip dates and holiday skip dates
- (instancetype)initWithCustomSkipDates:(NSArray *)customSkipDates holidaySkipDates:(NSDictionary *)holidaySkipDates;

// the delegate of this view controller
@property (nonatomic, weak) id <SLSkipDatesDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
