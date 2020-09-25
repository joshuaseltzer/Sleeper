//
//  SLAutoSetOptionsTableViewController.m
//  Table view controller that presents the user with various options to configure the timer to automatically be set.
//
//  Created by Joshua Seltzer on 7/1/20.
//  Copyright © 2020 Joshua Seltzer. All rights reserved.
//

#import "SLAutoSetOptionsTableViewController.h"
#import "SLPartialModalPresentationController.h"
#import "../../common/SLCompatibilityHelper.h"
#import "../../common/SLLocalizedStrings.h"

// define the reuse identifier for the cells in this table
#define kSLAutoSetOptionOpenInTableViewCellIdentifier           @"SLAutoSetOptionOpenInTableViewCell"
#define kSLAutoSetOptionCheckmarkTableViewCellIdentifier        @"SLAutoSetOptionCheckmarkTableViewCell"
#define kSLAutoSetOptionSelectionTableViewCellIdentifier        @"SLAutoSetOptionSelectionTableViewCell"

// define an enum for the available sections in this table
typedef enum SLAutoSetOptionsTableViewControllerSection : NSUInteger {
    kSLAutoSetOptionsTableViewControllerSectionWeather,
    kSLAutoSetOptionsTableViewControllerSectionOption,
    kSLAutoSetOptionsTableViewControllerSectionOffset,
    kSLAutoSetOptionsTableViewControllerNumSections
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

// the number of rows to be shown in the offset section
@property (nonatomic) NSInteger offsetSectionNumRows;

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

        // indicate the number of rows for the offset option section so that the table can distinguish between the rows appropriately
        self.offsetSectionNumRows = kSLAutoSetOffsetOptionAfter + 2;
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

// updates a given cell's accessory view visibility based on the selected aut

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // the number of sections in this table will be dynamic based on selected auto-set option
    NSInteger numSections = kSLAutoSetOptionsTableViewControllerNumSections;
    if (self.autoSetOption == kSLAutoSetOptionOff) {
        numSections = numSections - 1;
    }
    return numSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;
    switch (section) {
        case kSLAutoSetOptionsTableViewControllerSectionWeather:
            // a single row is displayed to allow the user to open the Weather application
            numRows = 1;
            break;
        case kSLAutoSetOptionsTableViewControllerSectionOption:
            // the number of rows for the auto-set options section corresponds to the last auto-set option
            numRows = kSLAutoSetOptionSunset + 1;
            break;
        case kSLAutoSetOptionsTableViewControllerSectionOffset:
            // the number of rows for the offset options section corresponds to the last auto-set option with an additional
            // row added to let the user select the time
            numRows = self.offsetSectionNumRows;
            break;
    }
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case kSLAutoSetOptionsTableViewControllerSectionWeather: {
            // create an open in cell and configure it to allow the user to go to the weather app
            UITableViewCell *weatherOpenInCell = [self tableView:tableView openInCellForRowAtIndexPath:indexPath];
            weatherOpenInCell.textLabel.text = kSLAutoSetOpenWeatherAppString;

            cell = weatherOpenInCell;
            break;
        }
        case kSLAutoSetOptionsTableViewControllerSectionOption: {
            UITableViewCell *autoSetOptionCheckmarkCell = [self tableView:tableView checkmarkCellForRowAtIndexPath:indexPath];

            // set the text of the checkmark cell to the appropriate auto-set option
            autoSetOptionCheckmarkCell.textLabel.text = [SLPrefsManager friendlyNameForAutoSetOption:indexPath.row];

            // check to see if this cell's accessory view should be shown or not based on the selected auto-set option
            if (self.autoSetOption == indexPath.row) {
                autoSetOptionCheckmarkCell.accessoryView.hidden = NO;
            } else {
                autoSetOptionCheckmarkCell.accessoryView.hidden = YES;
            }

            cell = autoSetOptionCheckmarkCell;
            break;
        }
        case kSLAutoSetOptionsTableViewControllerSectionOffset: {
            if (indexPath.row == self.offsetSectionNumRows - 1) {
                UITableViewCell *autoSetOptionSelectionCell = [self tableView:tableView selectionCellForRowAtIndexPath:indexPath];

                // configure the text of this cell
                autoSetOptionSelectionCell.textLabel.text = kSLTimeString;
                NSString *numHours = nil;
                NSString *numMinutes = nil;
                if (self.autoSetOffsetHour == 1) {
                    numHours = kSLNumHourString([@(self.autoSetOffsetHour) stringValue]);
                } else {
                    numHours = kSLNumHoursString([@(self.autoSetOffsetHour) stringValue]);
                }
                if (self.autoSetOffsetMinute == 1) {
                    numMinutes = kSLNumMinuteString([@(self.autoSetOffsetMinute) stringValue]);
                } else {
                    numMinutes = kSLNumMinutesString([@(self.autoSetOffsetMinute) stringValue]);
                }
                autoSetOptionSelectionCell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", numHours, numMinutes];

                cell = autoSetOptionSelectionCell;
            } else {
                UITableViewCell *autoSetOptionCheckmarkCell = [self tableView:tableView checkmarkCellForRowAtIndexPath:indexPath];

                // set the text of the checkmark cell to the appropriate offset option
                autoSetOptionCheckmarkCell.textLabel.text = [SLPrefsManager friendlyNameForAutoSetOffsetOption:indexPath.row];

                // check to see if this cell's accessory view should be shown or not based on the selected offset option
                if (self.autoSetOffsetOption == indexPath.row) {
                    autoSetOptionCheckmarkCell.accessoryView.hidden = NO;
                } else {
                    autoSetOptionCheckmarkCell.accessoryView.hidden = YES;
                }

                cell = autoSetOptionCheckmarkCell;
            }
            break;
        }
    }

    return cell;
}

