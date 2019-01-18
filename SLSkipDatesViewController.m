//
//  SLSkipDatesViewController.m
//
//  Created by Joshua Seltzer on 1/2/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLSkipDatesViewController.h"
#import "SLPartialModalPresentationController.h"
#import "SLPrefsManager.h"
#import "SLHolidaySelectionTableViewController.h"

// define the reuse identifier for the cells in this table
#define kSLSkipDateTableViewCellIdentifier              @"SLSkipDateTableViewCell"
#define kSLAddNewDateTableViewCellIdentifier            @"SLAddNewDateTableViewCell"
#define kSLResetDefaultTableViewCellIdentifier          @"SLResetDefaultTableViewCell"
#define kSLHolidaysTableViewCellIdentifier              @"SLHolidaysTableViewCell"

// enum that defines the sections that will be used in this table
typedef enum SLSkipDatesViewControllerSection : NSInteger {
    kSLSkipDatesViewControllerSectionDates,
    kSLSkipDatesViewControllerSectionAddDate,
    kSLSkipDatesViewControllerSectionHolidays,
    kSLSkipDatesViewControllerSectionnResetDefault,
    kSLSkipDatesViewControllerSectionNumSections
} SLSkipDatesViewControllerSection;

@interface SLSkipDatesViewController ()

// the array that contains the dates that will be skipping
@property (nonatomic, strong) NSMutableArray *customSkipDates;

// this value is set if the user is editing an existing date
@property (nonatomic, strong) NSIndexPath *editingIndexPath;

@end

// keep a single static instance of the date formatter that will be used to display the skip dates to the user
static NSDateFormatter *sSLCustomSkipDatesDateFormatter;

// TODO: Update all strings with localized versions
@implementation SLSkipDatesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Skip Dates";
    
    // create and customize the table
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelectionDuringEditing = YES;
    
    // initialize the skip dates
    self.customSkipDates = [[NSMutableArray alloc] init];
    
    // set the edit button to the right bar button if there are skip dates to remove
    if (self.customSkipDates.count > 0) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    
    // create the date formatter that will be used to display the dates (only once)
    if (sSLCustomSkipDatesDateFormatter == nil) {
        sSLCustomSkipDatesDateFormatter = [[NSDateFormatter alloc] init];
        sSLCustomSkipDatesDateFormatter.dateFormat = @"EEEE, MMMM d, YYYY";
    }
}

