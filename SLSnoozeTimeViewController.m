//
//  SLSnoozeTimeViewController.m
//  Customized picker table view controller for selecting the snooze time.
//
//  Created by Joshua Seltzer on 10/12/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "SLSnoozeTimeViewController.h"
#import "SLPrefsManager.h"
#import "SLLocalizedStrings.h"
#import "SLCompatibilityHelper.h"

@implementation SLSnoozeTimeViewController

// override to customize the view upon load
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title of the view controller
    self.title = kSLSnoozeTimeString;
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

        // on newer versions of iOS, we need to set the background views for the cell
        if (kSLSystemVersioniOS13) {
            cell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];
        }
        if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11 || kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
            cell.selectedBackgroundView = backgroundView;
        }
    }
    
    // customize the cell
    cell.textLabel.text = kSLResetDefaultString;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    // set the color of the button to the red, destructive color as defined by Apple in other cells
    cell.textLabel.textColor = [SLCompatibilityHelper destructiveLabelColor];
    
    return cell;
}

// return a footer view for each table view section
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // We only have one section which defines the default snooze button.  Display a message indicating
    // to the user what the default snooze time is
    NSString *defaultSnoozeTime = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)kSLDefaultSnoozeHour,
                                   (long)kSLDefaultSnoozeMinute, (long)kSLDefaultSnoozeSecond];
    return kSLDefaultSnoozeTimeString(defaultSnoozeTime);
}

#pragma mark - UITableViewDelegate

// handle table view cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // for now, we only have one button so we can assume it is the one that resets the default snooze
    // picker values
    [self changePickerTimeWithHours:kSLDefaultSnoozeHour
                            minutes:kSLDefaultSnoozeMinute
                            seconds:kSLDefaultSnoozeSecond
                           animated:YES];
    
    // deselect the row with animation
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
