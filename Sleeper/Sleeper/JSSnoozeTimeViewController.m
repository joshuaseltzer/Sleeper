//
//  JSSnoozeTimeViewController.m
//  Sleeper
//
//  Created by Joshua Seltzer on 10/12/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "JSSnoozeTimeViewController.h"
#import "JSPrefsManager.h"
#import "JSLocalizedStrings.h"

// define constants for the view dictionary when creating constraints
static NSString *const kJSSnoozePickerKey =         @"snoozePicker";
static NSString *const kJSOptionTableKey =          @"optionsTableView";
static NSString *const kJSLabelContainerViewKey =   @"labelContainerView";
static NSString *const kJSHourLabelKey =            @"hourLabelView";
static NSString *const kJSMinuteLabelKey =          @"minuteLabelView";
static NSString *const kJSSecondLabelKey =          @"secondLabelView";

// Constants for the snooze picker height per orientation.  These numbers are locked by Apple
static CGFloat const kJSSnoozePickerHeightPortrait = 216.0;
static CGFloat const kJSSnoozePickerHeightLandscape = 162.0;

// constants for the widths of the components in the snooze picker
static CGFloat const kJSSnoozePickerWidth = 320;
static CGFloat const kJSSnoozePickerLabelComponentWidth = 36.0;
static CGFloat const kJSSnoozePickerHiddenComponentWidth = 59.0;

// constants the define the size and layout of the labels
static CGFloat const kJSSnoozePickerLabelHeight = 60.0;
static CGFloat const kJSSnoozePickerLabelSpaceBetween = 40.0;
static CGFloat const kJSSnoozePickerLabelLeadingSpace = 8.0;
static CGFloat const kJSSnoozePickerLabelWidth = (kJSSnoozePickerWidth - kJSSnoozePickerLabelLeadingSpace
                                                  - kJSSnoozePickerLabelSpaceBetween * 3) / 3;

// constants that define the location of the valued components in our picker
static NSInteger const kJSHourComponent =   0;
static NSInteger const kJSMinuteComponent = 2;
static NSInteger const kJSSecondComponent = 4;

// static variables to define the initial values of the snooze time
static NSInteger sJSInitialHours;
static NSInteger sJSInitialMinutes;
static NSInteger sJSInitialSeconds;

@interface JSSnoozeTimeViewController ()

// the snooze picker view, which takes up the top part of the view
@property (nonatomic, strong) UIPickerView *snoozePickerView;

// the options table which will take up the rest of the view
@property (nonatomic, strong) UITableView *optionsTableView;

// the view which contains the different labels for the snooze picker
@property (nonatomic, strong) UIView *labelContainerView;

// the hour label for the snooze picker
@property (nonatomic, strong) UILabel *hourLabel;

// the minute label for the snooze picker
@property (nonatomic, strong) UILabel *minuteLabel;

// the second label for the snooze picker
@property (nonatomic, strong) UILabel *secondLabel;

// height constraint that defines the height of the date picker
@property (nonatomic, strong) NSLayoutConstraint *snoozePickerHeightConstraint;

// top space constraint that defines the Y position of the label container view
@property (nonatomic, strong) NSLayoutConstraint *labelContainerViewTopConstraint;

// creates the auto layout constraints that will depend on the orientation given
- (void)createViewConstraintsForInitialOrientation:(UIInterfaceOrientation)orientiation;

// adjusts the constraints for the snooze picker and label view depending on the given orientation
- (void)adjustSnoozePickerConstraintsForOrientation:(UIInterfaceOrientation)orientation;

// returns the snooze picker
- (UIPickerView *)createSnoozePickerViewWithDelegate:(id)delegate;

// returns the options table
- (UITableView *)createOptionsTableViewWithDelegate:(id)delegate;

// returns the view that contains all of the labels for the snooze picker
- (UIView *)createLabelContainerView;

