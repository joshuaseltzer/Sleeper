//
//  JSPickerTableViewController.h
//  Sleeper
//
//  Created by Joshua Seltzer on 9/24/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>

// forward delcare the view controller class so that we can define it in the delegate
@class JSPickerTableViewController;

// delegate that will notify the object that the picker times have been updated
@protocol JSPickerSelectionDelegate <NSObject>

// passes the updated picker times to the delegate
- (void)pickerTableViewController:(JSPickerTableViewController *)pickerTableViewController
               didUpdateWithHours:(NSInteger)hours
                          minutes:(NSInteger)minutes
                          seconds:(NSInteger)seconds;

@end

// custom view controller which presents the user with a time picker to pick hours, minutes, and
// seconds with a table view underneath
@interface JSPickerTableViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

// custom initialization method that sets the picker to the given times
- (id)initWithHours:(NSInteger)hours
            minutes:(NSInteger)minutes
            seconds:(NSInteger)seconds;

// move the time picker to the given hour, minute, and second values
- (void)changePickerTimeWithHours:(NSInteger)hours
                          minutes:(NSInteger)minutes
                          seconds:(NSInteger)seconds
                         animated:(BOOL)animated;

// the options table which will take up the rest of the view
@property (nonatomic, strong) UITableView *optionsTableView;

// the delegate of this view controller
@property (nonatomic, weak) id <JSPickerSelectionDelegate> delegate;

@end
