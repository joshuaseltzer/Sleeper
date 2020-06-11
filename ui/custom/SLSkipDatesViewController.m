//
//  SLSkipDatesViewController.m
//
//  Created by Joshua Seltzer on 1/2/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLSkipDatesViewController.h"
#import "SLPartialModalPresentationController.h"
#import "../../common/SLPrefsManager.h"
#import "../../common/SLLocalizedStrings.h"
#import "../../common/SLCompatibilityHelper.h"

// define the reuse identifier for the cells in this table
#define kSLSkipDateTableViewCellIdentifier              @"SLSkipDateTableViewCell"
#define kSLAddNewDateTableViewCellIdentifier            @"SLAddNewDateTableViewCell"
#define kSLResetDefaultTableViewCellIdentifier          @"SLResetDefaultTableViewCell"
#define kSLCountriesTableViewCellIdentifier             @"SLCountriesTableViewCell"

// enum that defines the sections that will be used in this table
typedef enum SLSkipDatesViewControllerSection : NSInteger {
    kSLSkipDatesViewControllerSectionDates,
    kSLSkipDatesViewControllerSectionAddDate,
    kSLSkipDatesViewControllerSectionRecommendedHolidays,
    kSLSkipDatesViewControllerSectionAllHolidays,
    kSLSkipDatesViewControllerSectionResetDefault,
    kSLSkipDatesViewControllerSectionNumSections
} SLSkipDatesViewControllerSection;

// define the strings that represent the dates for today and tomorrow
static NSString *sSLTodayDateString;
static NSString *sSLTomorrowDateString;

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

// the device might optionally have a holiday country used to show the recommended holidays
@property (nonatomic) SLHolidayCountry deviceHolidayCountry;

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
        self.deviceHolidayCountry = -1;

        // Populate a dictionary of all available holiday resource objects.  Also use this as an opportunity to check to see
        // if this device has any recommended holidays
        NSString *deviceCountryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        NSMutableDictionary *holidayResources = [[NSMutableDictionary alloc] initWithCapacity:kSLHolidayCountryNumCountries];
        for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
            // grab the resource for the holiday country
            NSString *countryCode = [SLPrefsManager countryCodeForHolidayCountry:holidayCountry];
            NSString *resourceName = [SLPrefsManager resourceNameForCountryCode:countryCode];
            NSDictionary *holidayResource = [SLPrefsManager holidayResourceForResourceName:resourceName];
            [holidayResources setObject:holidayResource forKey:resourceName];

            // check to see if the country code matches the device's country code
            if ([deviceCountryCode caseInsensitiveCompare:countryCode] == NSOrderedSame) {
                self.deviceHolidayCountry = holidayCountry;
            }
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

// returns a modified index that corresponds to a holiday country
- (SLHolidayCountry)offsetHolidayCountryIndexForIndex:(NSInteger)index increase:(BOOL)increase
{
    if (self.deviceHolidayCountry == -1 || index < self.deviceHolidayCountry) {
        return index;
    } else {
        if (increase) {
            return ++index;
        } else {
            return --index;
        }
    }
}