// override the editing state to modify the state of the table
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // update the sections that are either displayed or not displayed when edit mode is toggled
    NSRange sectionUpdateRange = NSMakeRange(kSLSkipDatesViewControllerSectionAddDate,
                                             kSLSkipDatesViewControllerSectionNumSections - 1);
    if (self.editing) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:sectionUpdateRange]
                      withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:sectionUpdateRange]
                      withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.navigationItem setHidesBackButton:self.editing animated:YES];
    
    // update the state of the selection style for all skip date cells when editing mode is toggled
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        if (indexPath.section == kSLSkipDatesViewControllerSectionDates) {
            [self updateSkipDateCellSelectionStyle:[self.tableView cellForRowAtIndexPath:indexPath]];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // the number of sections displayed in the table view varies depending on whether or not we are in editing mode
    NSInteger numSections = 0;
    if (self.editing) {
        numSections = 1;
    } else {
        numSections = kSLSkipDatesViewControllerSectionNumSections;
    }
    return numSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;
    switch (section) {
        case kSLSkipDatesViewControllerSectionDates:
            numRows = self.customSkipDates.count;
            break;
        case kSLSkipDatesViewControllerSectionHolidays:
            numRows = kSLHolidayCountryNumCountries;
            break;
        case kSLSkipDatesViewControllerSectionAddDate:
        case kSLSkipDatesViewControllerSectionnResetDefault:
            numRows = 1;
            break;
    }
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) {
        case kSLSkipDatesViewControllerSectionDates: {
            UITableViewCell *skipDateCell = [tableView dequeueReusableCellWithIdentifier:kSLSkipDateTableViewCellIdentifier];
            if (skipDateCell == nil) {
                skipDateCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:kSLSkipDateTableViewCellIdentifier];
                skipDateCell.accessoryType = UITableViewCellAccessoryNone;
                skipDateCell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                skipDateCell.textLabel.textAlignment = NSTextAlignmentLeft;
            }
            [self updateSkipDateCellSelectionStyle:skipDateCell];
            
            // customize the cell by grabbing the corresponding skip date
            NSDate *skipDate = [self.customSkipDates objectAtIndex:indexPath.row];
            skipDateCell.textLabel.text = [sSLCustomSkipDatesDateFormatter stringFromDate:skipDate];
            
            cell = skipDateCell;
            break;
        }
        case kSLSkipDatesViewControllerSectionAddDate: {
            UITableViewCell *addNewDateCell = [tableView dequeueReusableCellWithIdentifier:kSLAddNewDateTableViewCellIdentifier];
            if (addNewDateCell == nil) {
                addNewDateCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:kSLAddNewDateTableViewCellIdentifier];
                addNewDateCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                addNewDateCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                addNewDateCell.textLabel.textAlignment = NSTextAlignmentLeft;
            }
            
            // customize the cell
            addNewDateCell.textLabel.text = @"Add New Date...";
            
            cell = addNewDateCell;
            break;
        }
        case kSLSkipDatesViewControllerSectionHolidays: {
            UITableViewCell *holidayCell = [tableView dequeueReusableCellWithIdentifier:kSLHolidaysTableViewCellIdentifier];
            if (holidayCell == nil) {
                holidayCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:kSLHolidaysTableViewCellIdentifier];
                holidayCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                holidayCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                holidayCell.textLabel.textAlignment = NSTextAlignmentLeft;
            }
            
            // customize the cell
            switch (indexPath.row) {
                case kSLHolidayCountryUnitedStates:
                    // TODO: update the text here with the localized string, the key for which comes from the corresponding plist
                    holidayCell.textLabel.text = @"United States";
                    break;
            }
            
            cell = holidayCell;
            break;
        }
        case kSLSkipDatesViewControllerSectionnResetDefault: {
            UITableViewCell *resetDefaultCell = [tableView dequeueReusableCellWithIdentifier:kSLResetDefaultTableViewCellIdentifier];
            if (resetDefaultCell == nil) {
                resetDefaultCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:kSLResetDefaultTableViewCellIdentifier];
                resetDefaultCell.accessoryType = UITableViewCellAccessoryNone;
                resetDefaultCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                resetDefaultCell.textLabel.textAlignment = NSTextAlignmentCenter;
            }
            
            // customize the cell
            resetDefaultCell.textLabel.text = @"Reset Default";
            
            cell = resetDefaultCell;
            break;
        }
    }
    
    return cell;
}

// updates the state of the skip date cell depending on whether or not the tableview is in edit mode
- (void)updateSkipDateCellSelectionStyle:(UITableViewCell *)skipDateCell
{
    if (self.isEditing) {
        skipDateCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        skipDateCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

// determines whether or not a given row in this table is editable
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // only rows in the skip days section will be marked for editing
    BOOL canEdit = NO;
    if (indexPath.section == kSLSkipDatesViewControllerSectionDates) {
        canEdit = YES;
    }
    return canEdit;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSLSkipDatesViewControllerSectionDates) {
        // remove the date from our data source and reload the table
        [self.customSkipDates removeObjectAtIndex:indexPath.row];
        
        // update the table visually
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (self.customSkipDates.count == 0) {
            // if there are no more skip dates available, end editing and disable the edit button
            if (self.editing) {
                [self setEditing:NO animated:YES];
            }
            self.navigationItem.rightBarButtonItem = nil;
        }
        [tableView endUpdates];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerTitle = nil;
    if (section == kSLSkipDatesViewControllerSectionDates) {
        footerTitle = @"This alarm will be skipped on the dates selected.";
    }
    return footerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    if (section == kSLSkipDatesViewControllerSectionHolidays) {
        headerTitle = @"Holidays";
    }
    return headerTitle;
}

#pragma mark - UITableViewDelegate

// handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // set some variables that may be used if editing or adding a new date
    NSDate *editDate = nil;
    self.editingIndexPath = nil;
    
    switch (indexPath.section) {
        case kSLSkipDatesViewControllerSectionDates:
            // get the existing date to edit (intentionally do not break here to proceed to the next case)
            if (self.isEditing) {
                self.editingIndexPath = indexPath;
                editDate = [self.customSkipDates objectAtIndex:indexPath.row];
                [self setEditing:NO animated:YES];
            } else {
                // if we are not editing, do nothing when these cells are selected
                break;
            }
        case kSLSkipDatesViewControllerSectionAddDate: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            // create the edit date controller which will be shown as a partial modal transition to allow
            // the user to pick a new date or edit an existing one
            SLEditDateViewController *editDateViewController = [[SLEditDateViewController alloc] initWithInitialDate:editDate];
            editDateViewController.delegate = self;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editDateViewController];
            navController.modalPresentationStyle = UIModalPresentationCustom;
            navController.transitioningDelegate = self;
            [self presentViewController:navController animated:YES completion:nil];
            break;
        }
        case kSLSkipDatesViewControllerSectionHolidays: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            // load up the corresponding holidays to be displayed in the pushed controller
            NSArray *holidays = [SLPrefsManager holidaysForCountry:indexPath.row];
            if (holidays != nil) {
                // TODO: determine what holidays the user has picked and set the selections accordingly
                
                // create a new holiday selection controller with the list of holidays for the user to configure
                SLHolidaySelectionTableViewController *holidaySelectionTableViewController = [[SLHolidaySelectionTableViewController alloc] initWithHolidays:holidays];
                [self.navigationController pushViewController:holidaySelectionTableViewController animated:YES];
            }
            break;
        }
        case kSLSkipDatesViewControllerSectionnResetDefault: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            // clear out all of the saved dates after saving how many rows will need to be cleared
            NSInteger rowsToRemove = self.customSkipDates.count;
            [self.customSkipDates removeAllObjects];
            
            // update the UI to indicate the changes by removing all of the rows in the custom skip dates section
            NSMutableArray *customSkipDatesIndexPathes = [[NSMutableArray alloc] initWithCapacity:rowsToRemove];
            for (NSInteger i = 0; i < rowsToRemove; i++) {
                [customSkipDatesIndexPathes addObject:[NSIndexPath indexPathForRow:i
                                                                         inSection:kSLSkipDatesViewControllerSectionDates]];
            }
            [tableView deleteRowsAtIndexPaths:customSkipDatesIndexPathes
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            
            // remove the edit button from the controller since there are no dates to edit
            self.navigationItem.rightBarButtonItem = nil;
            break;
        }
    }
}

