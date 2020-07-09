//
//  SLEditDateTimeViewController.h
//
//  Created by Joshua Seltzer on 1/3/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>

// forward delcare the view controller class so that we can define it in the delegate
@class SLEditDateTimeViewController;

// define the height of the picker view
#define kSLEditDateTimePickerViewHeight         216.0

// delegate for this controller
@protocol SLEditDateTimeViewControllerDelegate <NSObject>

// all methods are optional since the delegate methods that are called will differ depending on which type of data is being edited
@optional

// notify the delegate that the date was saved
- (void)SLEditDateTimeViewController:(SLEditDateTimeViewController *)editDateTimeViewController didSaveDate:(NSDate *)date;

// notify the delegate that the hours/minutes were saved
- (void)SLEditDateTimeViewController:(SLEditDateTimeViewController *)editDateTimeViewController didSaveHours:(NSInteger)hours andMinutes:(NSInteger)minutes;

// notify the delegate that the selection was cancelled
- (void)SLEditDateTimeViewControllerDidCancelSelection:(SLEditDateTimeViewController *)editDateTimeViewController;

@end

// customized view controller which simply contains a date or time picker view
@interface SLEditDateTimeViewController : UIViewController

// Initialize this controller with a required title and optional dates.  Using this initilizer will put the picker in date mode.
- (instancetype)initWithTitle:(NSString *)title initialDate:(NSDate *)initialDate minimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate;

// Initialize this controller with a required title and optional hour/minutes.  Using this initilizer will put the picker in countdown timer mode.
- (instancetype)initWithTitle:(NSString *)title initialHours:(NSInteger)initialHours initialMinutes:(NSInteger)initialMinutes maximumHours:(NSInteger)maximumHours maximumMinutes:(NSInteger)maximumMinutes;

// the delegate of this view controller
@property (nonatomic, weak) id <SLEditDateTimeViewControllerDelegate> delegate;

@end
