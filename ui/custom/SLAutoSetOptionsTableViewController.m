//
//  SLAutoSetOptionsTableViewController.m
//  Table view controller that presents the user with various options to configure the timer to automatically be set.
//
//  Created by Joshua Seltzer on 7/1/20.
//  Copyright © 2020 Joshua Seltzer. All rights reserved.
//

#import "SLAutoSetOptionsTableViewController.h"
#import "../../common/SLCompatibilityHelper.h"
#import "../../common/SLLocalizedStrings.h"

// define the reuse identifier for the cells in this table
#define kSLAutoSetOptionTableViewCellIdentifier                 @"SLAutoSetOptionTableViewCell"

// define an enum for the available sections in this table
typedef enum SLAutoSetOptionsTableViewControllerSection : NSUInteger {
    kSLAutoSetOptionsTableViewControllerSectionOption,
    kSLAutoSetOptionsTableViewControllerSectionOffset,
    SLAutoSetOptionsTableViewControllerNumSections
} SLAutoSetOptionsTableViewControllerSection;

@interface SLAutoSetOptionsTableViewController ()

// the selected auto-set option
@property (nonatomic) SLAutoSetOption autoSetOption;

// the selected auto-set offset option
@property (nonatomic) SLAutoSetOffsetOption autoSetOffsetOption;

// the selected auto-set offset hour
@property (nonatomic) NSInteger autoSetOffsetHour;

// the selected auto-set offset hour
@property (nonatomic) NSInteger autoSetOffsetMinute;

@end

@implementation SLAutoSetOptionsTableViewController

// initialize this controller with the selected auto-set settings
- (instancetype)initWithAutoSetOption:(SLAutoSetOption)autoSetOption
                  autoSetOffsetOption:(SLAutoSetOffsetOption)autoSetOffsetOption
                    autoSetOffsetHour:(NSInteger)autoSetOffsetHour
                  autoSetOffsetMinute:(NSInteger)autoSetOffsetMinute
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.autoSetOption = autoSetOption;
        self.autoSetOffsetOption = autoSetOffsetOption;
        self.autoSetOffsetHour = autoSetOffsetHour;
        self.autoSetOffsetMinute = autoSetOffsetMinute;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // customize the view controller and table
    self.title = kSLAutoSetString;
}

// invoked when the given view is moving to the parent view controller
- (void)willMoveToParentViewController:(UIViewController *)parent
{
    // if the parent is nil, we know we are popping this view controller
    if (!parent && self.delegate) {
        // tell the delegate about the updated skip dates
        [self.delegate SLAutoSetOptionsTableViewController:self didUpdateAutoSetOption:self.autoSetOption
                                                               withAutoSetOffsetOption:self.autoSetOffsetOption
                                                                 withAutoSetOffsetHour:self.autoSetOffsetHour
                                                               withAutoSetOffsetMinute:self.autoSetOffsetMinute];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SLAutoSetOptionsTableViewControllerNumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;
    if (section == kSLAutoSetOptionsTableViewControllerSectionOption) {
        // the number of rows for the options section corresponds to the last option provided
        numRows = kSLSkipActivatedStatusDisabled + 1;
    }
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue the cell and create one if needed
    UITableViewCell *autoSetOptionCell = [tableView dequeueReusableCellWithIdentifier:kSLAutoSetOptionTableViewCellIdentifier];
    if (autoSetOptionCell == nil) {
        autoSetOptionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:kSLAutoSetOptionTableViewCellIdentifier];
        autoSetOptionCell.accessoryType = UITableViewCellAccessoryNone;
        autoSetOptionCell.accessoryView = [[UIImageView alloc] initWithImage:[SLCompatibilityHelper checkmarkImage]];
        autoSetOptionCell.textLabel.textAlignment = NSTextAlignmentLeft;
        autoSetOptionCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
        autoSetOptionCell.textLabel.numberOfLines = 0;

        // on newer versions of iOS, we need to set the background views for the cell
        if (kSLSystemVersioniOS13) {
            autoSetOptionCell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];
        }

        // set the background color of the cell to clear to remove the selection color
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor clearColor];
        autoSetOptionCell.selectedBackgroundView = backgroundView;
    }

    // get the text corresponding to the auto set option corresponding to the row
    if (indexPath.section == kSLAutoSetOptionsTableViewControllerSectionOption) {
        autoSetOptionCell.textLabel.text = [SLPrefsManager friendlyNameForAutoSetOption:indexPath.row];

        // check to see if this cell's accessory view should be shown or not based on the selected auto-set option
        if (self.autoSetOption == indexPath.row) {
            autoSetOptionCell.accessoryView.hidden = NO;
        } else {
            autoSetOptionCell.accessoryView.hidden = YES;
        }
    }
    
    return autoSetOptionCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

#pragma mark - UITableViewDelegate

// handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSLAutoSetOptionsTableViewControllerSectionOption) {
        // animate the deselection of the cell
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        // check to see if the selected cell's row corresponds to the currently selected auto-set option
        if (self.autoSetOption != indexPath.row) {
            // capture the previously selected auto-set option (i.e. row)
            NSInteger previousAutoSetOption = self.autoSetOption;

            // update the auto-set option to the selected row
            self.autoSetOption = indexPath.row;

            // reload the necessary cells
            [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:previousAutoSetOption inSection:kSLAutoSetOptionsTableViewControllerSectionOption],
                                                [NSIndexPath indexPathForRow:indexPath.row inSection:kSLAutoSetOptionsTableViewControllerSectionOption]]
                              withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

@end