// move the snooze time picker to the given hour, minute, and second values
- (void)changePickerTimeWithHours:(NSInteger)hours
                          minutes:(NSInteger)minutes
                          seconds:(NSInteger)seconds
                         animated:(BOOL)animated;

@end

@implementation JSSnoozeTimeViewController

// custom initialization method that sets the picker to the initial times given
- (id)initWithHours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds
{
    self = [super init];
    if (self) {
        // save the initial times
        sJSInitialHours = hours;
        sJSInitialMinutes = minutes;
        sJSInitialSeconds = seconds;
    }
    return self;
}

// override to customize the view upon load
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title of the view controller
    self.title = LZ_SNOOZE_TIME;
    
    // added to account for the navigation bar at the top of the view
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // set the default values of the snooze picker
    [self changePickerTimeWithHours:sJSInitialHours
                            minutes:sJSInitialMinutes
                            seconds:sJSInitialSeconds
                           animated:NO];
    
    // Set up the auto layout constraints depending on the current orientation.  On an iPad, we only
    // display the app in a portrait orientation
    UIInterfaceOrientation orientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        orientation = [[UIApplication sharedApplication] statusBarOrientation];
    } else {
        orientation = UIInterfaceOrientationPortrait;
    }
    [self createViewConstraintsForInitialOrientation:orientation];
}

// override to create a custom view
- (void)loadView
{
    // create a container view that will contain the rest of the view components
    UIView *containerView = [[UIView alloc] init];
    
    // create the snooze picker
    self.snoozePickerView = [self createSnoozePickerViewWithDelegate:self];
    
    // create the table view
    self.optionsTableView = [self createOptionsTableViewWithDelegate:self];
    
    // add the views to our container view
    [containerView addSubview:self.snoozePickerView];
    [containerView addSubview:self.optionsTableView];
    
    // create the labels that are used to describe the snooze picker wheels
    self.labelContainerView = [self createLabelContainerView];
    
    // add the label container view to the snooze picker
    [self.snoozePickerView addSubview:self.labelContainerView];
    
    // set the view of this controller to the container view
    self.view = containerView;
}

// invoked when the given view is moving to the parent view controller
- (void)willMoveToParentViewController:(UIViewController *)parent
{
    // if the parent is nil, we know we are popping this view controller
    if (!parent && self.delegate) {
        // tell the delegate about the updated snooze times
        [self.delegate alarmDidUpdateWithHours:[self.snoozePickerView selectedRowInComponent:kJSHourComponent]
                                       minutes:[self.snoozePickerView selectedRowInComponent:kJSMinuteComponent]
                                       seconds:[self.snoozePickerView selectedRowInComponent:kJSSecondComponent]];
    }
}

// Invoked when the size of the view changes (e.g. orientation change).  This is an iOS8 only
// implementation since the API has changed.  This is irrelevent to iOS7 since the iOS7 Clock app
// does not support rotation.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Animate the view changes if we are on an iPhone.  On the iPad, this orientation does not need
    // to change since the popover view is the same size in either orientation.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // adjust the snooze picker constraints for the orientation that we changed to
            [self adjustSnoozePickerConstraintsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        } completion:nil];
    }
}