// returns a cell that, when selected, will navigate the user to another applicastion
- (UITableViewCell *)tableView:(UITableView *)tableView openInCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue the cell and create one if needed
    UITableViewCell *autoSetOptionOpenInCell = [tableView dequeueReusableCellWithIdentifier:kSLAutoSetOptionOpenInTableViewCellIdentifier];
    if (autoSetOptionOpenInCell == nil) {
        autoSetOptionOpenInCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                         reuseIdentifier:kSLAutoSetOptionOpenInTableViewCellIdentifier];
        autoSetOptionOpenInCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        autoSetOptionOpenInCell.accessoryView = nil;
        autoSetOptionOpenInCell.imageView.image = [SLCompatibilityHelper openInImage];
        autoSetOptionOpenInCell.textLabel.textAlignment = NSTextAlignmentLeft;
        autoSetOptionOpenInCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
        autoSetOptionOpenInCell.textLabel.numberOfLines = 0;
        autoSetOptionOpenInCell.detailTextLabel.text = nil;
        
        // on newer versions of iOS, we need to set the background views for the cell
        if (kSLSystemVersioniOS14 || kSLSystemVersioniOS13) {
            autoSetOptionOpenInCell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];
        }

        // set the background color of the cell to clear to remove the selection color
        if (@available(iOS 10.0, *)) {
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
            autoSetOptionOpenInCell.selectedBackgroundView = backgroundView;
        }
    }
    return autoSetOptionOpenInCell;
}

// returns a checkmark cell that will be used in this table
- (UITableViewCell *)tableView:(UITableView *)tableView checkmarkCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue the cell and create one if needed
    UITableViewCell *autoSetOptionCheckmarkCell = [tableView dequeueReusableCellWithIdentifier:kSLAutoSetOptionCheckmarkTableViewCellIdentifier];
    if (autoSetOptionCheckmarkCell == nil) {
        autoSetOptionCheckmarkCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                            reuseIdentifier:kSLAutoSetOptionCheckmarkTableViewCellIdentifier];
        autoSetOptionCheckmarkCell.accessoryType = UITableViewCellAccessoryNone;
        autoSetOptionCheckmarkCell.accessoryView = [[UIImageView alloc] initWithImage:[SLCompatibilityHelper checkmarkImage]];
        autoSetOptionCheckmarkCell.textLabel.textAlignment = NSTextAlignmentLeft;
        autoSetOptionCheckmarkCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
        autoSetOptionCheckmarkCell.textLabel.numberOfLines = 0;

        // on newer versions of iOS, we need to set the background views for the cell
        if (kSLSystemVersioniOS14 || kSLSystemVersioniOS13) {
            autoSetOptionCheckmarkCell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];
        }

        // set the background color of the cell to clear to remove the selection color
        if (@available(iOS 10.0, *)) {
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
            autoSetOptionCheckmarkCell.selectedBackgroundView = backgroundView;
        }
    }
    return autoSetOptionCheckmarkCell;
}

// returns a selection cell that will be used in this table
- (UITableViewCell *)tableView:(UITableView *)tableView selectionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue the cell and create one if needed
    UITableViewCell *autoSetOptionSelectionCell = [tableView dequeueReusableCellWithIdentifier:kSLAutoSetOptionSelectionTableViewCellIdentifier];
    if (autoSetOptionSelectionCell == nil) {
        autoSetOptionSelectionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                            reuseIdentifier:kSLAutoSetOptionSelectionTableViewCellIdentifier];
        autoSetOptionSelectionCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        autoSetOptionSelectionCell.accessoryView = nil;
        autoSetOptionSelectionCell.textLabel.textAlignment = NSTextAlignmentLeft;
        autoSetOptionSelectionCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
        autoSetOptionSelectionCell.textLabel.numberOfLines = 0;
        
        // on newer versions of iOS, we need to set the background views for the cell
        if (kSLSystemVersioniOS14 || kSLSystemVersioniOS13) {
            autoSetOptionSelectionCell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];
        }

        // set the background color of the cell to clear to remove the selection color
        if (@available(iOS 10.0, *)) {
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
            autoSetOptionSelectionCell.selectedBackgroundView = backgroundView;
        }
    }
    return autoSetOptionSelectionCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerTitle = nil;
    switch (section) {
        case kSLAutoSetOptionsTableViewControllerSectionWeather:
            footerTitle = kSLAutoSetWeatherExplanationString;
            break;
        case kSLAutoSetOptionsTableViewControllerSectionOption:
            footerTitle = kSLAutoSetExplanationString;
            break;
        case kSLAutoSetOptionsTableViewControllerSectionOffset:
            footerTitle = kSLAutoSetOffsetExplanationString;
            break;
    }
    return footerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    if (section == kSLAutoSetOptionsTableViewControllerSectionOffset) {
        headerTitle = kSLOffsetString;
    }
    return headerTitle;
}

