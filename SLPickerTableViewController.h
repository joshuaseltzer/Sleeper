//
//  SLPickerTableViewController.h
//  Custom view controller with a time picker (hours, minutes, and seconds) on top with a table view on the bottom.
//
//  Created by Joshua Seltzer on 9/24/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

// forward delcare the view controller class so that we can define it in the delegate
@class SLPickerTableViewController;

// delegate that will notify the object that the picker times have been updated
@protocol SLPickerSelectionDelegate <NSObject>

// passes the updated picker times to the delegate
- (void)SLPickerTableViewController:(SLPickerTableViewController *)pickerTableViewController
                 didUpdateWithHours:(NSInteger)hours
                            minutes:(NSInteger)minutes
                            seconds:(NSInteger)seconds;

@end

@interface SLPickerTableViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

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
@property (nonatomic, weak) id <SLPickerSelectionDelegate> delegate;

@end
