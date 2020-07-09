//
//  SLAutoSetOptionsTableViewController.h
//  Table view controller that presents the user with various options to configure the timer to automatically be set.
//
//  Created by Joshua Seltzer on 7/1/20.
//  Copyright © 2020 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLEditDateTimeViewController.h"
#import "../../common/SLPrefsManager.h"

NS_ASSUME_NONNULL_BEGIN

// forward delcare the view controller class so that we can define it in the delegate
@class SLAutoSetOptionsTableViewController;

// delegate that will notify the object that holidays have been updated
@protocol SLAutoSetOptionsDelegate <NSObject>

// passes the updated auto-set selection and options to the delegate
- (void)SLAutoSetOptionsTableViewController:(SLAutoSetOptionsTableViewController *)autoSetOptionsTableViewController
                     didUpdateAutoSetOption:(SLAutoSetOption)autoSetOption
                    withAutoSetOffsetOption:(SLAutoSetOffsetOption)autoSetOffsetOption
                      withAutoSetOffsetHour:(NSInteger)autoSetOffsetHour
                    withAutoSetOffsetMinute:(NSInteger)autoSetOffsetMinute;

@end

@interface SLAutoSetOptionsTableViewController : UITableViewController <SLEditDateTimeViewControllerDelegate, UIViewControllerTransitioningDelegate>

// initialize this controller with the selected auto-set settings
- (instancetype)initWithAutoSetOption:(SLAutoSetOption)autoSetOption
                  autoSetOffsetOption:(SLAutoSetOffsetOption)autoSetOffsetOption
                    autoSetOffsetHour:(NSInteger)autoSetOffsetHour
                  autoSetOffsetMinute:(NSInteger)autoSetOffsetMinute;

// the delegate of this view controller
@property (nonatomic, weak) id <SLAutoSetOptionsDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
