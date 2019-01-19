//
//  SLHolidaySelectionTableViewController.m
//  sleeper-test
//
//  Created by Joshua Seltzer on 1/12/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLHolidaySelectionTableViewController.h"
#import "SLSkipDatesViewController.h"
#import "SLCompatibilityHelper.h"
#import "SLLocalizedStrings.h"

// define the reuse identifier for the cells in this table
#define kSLHolidayTableViewCellIdentifier               @"SLHolidayTableViewCell"

@interface SLHolidaySelectionTableViewController ()

// the holiday objects that this controller is responsible for displaying
@property (nonatomic, strong) NSMutableArray *holidays;

// the holiday country that this selection controller is displaying
@property (nonatomic) SLHolidayCountry holidayCountry;

@end

@implementation SLHolidaySelectionTableViewController

// initialize this controller the list of available holidays and the selection criteria
- (instancetype)initWithHolidays:(NSMutableArray *)holidays forHolidayCountry:(SLHolidayCountry)holidayCountry
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.holidays = holidays;
        self.holidayCountry = holidayCountry;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // customize the view controller and table
    self.title = [SLPrefsManager friendlyNameForCountry:self.holidayCountry];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self setEditing:YES animated:NO];

    // create a clear button to clear all selections
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:kSLClearString
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(clearButtonPressed:)];
    self.navigationItem.rightBarButtonItem = clearButton;
}

// invoked when the user presses the clear button
- (void)clearButtonPressed:(UIBarButtonItem *)clearButton
{
    // change all of the holidays/cells that were previously selected
    NSMutableArray *indexPathsToReload = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.holidays.count; i++) {
        NSMutableDictionary *holiday = [self.holidays objectAtIndex:i];
        if ([[holiday objectForKey:kSLHolidaySelectedKey] boolValue]) {
            [holiday setObject:[NSNumber numberWithBool:NO] forKey:kSLHolidaySelectedKey];
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.holidays.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue the cell and create one if needed
    UITableViewCell *holidayCell = [tableView dequeueReusableCellWithIdentifier:kSLHolidayTableViewCellIdentifier];
    if (holidayCell == nil) {
        holidayCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                             reuseIdentifier:kSLHolidayTableViewCellIdentifier];
        holidayCell.accessoryType = UITableViewCellAccessoryNone;
        holidayCell.textLabel.textAlignment = NSTextAlignmentLeft;
        holidayCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];

        // set the background color of the cell to clear to remove the selection color
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor clearColor];
        holidayCell.selectedBackgroundView = backgroundView;
    }

    // get the corresponding holiday for this cell for display
    NSDictionary *holiday = [self.holidays objectAtIndex:indexPath.row];
    holidayCell.textLabel.text = kSLHolidayNameString([holiday objectForKey:kSLHolidayLocalizationNameKey]);
    
    return holidayCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // set the selection for this cell if it should be selected
    NSDictionary *holiday = [self.holidays objectAtIndex:indexPath.row];
    if ([[holiday objectForKey:kSLHolidaySelectedKey] boolValue]) {
        [cell setSelected:YES animated:NO];
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

// handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // modify the selection flag for the selected row
    NSMutableDictionary *holiday = [self.holidays objectAtIndex:indexPath.row];
    [holiday setObject:[NSNumber numberWithBool:![[holiday objectForKey:kSLHolidaySelectedKey] boolValue]] forKey:kSLHolidaySelectedKey];
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // modify the selection flag for the selected row
    NSMutableDictionary *holiday = [self.holidays objectAtIndex:indexPath.row];
    [holiday setObject:[NSNumber numberWithBool:![[holiday objectForKey:kSLHolidaySelectedKey] boolValue]] forKey:kSLHolidaySelectedKey];
}

@end