// creates the auto layout constraints that will depend on the orientation given
- (void)createViewConstraintsForInitialOrientation:(UIInterfaceOrientation)orientiation
{
    // create view dictionaries for our constraints
    NSDictionary *mainViewDictionary = @{kJSSnoozePickerKey:self.snoozePickerView, kJSOptionTableKey:self.optionsTableView};
    NSDictionary *labelViewDictionary = @{kJSLabelContainerViewKey:self.labelContainerView, kJSHourLabelKey:self.hourLabel,
                                          kJSMinuteLabelKey:self.minuteLabel, kJSSecondLabelKey:self.secondLabel};
    
    // set up the horizontal layout constraints for the snooze picker
    NSString *snoozeLayoutStringH = [NSString stringWithFormat:@"H:|-0-[%@]-0-|", kJSSnoozePickerKey];
    NSArray *snoozeConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:snoozeLayoutStringH
                                                                          options:0
                                                                          metrics:nil
                                                                            views:mainViewDictionary];
    
    // set up the horizontal layout constraints for the options table
    NSString *optionsLayoutStringH = [NSString stringWithFormat:@"H:|-0-[%@]-0-|", kJSOptionTableKey];
    NSArray *optionsConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:optionsLayoutStringH
                                                                           options:0
                                                                           metrics:nil
                                                                             views:mainViewDictionary];
    
    // set up the vertical layout constraints for the entire view
    NSString *layoutStringV = [NSString stringWithFormat:@"V:|-0-[%@]-0-[%@]-0-|", kJSSnoozePickerKey, kJSOptionTableKey];
    NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:layoutStringV
                                                                    options:0
                                                                    metrics:nil
                                                                      views:mainViewDictionary];
    
    // create a height constraint on the date picker view that will be set on orientation change
    self.snoozePickerHeightConstraint = [NSLayoutConstraint constraintWithItem:self.snoozePickerView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:0
                                                                    multiplier:1.0
                                                                      constant:0.0];
    
    // set up the horizontal layout for all of the snooze picker labels
    NSString *labelLayoutStringH = [NSString stringWithFormat:@"H:|-%f-[%@(%f)]-%f-[%@(%f)]-%f-[%@(%f)]-0-|",
                                    kJSSnoozePickerLabelSpaceBetween + kJSSnoozePickerLabelLeadingSpace,
                                    kJSHourLabelKey, kJSSnoozePickerLabelWidth, kJSSnoozePickerLabelSpaceBetween,
                                    kJSMinuteLabelKey, kJSSnoozePickerLabelWidth, kJSSnoozePickerLabelSpaceBetween,
                                    kJSSecondLabelKey, kJSSnoozePickerLabelWidth];
    NSArray *labelConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:labelLayoutStringH
                                                                         options:NSLayoutFormatDirectionLeftToRight
                                                                         metrics:nil
                                                                           views:labelViewDictionary];
    
    // create the Y position constraints for each label
    NSLayoutConstraint *hourLabelYConstraint = [NSLayoutConstraint constraintWithItem:self.hourLabel
                                                                            attribute:NSLayoutAttributeCenterY
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.labelContainerView
                                                                            attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.0
                                                                             constant:0.0];
    NSLayoutConstraint *minuteLabelYConstraint = [NSLayoutConstraint constraintWithItem:self.minuteLabel
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.labelContainerView
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.0
                                                                               constant:0.0];
    NSLayoutConstraint *secondLabelYConstraint = [NSLayoutConstraint constraintWithItem:self.secondLabel
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.labelContainerView
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.0
                                                                               constant:0.0];
    
    // create the height constraints for each label
    NSLayoutConstraint *hourLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.hourLabel
                                                                                 attribute:NSLayoutAttributeHeight
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:0
                                                                                 attribute:0
                                                                                multiplier:1.0
                                                                                  constant:kJSSnoozePickerLabelHeight];
    NSLayoutConstraint *minuteLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.minuteLabel
                                                                                   attribute:NSLayoutAttributeHeight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:0
                                                                                   attribute:0
                                                                                  multiplier:1.0
                                                                                    constant:kJSSnoozePickerLabelHeight];
    NSLayoutConstraint *secondLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.secondLabel
                                                                                   attribute:NSLayoutAttributeHeight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:0
                                                                                   attribute:0
                                                                                  multiplier:1.0
                                                                                    constant:kJSSnoozePickerLabelHeight];
    
    // create the contraints that define the label container view
    self.labelContainerViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.snoozePickerView
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0
                                                                         constant:0.0];
    NSLayoutConstraint *labelContainerViewXConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:self.snoozePickerView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                    multiplier:1.0
                                                                                      constant:0.0];
    NSLayoutConstraint *labelContainerViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                                         attribute:NSLayoutAttributeWidth
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:nil
                                                                                         attribute:0
                                                                                        multiplier:1.0
                                                                                          constant:kJSSnoozePickerWidth];
    NSLayoutConstraint *labelContainerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                                          attribute:NSLayoutAttributeHeight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:nil
                                                                                          attribute:0
                                                                                         multiplier:1.0
                                                                                           constant:kJSSnoozePickerLabelHeight];
    
    // set up the constraints for the snooze picker and labels depending on what orientation was given
    [self adjustSnoozePickerConstraintsForOrientation:orientiation];
    
    // add the individual label constraints to the label container
    [self.labelContainerView addConstraints:labelConstraintsH];
    [self.labelContainerView addConstraint:hourLabelYConstraint];
    [self.labelContainerView addConstraint:minuteLabelYConstraint];
    [self.labelContainerView addConstraint:secondLabelYConstraint];
    [self.labelContainerView addConstraint:hourLabelHeightConstraint];
    [self.labelContainerView addConstraint:minuteLabelHeightConstraint];
    [self.labelContainerView addConstraint:secondLabelHeightConstraint];
    
    // add the label container constraints to the snooze picker view
    [self.snoozePickerView addConstraint:self.labelContainerViewTopConstraint];
    [self.snoozePickerView addConstraint:labelContainerViewXConstraint];
    [self.snoozePickerView addConstraint:labelContainerViewWidthConstraint];
    [self.snoozePickerView addConstraint:labelContainerViewHeightConstraint];
    
    // add our constraints to the parent view
    [self.view addConstraints:snoozeConstraintsH];
    [self.view addConstraints:optionsConstraintsH];
    [self.view addConstraints:constraintsV];
    [self.view addConstraint:self.snoozePickerHeightConstraint];
}

