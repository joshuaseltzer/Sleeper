//
//  SLHolidaySelectionTableViewController.m
//  Table view controller that allows the user to pick from a list of holidays.
//
//  Created by Joshua Seltzer on 1/12/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLHolidaySelectionTableViewController.h"
#import "SLSkipDatesViewController.h"
#import "../../common/SLCompatibilityHelper.h"
#import "../../common/SLLocalizedStrings.h"

// define the reuse identifier for the cells in this table
#define kSLHolidayTableViewCellIdentifier               @"SLHolidayTableViewCell"

// define some of the sizes of the components of this cell to help calculate the height of the cell
#define kSLHolidayTableViewCellEditControlWidth         38.0
#define kSLHolidayTableViewCellLabelVerticalPadding     8.0
#define kSLHolidayTableViewCellLabelHorizontalPadding   16.0
#define kSLHolidayTableViewCellDetailLabelHeight        15.0
#define kSLHolidayTableViewCellMinimumHeight            50.0

@interface SLHolidaySelectionTableViewController ()

// the array of selected holidays to be displayed
@property (nonatomic, strong) NSMutableArray *selectedHolidays;

// the available holidays for this country (loaded from the bundle resource)
@property (nonatomic, strong) NSArray *availableHolidays;

// the holiday country that this selection controller is displaying
@property (nonatomic) SLHolidayCountry holidayCountry;

@end

@implementation SLHolidaySelectionTableViewController

// initialize this controller with the selected holidays and available holidays for a given holiday country
- (instancetype)initWithSelectedHolidays:(NSArray *)selectedHolidays holidayResource:(NSDictionary *)holidayResource inHolidayCountry:(SLHolidayCountry)holidayCountry
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.selectedHolidays = [[NSMutableArray alloc] initWithArray:selectedHolidays];
        self.availableHolidays = [holidayResource objectForKey:kSLHolidayHolidaysKey];
        self.holidayCountry = holidayCountry;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // customize the view controller and table
    self.title = [SLPrefsManager friendlyNameForHolidayCountry:self.holidayCountry];
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
    for (NSInteger i = 0; i < self.availableHolidays.count; i++) {
        NSDictionary *holiday = [self.availableHolidays objectAtIndex:i];
        for (NSString *selectedHolidayName in self.selectedHolidays) {
            if ([selectedHolidayName isEqualToString:[holiday objectForKey:kSLHolidayNameKey]]) {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
    }
    [self.selectedHolidays removeAllObjects];
    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
}

// invoked when the given view is moving to the parent view controller
- (void)willMoveToParentViewController:(UIViewController *)parent
{
    // if the parent is nil, we know we are popping this view controller
    if (!parent && self.delegate && [self.delegate conformsToProtocol:@protocol(SLHolidaySelectionDelegate)]) {
        // tell the delegate about the updated skip dates
        [self.delegate SLHolidaySelectionTableViewController:self
                                   didUpdateSelectedHolidays:[self.selectedHolidays copy]
                                           forHolidayCountry:self.holidayCountry];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.availableHolidays.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue the cell and create one if needed
    UITableViewCell *holidayCell = [tableView dequeueReusableCellWithIdentifier:kSLHolidayTableViewCellIdentifier];
    if (holidayCell == nil) {
        holidayCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:kSLHolidayTableViewCellIdentifier];
        holidayCell.accessoryType = UITableViewCellAccessoryNone;
        holidayCell.accessoryView = nil;
        holidayCell.textLabel.textAlignment = NSTextAlignmentLeft;
        holidayCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
        holidayCell.textLabel.numberOfLines = 0;
        holidayCell.detailTextLabel.textColor = [UIColor grayColor];
        holidayCell.detailTextLabel.numberOfLines = 1;

        // on newer versions of iOS, we need to set the background views for the cell
        if (kSLSystemVersioniOS14 || kSLSystemVersioniOS13) {
            holidayCell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];
        }

        // set the background color of the cell to clear to remove the selection color
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor clearColor];
        holidayCell.selectedBackgroundView = backgroundView;
    }

    // get the corresponding holiday for this cell for display
    NSDictionary *holiday = [self.availableHolidays objectAtIndex:indexPath.row];
    holidayCell.textLabel.text = [holiday objectForKey:kSLHolidayNameKey];

    NSArray *holidayDates = [holiday objectForKey:kSLHolidayDatesKey];
    if (holidayDates.count > 0) {
        holidayCell.detailTextLabel.text = [SLPrefsManager skipDateStringForDate:[[SLPrefsManager plistDateFormatter] dateFromString:[holidayDates objectAtIndex:0]]
                                                              showRelativeString:NO];
    } else {
        holidayCell.detailTextLabel.text = kSLNoFutureDatesString;
    }
    
    return holidayCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return kSLHolidayExplanationString;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // set the selection for this cell if it should be selected
    for (NSString *selectedHolidayName in self.selectedHolidays) {
        if ([selectedHolidayName isEqualToString:[[self.availableHolidays objectAtIndex:indexPath.row] objectForKey:kSLHolidayNameKey]]) {
            [cell setSelected:YES animated:NO];
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            break;
        }
    }
}

// handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // add the name of the holiday to the selected array
    [self.selectedHolidays addObject:[[self.availableHolidays objectAtIndex:indexPath.row] objectForKey:kSLHolidayNameKey]];
}

// handle cell deselection
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // remove the name of the selected holiday from the selected array
    [self.selectedHolidays removeObject:[[self.availableHolidays objectAtIndex:indexPath.row] objectForKey:kSLHolidayNameKey]];
}

// calculate the height for the cell based on the text provided
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the corresponding holiday for this cell for display
    NSDictionary *holiday = [self.availableHolidays objectAtIndex:indexPath.row];

    // determine the size of the label that will be used to display the holiday name
    NSString *holidayName = [holiday objectForKey:kSLHolidayNameKey];
    CGRect holidayNameRect = [holidayName boundingRectWithSize:CGSizeMake(tableView.frame.size.width - kSLHolidayTableViewCellEditControlWidth - (2 * kSLHolidayTableViewCellLabelHorizontalPadding), CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0]}
                                                       context:nil];
    
    // return the calculated height (with the additional cell padding) or the minimum height for this cell, whichever is greater
    return MAX(ceilf(holidayNameRect.size.height) + (2 * kSLHolidayTableViewCellLabelVerticalPadding) + kSLHolidayTableViewCellDetailLabelHeight + 1.0, kSLHolidayTableViewCellMinimumHeight);
}

@end