// presents the alert controller which dynamic options depending on which skip dates are already included for this alarm
- (void)presentSkipDateAlertController
{
    // create an alert controller (shown as an action sheet) that will be used to allow the user to add various dates
    UIAlertController *selectDateAlertController = [UIAlertController alertControllerWithTitle:kSLAddNewDateString
                                                                                       message:nil
                                                                                preferredStyle:UIAlertControllerStyleActionSheet];

    // create the strings used to determine today and tomorrow's dates only once
    if (sSLTodayDateString == nil || sSLTomorrowDateString == nil) {
        NSDate *today = [NSDate date];
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        dateComponents.day = 1;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *tomorrow = [calendar dateByAddingComponents:dateComponents toDate:[calendar startOfDayForDate:today] options:0];

        sSLTodayDateString = [[SLPrefsManager plistDateFormatter] stringFromDate:today];
        sSLTomorrowDateString = [[SLPrefsManager plistDateFormatter] stringFromDate:tomorrow];
    }
    
    // check if the date representing today is already included in the custom skip dates
    if (![self.customSkipDates containsObject:sSLTodayDateString]) {
        // create an action that will let the user quickly add today as a skip date
        UIAlertAction *skipTodayAlertAction = [UIAlertAction actionWithTitle:kSLTodayString
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                                        // add the today string to the list of custom skip dates
                                                                        [self updateCustomSkipDatesWithSkipDateString:sSLTodayDateString];
                                                                    }];
        [selectDateAlertController addAction:skipTodayAlertAction];
    }

    // check if the date representing tomorrow is already included in the custom skip dates
    if (![self.customSkipDates containsObject:sSLTomorrowDateString]) {
        // create an action that will let the user quickly add tomorrow as a skip date
        UIAlertAction *skipTomorrowAlertAction = [UIAlertAction actionWithTitle:kSLTomorrowString
                                                                          style:UIAlertActionStyleDefault
                                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                                            // add the tomorrow string to the list of custom skip dates
                                                                            [self updateCustomSkipDatesWithSkipDateString:sSLTomorrowDateString];
                                                                        }];
        [selectDateAlertController addAction:skipTomorrowAlertAction];
    }

    // create an action that will let the user pick a single date
    UIAlertAction *skipSingleDateAlertAction = [UIAlertAction actionWithTitle:kSLCustomDateString
                                                                          style:UIAlertActionStyleDefault
                                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                                            // invoke the controller that will allow the user to pick a single custom date
                                                                            [self presentEditDateViewControllerWithInitialDate:nil];
                                                                        }];
    [selectDateAlertController addAction:skipSingleDateAlertAction];

    // create an action that will close the alert
    UIAlertAction *closeAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
    [selectDateAlertController addAction:closeAlertAction];

    // present the alert
    [self presentViewController:selectDateAlertController animated:YES completion:nil];
}

// creates and presents the edit date view controller with the selected initial date
- (void)presentEditDateViewControllerWithInitialDate:(NSDate *)initialDate
{
    // create the edit date controller which will be shown as a partial modal transition to allow
    // the user to pick a new date or edit an existing one
    SLEditDateViewController *editDateViewController = [[SLEditDateViewController alloc] initWithInitialDate:initialDate];
    editDateViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editDateViewController];
    navController.modalPresentationStyle = UIModalPresentationCustom;
    navController.transitioningDelegate = self;
    [self presentViewController:navController animated:YES completion:nil];
}