// adjusts the constraints for the snooze picker and label view depending on the given device orientation
- (void)adjustSnoozePickerConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        // change the height of the snooze picker to the landscape height
        self.snoozePickerHeightConstraint.constant = kJSSnoozePickerHeightLandscape;
    } else {
        // change the height of the snooze picker to the portrait height
        self.snoozePickerHeightConstraint.constant = kJSSnoozePickerHeightPortrait;
    }
    
    // adjust the height of the leftmost label
    self.labelContainerViewTopConstraint.constant = self.snoozePickerHeightConstraint.constant / 2 - kJSSnoozePickerLabelHeight / 2;
}

// returns the snooze picker
- (UIPickerView *)createSnoozePickerViewWithDelegate:(id)delegate
{
    // programatically create the snooze picker
    UIPickerView *snoozePickerView = [[UIPickerView alloc] init];
    snoozePickerView.translatesAutoresizingMaskIntoConstraints = NO;
    snoozePickerView.backgroundColor = [UIColor whiteColor];
    snoozePickerView.delegate = delegate;
    snoozePickerView.dataSource = delegate;
    
    return snoozePickerView;
}

// returns the options table
- (UITableView *)createOptionsTableViewWithDelegate:(id)delegate
{
    // initialize a table view with the grouped style
    UITableView *optionsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)
                                                                 style:UITableViewStyleGrouped];
    optionsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    optionsTableView.delegate = delegate;
    optionsTableView.dataSource = delegate;
    
    return optionsTableView;
}

// returns the view that contains all of the labels for the snooze picker
- (UIView *)createLabelContainerView
{
    // create the container view which will contain the snooze picker labels
    UIView *labelContainerView = [[UIView alloc] init];
    labelContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // create the hour label
    self.hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.hourLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hourLabel.textAlignment = NSTextAlignmentLeft;
    self.hourLabel.adjustsFontSizeToFitWidth = YES;
    self.hourLabel.minimumScaleFactor = 8.0 / self.hourLabel.font.pointSize;
    self.hourLabel.text = LZ_HOURS;
    [labelContainerView addSubview:self.hourLabel];
    
    // create the minute label
    self.minuteLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.minuteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.minuteLabel.textAlignment = NSTextAlignmentLeft;
    self.minuteLabel.adjustsFontSizeToFitWidth = YES;
    self.minuteLabel.minimumScaleFactor = 8.0 / self.hourLabel.font.pointSize;
    self.minuteLabel.text = LZ_MINUTES;
    [labelContainerView addSubview:self.minuteLabel];
    
    // create the second label
    self.secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.secondLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.secondLabel.textAlignment = NSTextAlignmentLeft;
    self.secondLabel.adjustsFontSizeToFitWidth = YES;
    self.secondLabel.minimumScaleFactor = 8.0 / self.hourLabel.font.pointSize;
    self.secondLabel.text = LZ_SECONDS;
    [labelContainerView addSubview:self.secondLabel];
    
    return labelContainerView;
}

