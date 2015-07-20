//
//  JSSkipTimeViewController.m
//  Sleeper
//
//  Created by Joshua Seltzer on 7/19/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

#import "JSSkipTimeViewController.h"
#import "JSLocalizedStrings.h"

@implementation JSSkipTimeViewController

// static variable to define the initial value of the skip time
static NSInteger sJSSelectedHours;

// custom initialization method that sets the default hours
- (id)initWithHours:(NSInteger)hours
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // save the initial time
        sJSSelectedHours = hours;
    }
    return self;
}

// override to customize the view upon load
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title of the view controller
    self.title = LZ_SKIP_TIME;
}

// invoked when the given view is moving to the parent view controller
- (void)willMoveToParentViewController:(UIViewController *)parent
{
    // if the parent is nil, we know we are popping this view controller
    if (!parent && self.delegate) {
        // tell the delegate about the updated skip times
        [self.delegate alarmDidUpdateWithSkipHours:sJSSelectedHours];
    }
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
    return 6;
}

// returns a cell for a table at an index path
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // create an identifier for our table view cell
    static NSString *const skipHourCellIdentifier = @"skipHourCellIdentifier";
    
    // attempt to dequeue the cell from the table
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:skipHourCellIdentifier];
    
    // if the cell doesn't exist yet, create a new one
    if (!cell) {
        // create a new default cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:skipHourCellIdentifier];
    }
    
    // customize the cell text
    NSString *hourString = nil;
    if (indexPath.row == 0) {
        hourString = LZ_HOUR;
    } else {
        hourString = LZ_HOURS;
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%ld %@", (long)indexPath.row + 1, hourString];
    
    // set the checkmark to the selected row for the selected skip time or disabled if not
    if (indexPath.row + 1 == sJSSelectedHours) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

// handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // create the indexpath for the previously selected row
    NSIndexPath *previousSelection = [NSIndexPath indexPathForRow:sJSSelectedHours - 1
                                                        inSection:0];
    
    // if the selected cell is not the previously cell, then reload both the old and new cells
    if (previousSelection != indexPath) {
        // set our selected row variable to the newly selected row
        sJSSelectedHours = indexPath.row + 1;
        
        // reload the cell that was selected
        [self.tableView reloadRowsAtIndexPaths:@[previousSelection, indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        // otherwise, animate the deselection of the cell
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