// logic that will be used to update the data source and UI (i.e. table view) with the given custom skip date string
- (void)updateCustomSkipDatesWithSkipDateString:(NSString *)skipDateString
{
    BOOL tableNeedsRefresh = NO;
    if (self.editingIndexPath != nil) {
        // if an editing index path is set, then we are editing an existing date.
        [self.customSkipDates replaceObjectAtIndex:self.editingIndexPath.row withObject:skipDateString];
        tableNeedsRefresh = YES;
        self.editingIndexPath = nil;
    } else {
        // check to see if the date has already been added (in this case, do not add a new date)
        BOOL containsDate = NO;
        for (NSString *existingSkipDateString in self.customSkipDates) {
            if ([existingSkipDateString isEqualToString:skipDateString]) {
                containsDate = YES;
                break;
            }
        }
        if (!containsDate) {
            // add a new date to the array of skip dates
            [self.customSkipDates addObject:skipDateString];
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

        // scroll to the newly added or updated date
        NSUInteger rowIndex = [self.customSkipDates indexOfObject:skipDateString];
        if (rowIndex != NSNotFound) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex
                                                                      inSection:kSLSkipDatesViewControllerSectionDates]
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:YES];
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
        case kSLSkipDatesViewControllerSectionRecommendedHolidays:
            if (self.deviceHolidayCountry != -1) {
                numRows = 1;
            }
            break;
        case kSLSkipDatesViewControllerSectionAllHolidays:
            numRows = kSLHolidayCountryNumCountries;

            // remove a row if the device's holiday country is set
            if (self.deviceHolidayCountry != -1) {
                --numRows;
            }
            break;
        case kSLSkipDatesViewControllerSectionAddDate:
        case kSLSkipDatesViewControllerSectionResetDefault:
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
                [self setBackgroundColorsForCell:skipDateCell];
            }
            [self updateSkipDateCellSelectionStyle:skipDateCell];
            
            // customize the cell by grabbing the corresponding skip date
            NSString *skipDateString = [self.customSkipDates objectAtIndex:indexPath.row];
            skipDateCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
            skipDateCell.textLabel.text = [SLPrefsManager skipDateStringForDate:[[SLPrefsManager plistDateFormatter] dateFromString:skipDateString] showRelativeString:NO];
            
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
                [self setBackgroundColorsForCell:addNewDateCell];
            }
            
            // customize the cell
            addNewDateCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
            addNewDateCell.textLabel.text = kSLAddNewDateString;
            
            cell = addNewDateCell;
            break;
        }
        case kSLSkipDatesViewControllerSectionRecommendedHolidays:
            cell = [self tableView:tableView countryCellForHolidayCountry:self.deviceHolidayCountry];
            break;
        case kSLSkipDatesViewControllerSectionAllHolidays:
            cell = [self tableView:tableView countryCellForHolidayCountry:[self offsetHolidayCountryIndexForIndex:indexPath.row increase:YES]];
            break;
        case kSLSkipDatesViewControllerSectionResetDefault: {
            UITableViewCell *resetDefaultCell = [tableView dequeueReusableCellWithIdentifier:kSLResetDefaultTableViewCellIdentifier];
            if (resetDefaultCell == nil) {
                resetDefaultCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:kSLResetDefaultTableViewCellIdentifier];
                resetDefaultCell.accessoryType = UITableViewCellAccessoryNone;
                resetDefaultCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                resetDefaultCell.textLabel.textAlignment = NSTextAlignmentCenter;
                [self setBackgroundColorsForCell:resetDefaultCell];
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

// creates and returns a cell that is used to display a holiday country for the given holiday country identifier
- (UITableViewCell *)tableView:(UITableView *)tableView countryCellForHolidayCountry:(SLHolidayCountry)holidayCountry
{
    UITableViewCell *countryCell = [tableView dequeueReusableCellWithIdentifier:kSLCountriesTableViewCellIdentifier];
    if (countryCell == nil) {
        countryCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                             reuseIdentifier:kSLCountriesTableViewCellIdentifier];
        countryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        countryCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        countryCell.textLabel.textAlignment = NSTextAlignmentLeft;
        [self setBackgroundColorsForCell:countryCell];
    }
    
    // customize the cell
    countryCell.textLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
    countryCell.textLabel.text = [SLPrefsManager friendlyNameForHolidayCountry:holidayCountry];
    
    // display the text for the country different if there are any selected
    NSString *resourceName = [SLPrefsManager resourceNameForHolidayCountry:holidayCountry];
    NSDictionary *holidayResource = [self.holidayResources objectForKey:resourceName];
    NSInteger numTotalAvailableHolidays = [[holidayResource objectForKey:kSLHolidayHolidaysKey] count];
    NSInteger numSelectedHolidays = [[self.holidaySkipDates objectForKey:resourceName] count];
    if (numSelectedHolidays > 0) {
        countryCell.detailTextLabel.text = [NSString stringWithFormat:@"%ld (%@)", (long)numTotalAvailableHolidays, kSLNumberSelectedString(numSelectedHolidays)];
    } else {
        countryCell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)numTotalAvailableHolidays];
    }
    
    return countryCell;
}

// sets some default colors for newly created cells
- (void)setBackgroundColorsForCell:(UITableViewCell *)cell
{
    // on newer versions of iOS, we need to set the background views for the cell
    if (kSLSystemVersioniOS13) {
        cell.backgroundColor = [SLCompatibilityHelper tableViewCellBackgroundColor];
    }

    // set the background color of the cell
    if (@available(iOS 10.0, *)) {
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
        cell.selectedBackgroundView = backgroundView;
    }
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
        case kSLSkipDatesViewControllerSectionAddDate:
            // use a single space for the footer so that the delegate method for the height is called and effectively hidden
            if (self.deviceHolidayCountry == -1) {
                footerTitle = @" ";
            }
            break;
        case kSLSkipDatesViewControllerSectionRecommendedHolidays:
            if (self.deviceHolidayCountry != -1) {
                footerTitle = kSLRecommendedHolidaysExplanationString;
            } else {
                // use a single space for the footer so that the delegate method for the height is called and effectively hidden
                footerTitle = @" ";
            }
            break;
        case kSLSkipDatesViewControllerSectionResetDefault:
            footerTitle = kSLDefaultSkipDatesString;
            break;
    }
    return footerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    switch (section) {
        case kSLSkipDatesViewControllerSectionAllHolidays:
            headerTitle = kSLAllHolidaysString;
            break;
    }
    return headerTitle;
}