// move the snooze time picker to the given hour, minute, and second values
- (void)changePickerTimeWithHours:(NSInteger)hours
                          minutes:(NSInteger)minutes
                          seconds:(NSInteger)seconds
                         animated:(BOOL)animated
{
    // set the values of the picker view to the specified values with or without animation
    [self.snoozePickerView selectRow:hours inComponent:kJSHourComponent animated:animated];
    [self.snoozePickerView selectRow:minutes inComponent:kJSMinuteComponent animated:animated];
    [self.snoozePickerView selectRow:seconds inComponent:kJSSecondComponent animated:animated];
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
    }
    
    // customize the cell text and alignment
    cell.textLabel.text = LZ_RESET_DEFAULT;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    // set the color of the button to the red, destructive color as defined by Apple in other cells
    cell.textLabel.textColor = [UIColor colorWithRed:1.0f
                                               green:0.231373f
                                                blue:0.188235f
                                               alpha:1.0f];
    
    return cell;
}

// return a footer view for each table view section
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // We only have one section which defines the default snooze button.  Display a message indicating
    // to the user what the default snooze time is
    return [NSString stringWithFormat:@"%@ %02ld:%02ld:%02ld.", LZ_DEFAULT_SNOOZE_TIME, (long)kJSDefaultHour,
            (long)kJSDefaultMinute, (long)kJSDefaultSecond];
}

#pragma mark - UITableViewDelegate

// handle table view cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // for now, we only have one button so we can assume it is the one that resets the default snooze
    // picker values
    [self changePickerTimeWithHours:kJSDefaultHour
                            minutes:kJSDefaultMinute
                            seconds:kJSDefaultSecond
                           animated:YES];
    
    // deselect the row with animation
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIPickerViewDataSource

// return the number of components in the picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    // there are 3 real components, and 3 hidden ones to make room for the labels
    return 6;
}

// return the number of rows for each component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component) {
        case kJSHourComponent:
            // ability to choose between 24 hours
            return 24;
        case kJSMinuteComponent:
        case kJSSecondComponent:
            // ability to choose between 60 minutes/seconds
            return 60;
        default:
            // for the hidden rows, return nothing
            return 0;
    }
}

#pragma mark - UIPickerViewDelegate

// return the width of a paritcular row in a component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    switch (component) {
        case kJSHourComponent:
        case kJSMinuteComponent:
        case kJSSecondComponent:
            // the components which have options to show have a particular width
            return kJSSnoozePickerLabelComponentWidth;
        default:
            // the hidden components have a width that is enough to make room for the labels
            return kJSSnoozePickerHiddenComponentWidth;
    }
}

// returns the title of a particular row for a particular component in the picker view
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    // the title returned is simply the number of the row
    return [NSString stringWithFormat:@"%ld", (long)row];
}

// handled when a component's row changes
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // disallow a snooze time of all zeroes
    if ([pickerView selectedRowInComponent:kJSHourComponent] == 0 &&
        [pickerView selectedRowInComponent:kJSMinuteComponent] == 0 &&
        [pickerView selectedRowInComponent:kJSSecondComponent] == 0) {
        // move the last selected component to the first position
        [pickerView selectRow:1 inComponent:component animated:YES];
    }
}

@end
