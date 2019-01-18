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

        // set the background color of the cell
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor clearColor];
        holidayCell.selectedBackgroundView = backgroundView;
        
    }

    // get the corresponding holiday for this cell for display
    NSDictionary *holiday = [self.holidays objectAtIndex:indexPath.row];
    holidayCell.textLabel.text = kSLHolidayNameString([holiday objectForKey:@"lz_key"]);
    [holidayCell setSelected:[[holiday objectForKey:@"selected"] boolValue] animated:NO];
    
    return holidayCell;
}

@end