// set up the editing style for the given cells
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // only the skip days section is editable
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    if (indexPath.section == kSLSkipDatesViewControllerSectionDates) {
        editingStyle = UITableViewCellEditingStyleDelete;
    }
    return editingStyle;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    // only the skip days section should be indented
    BOOL shouldIndent = NO;
    if (indexPath.section == kSLSkipDatesViewControllerSectionDates) {
        shouldIndent = YES;
    }
    return shouldIndent;
}

// provide an empty implementation to these delegate functions to prevent the table from entering and leaving edit mode
// when a swipe to delete action is performed on any cells
- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {}
- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {}

#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    // calculate the percentage of the screen that should be shown to display the edit date controller
    CGFloat safeAreaInsets = 0.0;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom + [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.top;
    }
    CGFloat partialModalPercentage = ceilf((kSLEditDatePickerViewHeight + [UIApplication sharedApplication].statusBarFrame.size.height) / (source.view.frame.size.height - safeAreaInsets) * 100) / 100;
    
    // return the custom presentation controller
    return [[SLPartialModalPresentationController alloc] initWithPresentedViewController:presented
                                                                presentingViewController:presenting
                                                                  partialModalPercentage:partialModalPercentage
                                                                     allowSwipeDismissal:NO];
}

#pragma mark - SLEditDateViewControllerDelegate

// invoked when the edit date view controller saves a date
- (void)dateUpdated:(NSDate *)date
{
    if (self.editingIndexPath != nil) {
        // if an editing index path is set, then we are editing an existing date.
        [self.customSkipDates replaceObjectAtIndex:self.editingIndexPath.row withObject:date];
        [self.tableView reloadRowsAtIndexPaths:@[self.editingIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        self.editingIndexPath = nil;
    } else {
        // check to see if the date has already been added (in this case, do not add a new date)
        BOOL containsDate = NO;
        for (NSDate *skipDate in self.customSkipDates) {
            if ([[NSCalendar currentCalendar] isDate:skipDate inSameDayAsDate:date]) {
                containsDate = YES;
                break;
            }
        }
        if (!containsDate) {
            // add a new date to the array of skip dates
            [self.customSkipDates addObject:date];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.customSkipDates.count - 1
                                                                        inSection:kSLSkipDatesViewControllerSectionDates]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            
            // set the edit button to the right bar button if there are skip dates to remove
            if (self.customSkipDates.count > 0) {
                self.navigationItem.rightBarButtonItem = self.editButtonItem;
            }
        }
    }
}

@end
