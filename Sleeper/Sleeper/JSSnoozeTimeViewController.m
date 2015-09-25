//
//  JSSnoozeTimeViewController.m
//  Sleeper
//
//  Created by Joshua Seltzer on 10/12/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "JSSnoozeTimeViewController.h"
#import "JSPrefsManager.h"
#import "JSLocalizedStrings.h"

@implementation JSSnoozeTimeViewController

// override to customize the view upon load
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title of the view controller
    self.title = LZ_SNOOZE_TIME;
}

#pragma mark - UITableViewDataSource

// returns the number of sections for a table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// returns the number of rows for a table view
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

// returns a cell for a table at an index path
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // create an identifier for our table view cell
    static NSString *const optionTableButtonCellIdentifier = @"optionTableButtonCellIdentifier";
    
    // attempt to dequeue the cell from the table
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:optionTableButtonCellIdentifier];
    
    // if the cell doesn't exist yet, create a new one
    if (!cell) {
        // create a new default cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:optionTableButtonCellIdentifier];
    }
    
    // customize the cell text and alignment
    cell.textLabel.text = LZ_RESET_DEFAULT;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    // set the color of the button to the red, destructive color as defined by Apple in other cells
    cell.textLabel.textColor = [UIColor colorWithRed:1.0f
                                               green:0.231373f
                                                blue:0.188235f
                                               alpha:1.0f];
    
    return cell;
}

// return a footer view for each table view section
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // We only have one section which defines the default snooze button.  Display a message indicating
    // to the user what the default snooze time is
    NSString *defaultSnoozeTime = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)kJSDefaultSnoozeHour,
                                   (long)kJSDefaultSnoozeMinute, (long)kJSDefaultSnoozeSecond];
    return LZ_DEFAULT_SNOOZE_TIME(defaultSnoozeTime);
}

#pragma mark - UITableViewDelegate

// handle table view cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // for now, we only have one button so we can assume it is the one that resets the default snooze
    // picker values
    [self changePickerTimeWithHours:kJSDefaultSnoozeHour
                            minutes:kJSDefaultSnoozeMinute
                            seconds:kJSDefaultSnoozeSecond
                           animated:YES];
    
    // deselect the row with animation
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