#pragma mark - UITableViewDelegate

// handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // animate the deselection of the cell
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case kSLAutoSetOptionsTableViewControllerSectionWeather: {
            // navigate the user to the weather application
            [SLCompatibilityHelper openWeatherApplication];
            break;
        }
        case kSLAutoSetOptionsTableViewControllerSectionOption:
            // check to see if the selected cell's row corresponds to the currently selected auto-set option
            if (self.autoSetOption != indexPath.row) {
                // update the visibility of the accessory view of the previously selected cell
                SLAutoSetOption previousAutoSetOption = self.autoSetOption;
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:previousAutoSetOption inSection:kSLAutoSetOptionsTableViewControllerSectionOption]].accessoryView.hidden = YES;

                // update the auto-set option to the selected row
                self.autoSetOption = indexPath.row;

                // update the accessory view of the newly selected cell
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.autoSetOption inSection:kSLAutoSetOptionsTableViewControllerSectionOption]].accessoryView.hidden = NO;

                // check to see if the offset section should be added or removed based on the newly selected auto-set option
                if (previousAutoSetOption == kSLAutoSetOptionOff) {
                    [tableView insertSections:[NSIndexSet indexSetWithIndex:kSLAutoSetOptionsTableViewControllerSectionOffset]
                            withRowAnimation:UITableViewRowAnimationFade];
                } else if (self.autoSetOption == kSLAutoSetOptionOff) {
                    [tableView deleteSections:[NSIndexSet indexSetWithIndex:kSLAutoSetOptionsTableViewControllerSectionOffset]
                            withRowAnimation:UITableViewRowAnimationFade];
                }
            }
            break;
        case kSLAutoSetOptionsTableViewControllerSectionOffset:
            if (indexPath.row == self.offsetSectionNumRows - 1) {
                // create the edit time controller which will be shown as a partial modal transition to allow the user to edit the hours/minutes
                SLEditDateTimeViewController *editTimeViewController = [[SLEditDateTimeViewController alloc] initWithTitle:kSLOffsetTimeString
                                                                                                            initialHours:self.autoSetOffsetHour
                                                                                                            initialMinutes:self.autoSetOffsetMinute
                                                                                                            maximumHours:6];
                editTimeViewController.delegate = self;
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editTimeViewController];
                navController.modalPresentationStyle = UIModalPresentationCustom;
                navController.transitioningDelegate = self;
                [self presentViewController:navController animated:YES completion:nil];
            } else {
                // check to see if the selected cell's row corresponds to the currently selected offset option
                if (self.autoSetOffsetOption != indexPath.row) {
                    // update the visibility of the accessory view of the previously selected cell
                    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.autoSetOffsetOption inSection:kSLAutoSetOptionsTableViewControllerSectionOffset]].accessoryView.hidden = YES;

                    // update the offset option to the selected row
                    self.autoSetOffsetOption = indexPath.row;

                    // update the accessory view of the newly selected cell
                    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.autoSetOffsetOption inSection:kSLAutoSetOptionsTableViewControllerSectionOffset]].accessoryView.hidden = NO;
                }
            }
            break;
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    // calculate the percentage of the screen that should be shown to display the edit date controller
    CGFloat safeAreaInsets = 0.0;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = source.view.safeAreaInsets.bottom + source.view.safeAreaInsets.top;
    } else {
        // for older iOS versions, add some additional padding
        safeAreaInsets = 30.0;
    }
    CGFloat partialModalPercentage = ceilf((kSLEditDateTimePickerViewHeight + [UIApplication sharedApplication].statusBarFrame.size.height) / (source.view.frame.size.height - safeAreaInsets) * 100) / 100;
    
    // return the custom presentation controller
    return [[SLPartialModalPresentationController alloc] initWithPresentedViewController:presented
                                                                presentingViewController:presenting
                                                                  partialModalPercentage:partialModalPercentage
                                                                     allowSwipeDismissal:NO];
}

#pragma mark - SLEditDateTimeViewControllerDelegate

// invoked when the hours and minutes are updated from the edit time view controller
- (void)SLEditDateTimeViewController:(SLEditDateTimeViewController *)editDateTimeViewController didSaveHours:(NSInteger)hours andMinutes:(NSInteger)minutes
{
    // update the offset hours and minutes
    self.autoSetOffsetMinute = minutes;
    self.autoSetOffsetHour = hours;

    // reload the cell which displays the hours/minutes
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.offsetSectionNumRows - 1 inSection:kSLAutoSetOptionsTableViewControllerSectionOffset]]
                          withRowAnimation:UITableViewRowAnimationFade];
}

@end