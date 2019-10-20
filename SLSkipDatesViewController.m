//
//  SLSkipDatesViewController.m
//
//  Created by Joshua Seltzer on 1/2/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLSkipDatesViewController.h"
#import "SLPartialModalPresentationController.h"
#import "SLPrefsManager.h"
#import "SLLocalizedStrings.h"
#import "SLCompatibilityHelper.h"

// define the reuse identifier for the cells in this table
#define kSLSkipDateTableViewCellIdentifier              @"SLSkipDateTableViewCell"
#define kSLAddNewDateTableViewCellIdentifier            @"SLAddNewDateTableViewCell"
#define kSLResetDefaultTableViewCellIdentifier          @"SLResetDefaultTableViewCell"
#define kSLCountriesTableViewCellIdentifier             @"SLCountriesTableViewCell"

// enum that defines the sections that will be used in this table
typedef enum SLSkipDatesViewControllerSection : NSInteger {
    kSLSkipDatesViewControllerSectionDates,
    kSLSkipDatesViewControllerSectionAddDate,
    kSLSkipDatesViewControllerSectionCountries,
    kSLSkipDatesViewControllerSectionnResetDefault,
    kSLSkipDatesViewControllerSectionNumSections
} SLSkipDatesViewControllerSection;

@interface SLSkipDatesViewController ()

// the array that contains the custom dates that will be skipped
@property (nonatomic, strong) NSMutableArray *customSkipDates;

// the dictionary containing the holiday skip dates for this alarm
@property (nonatomic, strong) NSMutableDictionary *holidaySkipDates;

// dictionary of all available holiday country resources
@property (nonatomic, strong) NSDictionary *holidayResources;

// the preferences for the alarm
@property (nonatomic, strong) SLAlarmPrefs *alarmPrefs;

// this value is set if the user is editing an existing date
@property (nonatomic, strong) NSIndexPath *editingIndexPath;

@end

@implementation SLSkipDatesViewController

