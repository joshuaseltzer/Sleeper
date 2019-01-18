//
//  SLEditDateViewController.h
//
//  Created by Joshua Seltzer on 1/3/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>

// define the height of the time picker view
#define kSLEditDatePickerViewHeight             216.0

// define the segue from the storyboard to show this controller
#define kSLEditDateSegue                        @"SLEditDateSegue"

// delegate for the edit date controller
@protocol SLEditDateViewControllerDelegate <NSObject>

// notify the delegate that the date was updated
- (void)dateUpdated:(NSDate *)date;

@end

// customized view controller which simply contains a date picker view
@interface SLEditDateViewController : UIViewController

// initialize this controller with an optional initial date
- (instancetype)initWithInitialDate:(NSDate *)initialDate;

// the delegate of this view controller
@property (nonatomic, weak) id delegate;

@end