#pragma mark - UITableViewDelegate

// handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // set some variables that may be used if editing or adding a new date
    NSString *editDateString = nil;
    self.editingIndexPath = nil;
    
    switch (indexPath.section) {
        case kSLSkipDatesViewControllerSectionDates:
            // if we're in edit mode, grab the existing date to edit
            if (self.isEditing) {
                self.editingIndexPath = indexPath;
                editDateString = [self.customSkipDates objectAtIndex:indexPath.row];
                [self setEditing:NO animated:YES];

                // display the edit date controller
                [self presentEditDateViewControllerWithInitialDate:[[SLPrefsManager plistDateFormatter] dateFromString:editDateString]];

                break;
            } else {
                // if we are not editing, do nothing when these cells are selected
                break;
            }
        case kSLSkipDatesViewControllerSectionAddDate: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            // show the alert controller (i.e. action sheet) that will allow the user to add a new custom skip date
            [self presentSkipDateAlertController];
            break;
        }
        case kSLSkipDatesViewControllerSectionRecommendedHolidays: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self tableView:tableView didSelectHolidayCountry:self.deviceHolidayCountry];
            break;
        }
        case kSLSkipDatesViewControllerSectionAllHolidays: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self tableView:tableView didSelectHolidayCountry:[self offsetHolidayCountryIndexForIndex:indexPath.row increase:YES]];
            break;
        }
        case kSLSkipDatesViewControllerSectionResetDefault: {
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

            // remove any custom skip dates from the table
            [tableView beginUpdates];
            if (customSkipDatesIndexPaths.count > 0) {
                [tableView deleteRowsAtIndexPaths:customSkipDatesIndexPaths
                                 withRowAnimation:UITableViewRowAnimationFade];
            }

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
                    if (holidayCountry == self.deviceHolidayCountry) {
                        [updatedHolidayCountryIndexPaths addObject:[NSIndexPath indexPathForRow:0
                                                                                      inSection:kSLSkipDatesViewControllerSectionRecommendedHolidays]];
                    } else {
                        [updatedHolidayCountryIndexPaths addObject:[NSIndexPath indexPathForRow:holidayCountry
                                                                                      inSection:kSLSkipDatesViewControllerSectionAllHolidays]];
                    }
                }
            }

            // reload any of the country holiday rows in the table
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

// handle cell selection for a holiday cell
- (void)tableView:(UITableView *)tableView didSelectHolidayCountry:(SLHolidayCountry)holidayCountry
{
    // load up the corresponding country to be displayed in the holiday selection controller
    NSString *resourceName = [SLPrefsManager resourceNameForHolidayCountry:holidayCountry];
    if (resourceName != nil) {
        // create a new holiday selection controller with the list of holidays for the user to configure
        SLHolidaySelectionTableViewController *holidaySelectionTableViewController = [[SLHolidaySelectionTableViewController alloc] initWithSelectedHolidays:[self.holidaySkipDates objectForKey:resourceName]
                                                                                                                                             holidayResource:[self.holidayResources objectForKey:resourceName]
                                                                                                                                            inHolidayCountry:holidayCountry];
        holidaySelectionTableViewController.delegate = self;
        [self.navigationController pushViewController:holidaySelectionTableViewController animated:YES];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = UITableViewAutomaticDimension;
    if (self.deviceHolidayCountry == -1 && section == kSLSkipDatesViewControllerSectionRecommendedHolidays) {
        height = 0.1;
    }
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = UITableViewAutomaticDimension;
    if (self.deviceHolidayCountry == -1 && (section == kSLSkipDatesViewControllerSectionRecommendedHolidays || section == kSLSkipDatesViewControllerSectionAddDate)) {
        height = 0.1;
    }
    return height;
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
    // invoke the logic that will add or update the date in our array and table
    [self updateCustomSkipDatesWithSkipDateString:[[SLPrefsManager plistDateFormatter] stringFromDate:date]];
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
    if (self.deviceHolidayCountry == holidayCountry) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:kSLSkipDatesViewControllerSectionRecommendedHolidays]]
                              withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self offsetHolidayCountryIndexForIndex:holidayCountry increase:NO] inSection:kSLSkipDatesViewControllerSectionAllHolidays]]
                          withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