// initialize this controller with the preferences for the given alarm
- (instancetype)initWithAlarmPrefs:(SLAlarmPrefs *)alarmPrefs
{
    self = [super init];
    if (self) {
        self.alarmPrefs = alarmPrefs;
        self.customSkipDates = [[NSMutableArray alloc] initWithArray:alarmPrefs.customSkipDates];
        self.holidaySkipDates = [[NSMutableDictionary alloc] initWithDictionary:alarmPrefs.holidaySkipDates];

        // populate a dictionary of all available holiday resource objects
        NSMutableDictionary *holidayResources = [[NSMutableDictionary alloc] initWithCapacity:kSLHolidayCountryNumCountries];
        for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
            // grab the resource for the holiday country
            NSDictionary *holidayResource = [SLPrefsManager holidayResourceForHolidayCountry:holidayCountry];
            [holidayResources setObject:holidayResource forKey:[SLPrefsManager resourceNameForHolidayCountry:holidayCountry]];
        }
        self.holidayResources = [holidayResources copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = kSLSkipDatesString;
    
    // create and customize the table
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelectionDuringEditing = YES;
    
    // set the edit button to the right bar button if there are skip dates to remove
    if (self.customSkipDates.count > 0) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

// invoked when the given view is moving to the parent view controller
- (void)willMoveToParentViewController:(UIViewController *)parent
{
    // if the parent is nil, we know we are popping this view controller
    if (!parent && self.delegate) {
        // tell the delegate about the updated skip dates
        [self.delegate SLSkipDatesViewController:self
                        didUpdateCustomSkipDates:[self.customSkipDates copy]
                                holidaySkipDates:[self.holidaySkipDates copy]];
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
        case kSLSkipDatesViewControllerSectionCountries:
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

                // set the background color of the cell
                if (@available(iOS 10.0, *)) {
                    UIView *backgroundView = [[UIView alloc] init];
                    backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
                    skipDateCell.selectedBackgroundView = backgroundView;
                }
            }
            [self updateSkipDateCellSelectionStyle:skipDateCell];
            
            // customize the cell by grabbing the corresponding skip date
            NSDate *skipDate = [self.customSkipDates objectAtIndex:indexPath.row];
            skipDateCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
            skipDateCell.textLabel.text = [SLPrefsManager skipDateStringForDate:skipDate];
            
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

                // set the background color of the cell
                if (@available(iOS 10.0, *)) {
                    UIView *backgroundView = [[UIView alloc] init];
                    backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
                    addNewDateCell.selectedBackgroundView = backgroundView;
                }
            }
            
            // customize the cell
            addNewDateCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
            addNewDateCell.textLabel.text = kSLAddNewDateString;
            
            cell = addNewDateCell;
            break;
        }
        case kSLSkipDatesViewControllerSectionCountries: {
            UITableViewCell *countryCell = [tableView dequeueReusableCellWithIdentifier:kSLCountriesTableViewCellIdentifier];
            if (countryCell == nil) {
                countryCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                     reuseIdentifier:kSLCountriesTableViewCellIdentifier];
                countryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                countryCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                countryCell.textLabel.textAlignment = NSTextAlignmentLeft;

                // set the background color of the cell
                if (@available(iOS 10.0, *)) {
                    UIView *backgroundView = [[UIView alloc] init];
                    backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
                    countryCell.selectedBackgroundView = backgroundView;
                }
            }
            
            // customize the cell
            countryCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
            countryCell.textLabel.text = [SLPrefsManager friendlyNameForHolidayCountry:indexPath.row];
            
            // display the text for the country different if there are any selected
            NSString *resourceName = [SLPrefsManager resourceNameForHolidayCountry:indexPath.row];
            NSDictionary *holidayResource = [self.holidayResources objectForKey:resourceName];
            NSInteger numTotalAvailableHolidays = [[holidayResource objectForKey:kSLHolidayHolidaysKey] count];
            NSInteger numSelectedHolidays = [[self.holidaySkipDates objectForKey:resourceName] count];
            if (numSelectedHolidays > 0) {
                countryCell.detailTextLabel.text = [NSString stringWithFormat:@"%ld (%@)", (long)numTotalAvailableHolidays, kSLNumberSelectedString(numSelectedHolidays)];
            } else {
                countryCell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)numTotalAvailableHolidays];
            }
            
            cell = countryCell;
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

                // set the background color of the cell
                if (@available(iOS 10.0, *)) {
                    UIView *backgroundView = [[UIView alloc] init];
                    backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
                    resetDefaultCell.selectedBackgroundView = backgroundView;
                }
            }
            
            // customize the cell
            resetDefaultCell.textLabel.textColor = [SLCompatibilityHelper destructiveLabelColor];
            resetDefaultCell.textLabel.text = kSLResetDefaultString;
            
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
    switch (section) {
        case kSLSkipDatesViewControllerSectionDates:
            footerTitle = kSLSkipDateExplanationString;
            break;
        case kSLSkipDatesViewControllerSectionnResetDefault:
            footerTitle = kSLDefaultSkipDatesString;
            break;
    }
    return footerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    if (section == kSLSkipDatesViewControllerSectionCountries) {
        headerTitle = kSLHolidaysString;
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
        case kSLSkipDatesViewControllerSectionCountries: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            // load up the corresponding country to be displayed in the holiday selection controller
            NSString *resourceName = [SLPrefsManager resourceNameForHolidayCountry:indexPath.row];
            if (resourceName != nil) {
                // create a new holiday selection controller with the list of holidays for the user to configure
                SLHolidaySelectionTableViewController *holidaySelectionTableViewController = [[SLHolidaySelectionTableViewController alloc] initWithSelectedHolidays:[self.holidaySkipDates objectForKey:resourceName]
                                                                                                                                                     holidayResource:[self.holidayResources objectForKey:resourceName]
                                                                                                                                                    inHolidayCountry:indexPath.row];
                holidaySelectionTableViewController.delegate = self;
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
            NSMutableArray *customSkipDatesIndexPaths = [[NSMutableArray alloc] initWithCapacity:rowsToRemove];
            for (NSInteger i = 0; i < rowsToRemove; i++) {
                [customSkipDatesIndexPaths addObject:[NSIndexPath indexPathForRow:i
                                                                        inSection:kSLSkipDatesViewControllerSectionDates]];
            }
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:customSkipDatesIndexPaths
                             withRowAnimation:UITableViewRowAnimationFade];

            // clear out any of the selected holidays
            NSMutableArray *updatedHolidayCountryIndexPaths = [[NSMutableArray alloc] init];
            for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
                // get the holidays that correspond to the country's particular resource
                NSString *resourceName = [SLPrefsManager resourceNameForHolidayCountry:holidayCountry];
                NSMutableArray *selectedHolidayNames = [[NSMutableArray alloc] initWithArray:[self.holidaySkipDates objectForKey:resourceName]];
                if (selectedHolidayNames != nil && selectedHolidayNames.count > 0) {
                    // remove all selected holidays
                    [selectedHolidayNames removeAllObjects];
                    [self.holidaySkipDates setObject:selectedHolidayNames forKey:resourceName];

                    // add the corresponding index path to update
                    [updatedHolidayCountryIndexPaths addObject:[NSIndexPath indexPathForRow:holidayCountry
                                                                                  inSection:kSLSkipDatesViewControllerSectionCountries]];
                }
            }

            if (updatedHolidayCountryIndexPaths.count > 0) {
                [tableView reloadRowsAtIndexPaths:updatedHolidayCountryIndexPaths
                                withRowAnimation:UITableViewRowAnimationFade];
            }
            [tableView endUpdates];
            
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
        safeAreaInsets = source.view.safeAreaInsets.bottom + source.view.safeAreaInsets.top;
    } else {
        // for older iOS versions, add some additional padding
        safeAreaInsets = 30.0;
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
- (void)SLEditDateViewController:(SLEditDateViewController *)editDateViewController didUpdateDate:(NSDate *)date
{
    BOOL tableNeedsRefresh = NO;
    if (self.editingIndexPath != nil) {
        // if an editing index path is set, then we are editing an existing date.
        [self.customSkipDates replaceObjectAtIndex:self.editingIndexPath.row withObject:date];
        tableNeedsRefresh = YES;
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
            tableNeedsRefresh = YES;
            
            // set the edit button to the right bar button if there are skip dates to remove
            if (self.customSkipDates.count > 0) {
                self.navigationItem.rightBarButtonItem = self.editButtonItem;
            }
        }
    }
    // refresh the table if necessary
    if (tableNeedsRefresh) {
        // sort the custom skip dates
        [self.customSkipDates sortUsingSelector:@selector(compare:)];

        // reload the section with the custom skip dates
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSLSkipDatesViewControllerSectionDates]
                      withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - SLHolidaySelectionDelegate

// invoked when the holiday selection controller returns with updated holidays
- (void)SLHolidaySelectionTableViewController:(SLHolidaySelectionTableViewController *)holidaySelectionTableViewController didUpdateSelectedHolidays:(NSArray *)selectedHolidays forHolidayCountry:(SLHolidayCountry)holidayCountry
{
    // update the row that corresponds to the holiday country
    NSString *resourceName = [SLPrefsManager resourceNameForHolidayCountry:holidayCountry];

    // set the new selected holidays
    [self.holidaySkipDates setObject:selectedHolidays forKey:resourceName];

    // refresh the table UI
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:holidayCountry inSection:kSLSkipDatesViewControllerSectionCountries]]
                          withRowAnimation:UITableViewRowAnimationFade];
}

@end
