//
//  JSSnoozeTimeViewController.m
//  Sleeper
//
//  Created by Joshua Seltzer on 10/12/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "JSSnoozeTimeViewController.h"
#import "JSPrefsManager.h"

// define constants for the view dictionary when creating constraints
static NSString const *kJSSnoozePickerKey = @"snoozePicker";
static NSString const *kJSOptionTableKey =  @"optionsTableView";

// Constants for the snooze picker per orientation.  These numbers are locked by Apple
static CGFloat const kJSSnoozePickerHeightPortrait = 216.0;
static CGFloat const kJSSnoozePickerHeightLandscape = 162.0;

// constants the define the size of the labels
static CGFloat const kJSSnoozePickerLabelWidth = 45.0;
static CGFloat const kJSSnoozePickerLabelHeight = 60.0;
static CGFloat const KJSSnoozePickerLabelSpaceBetween = kJSSnoozePickerLabelWidth + 10.0;

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

// the hour label for the snooze picker
@property (nonatomic, strong) UILabel *hourLabel;

// the minute label for the snooze picker
@property (nonatomic, strong) UILabel *minuteLabel;

// the second label for the snooze picker
@property (nonatomic, strong) UILabel *secondLabel;

// height constraint that defines the height of the date picker
@property (nonatomic, strong) NSLayoutConstraint *snoozePickerHeightConstraint;

// top space constraint that defines the hour label
@property (nonatomic, strong) NSLayoutConstraint *hourLabelTopConstraint;

// left space constraint that defines the hour label
@property (nonatomic, strong) NSLayoutConstraint *hourLabelLeftConstraint;

// creates the auto layout constraints that apply to the given view and orientation
- (void)createViewConstraintsForView:(UIView *)view orientation:(UIDeviceOrientation)orientiation;

// adjusts the constraints for the snooze picker and labels depending on the given device orientation and size
- (void)adjustSnoozePickerConstraintsForOrientation:(UIDeviceOrientation)orientation size:(CGSize)size;

// returns the snooze picker
- (UIPickerView *)snoozePickerViewWithDelegate:(id)delegate;

// returns the options table
- (UITableView *)optionsTableViewWithDelegate:(id)delegate;

// create the labels that define the different components in the picker view
- (void)createSnoozePickerLabels;

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
    self.title = @"Snooze Time";
    
    // added to account for the navigation bar at the top of the view
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // set the default values of the snooze picker
    [self changePickerTimeWithHours:sJSInitialHours
                            minutes:sJSInitialMinutes
                            seconds:sJSInitialSeconds
                           animated:NO];
    
    // set up the auto layout constraints
    [self createViewConstraintsForView:self.view orientation:[[UIDevice currentDevice] orientation]];
}

// override to create a custom view
- (void)loadView
{
    // create a container view that will contain the rest of the view components
    UIView *containerView = [[UIView alloc] init];
    
    // create the snooze picker
    self.snoozePickerView = [self snoozePickerViewWithDelegate:self];
    
    // create the table view
    self.optionsTableView = [self optionsTableViewWithDelegate:self];
    
    // add the views to our container view
    [containerView addSubview:self.snoozePickerView];
    [containerView addSubview:self.optionsTableView];
    
    // create the labels that are used to describe the snooze picker wheels
    [self createSnoozePickerLabels];
    
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

// invoked when the size of the view changes (e.g. orientation change)
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // adjust the snooze picker constraints for the orientation that we changed to
    [self adjustSnoozePickerConstraintsForOrientation:[[UIDevice currentDevice] orientation] size:size];
}

// creates the auto layout constraints that apply to the given view and orientation
- (void)createViewConstraintsForView:(UIView *)view orientation:(UIDeviceOrientation)orientiation
{
    // create a views dictionary for our constraints
    NSDictionary *viewsDictionary = @{kJSSnoozePickerKey:self.snoozePickerView, kJSOptionTableKey:self.optionsTableView};
    
    // set up the horizontal layout constraints for the snooze picker
    NSString *snoozeLayoutStringH = [NSString stringWithFormat:@"H:|-0-[%@]-0-|", kJSSnoozePickerKey];
    NSArray *snoozeConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:snoozeLayoutStringH
                                                                          options:0
                                                                          metrics:nil
                                                                            views:viewsDictionary];
    
    // set up the horizontal layout constraints for the options table
    NSString *optionsLayoutStringH = [NSString stringWithFormat:@"H:|-0-[%@]-0-|", kJSOptionTableKey];
    NSArray *optionsConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:optionsLayoutStringH
                                                                           options:0
                                                                           metrics:nil
                                                                             views:viewsDictionary];
    
    // set up the vertical layout constraints for the entire view
    NSString *layoutStringV = [NSString stringWithFormat:@"V:|-0-[%@]-0-[%@]-0-|", kJSSnoozePickerKey, kJSOptionTableKey];
    NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:layoutStringV
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewsDictionary];
    
    // create a height constraint on the date picker view that will be set on orientation change
    self.snoozePickerHeightConstraint = [NSLayoutConstraint constraintWithItem:self.snoozePickerView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:0
                                                                    multiplier:1.0
                                                                      constant:0.0];
    
    // create the constraint for the top space for the hour label that is set on orientation change
    self.hourLabelTopConstraint = [NSLayoutConstraint constraintWithItem:self.hourLabel
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.snoozePickerView
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // create the constraint for the left space for the hour label that is set on orientation change
    self.hourLabelLeftConstraint = [NSLayoutConstraint constraintWithItem:self.hourLabel
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.snoozePickerView
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:0.0];
    
    // align the bottoms of the minute and second labels to the hour label
    NSLayoutConstraint *minuteLabelBottomAlignment = [NSLayoutConstraint constraintWithItem:self.minuteLabel
                                                                                  attribute:NSLayoutAttributeBottom
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:self.hourLabel
                                                                                  attribute:NSLayoutAttributeBottom
                                                                                 multiplier:1.0
                                                                                   constant:0.0];
    NSLayoutConstraint *secondLabelBottomAlignment = [NSLayoutConstraint constraintWithItem:self.secondLabel
                                                                                  attribute:NSLayoutAttributeBottom
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:self.hourLabel
                                                                                  attribute:NSLayoutAttributeBottom
                                                                                 multiplier:1.0
                                                                                   constant:0.0];
    
    // align the left sides of the minute and second label to the label right next to it
    NSLayoutConstraint *minuteLabelLeftAlignment = [NSLayoutConstraint constraintWithItem:self.minuteLabel
                                                                                attribute:NSLayoutAttributeLeft
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.hourLabel
                                                                                attribute:NSLayoutAttributeRight
                                                                               multiplier:1.0
                                                                                 constant:KJSSnoozePickerLabelSpaceBetween];
    NSLayoutConstraint *secondLabelLeftAlignment = [NSLayoutConstraint constraintWithItem:self.secondLabel
                                                                                attribute:NSLayoutAttributeLeft
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.minuteLabel
                                                                                attribute:NSLayoutAttributeRight
                                                                               multiplier:1.0
                                                                                 constant:KJSSnoozePickerLabelSpaceBetween];
    
    // create height constraints for all 3 labels
    NSLayoutConstraint *hourLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.hourLabel
                                                                                 attribute:NSLayoutAttributeHeight
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:nil
                                                                                 attribute:0
                                                                                multiplier:1.0
                                                                                  constant:kJSSnoozePickerLabelHeight];
    NSLayoutConstraint *minuteLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.minuteLabel
                                                                                   attribute:NSLayoutAttributeHeight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:nil
                                                                                   attribute:0
                                                                                  multiplier:1.0
                                                                                    constant:kJSSnoozePickerLabelHeight];
    NSLayoutConstraint *secondLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.secondLabel
                                                                                   attribute:NSLayoutAttributeHeight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:nil
                                                                                   attribute:0
                                                                                  multiplier:1.0
                                                                                    constant:kJSSnoozePickerLabelHeight];
    
    // create width constraints for all 3 labels
    NSLayoutConstraint *hourLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.hourLabel
                                                                                attribute:NSLayoutAttributeWidth
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:nil
                                                                                attribute:0
                                                                               multiplier:1.0
                                                                                 constant:kJSSnoozePickerLabelWidth];
    NSLayoutConstraint *minuteLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.minuteLabel
                                                                                  attribute:NSLayoutAttributeWidth
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:nil
                                                                                  attribute:0
                                                                                 multiplier:1.0
                                                                                   constant:kJSSnoozePickerLabelWidth];
    NSLayoutConstraint *secondLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.secondLabel
                                                                                  attribute:NSLayoutAttributeWidth
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:nil
                                                                                  attribute:0
                                                                                 multiplier:1.0
                                                                                   constant:kJSSnoozePickerLabelWidth];
    
    // set up the constraints for the snooze picker and labels depending on what orientation was given
    [self adjustSnoozePickerConstraintsForOrientation:orientiation size:[UIScreen mainScreen].applicationFrame.size];
    
    // add the label constraints to the snooze picker
    [self.snoozePickerView addConstraint:self.hourLabelTopConstraint];
    [self.snoozePickerView addConstraint:minuteLabelBottomAlignment];
    [self.snoozePickerView addConstraint:secondLabelBottomAlignment];
    [self.snoozePickerView addConstraint:self.hourLabelLeftConstraint];
    [self.snoozePickerView addConstraint:minuteLabelLeftAlignment];
    [self.snoozePickerView addConstraint:secondLabelLeftAlignment];
    [self.snoozePickerView addConstraint:hourLabelHeightConstraint];
    [self.snoozePickerView addConstraint:minuteLabelHeightConstraint];
    [self.snoozePickerView addConstraint:secondLabelHeightConstraint];
    [self.snoozePickerView addConstraint:hourLabelWidthConstraint];
    [self.snoozePickerView addConstraint:minuteLabelWidthConstraint];
    [self.snoozePickerView addConstraint:secondLabelWidthConstraint];
    
    // add our constraints to the view
    [view addConstraints:snoozeConstraintsH];
    [view addConstraints:optionsConstraintsH];
    [view addConstraints:constraintsV];
    [view addConstraint:self.snoozePickerHeightConstraint];
}

// adjusts the constraints for the snooze picker and labels depending on the given device orientation and size
- (void)adjustSnoozePickerConstraintsForOrientation:(UIDeviceOrientation)orientation size:(CGSize)size
{
    if (UIDeviceOrientationIsLandscape(orientation)) {
        // change the height of the snooze picker to the landscape height
        self.snoozePickerHeightConstraint.constant = kJSSnoozePickerHeightLandscape;
    } else {
        // change the height of the snooze picker to the portrait height
        self.snoozePickerHeightConstraint.constant = kJSSnoozePickerHeightPortrait;
    }
    
    // adjust the height of the leftmost label
    self.hourLabelTopConstraint.constant = self.snoozePickerHeightConstraint.constant / 2 - kJSSnoozePickerLabelHeight / 2;
    
    // set the left space constraint for the hour label which is dependent on the components in the view
    self.hourLabelLeftConstraint.constant = (size.width - 2 * KJSSnoozePickerLabelSpaceBetween - 2 * kJSSnoozePickerLabelWidth) / 2;
}

// returns the snooze picker
- (UIPickerView *)snoozePickerViewWithDelegate:(id)delegate
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
- (UITableView *)optionsTableViewWithDelegate:(id)delegate
{
    // initialize a table view with the grouped style
    UITableView *optionsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)
                                                                 style:UITableViewStyleGrouped];
    optionsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    optionsTableView.delegate = delegate;
    optionsTableView.dataSource = delegate;
    
    return optionsTableView;
}

// create the labels that define the different components in the picker view
- (void)createSnoozePickerLabels
{
    // create the hour label
    self.hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.hourLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hourLabel.text = @"hours";
    [self.snoozePickerView addSubview:self.hourLabel];
    
    // create the minute label
    self.minuteLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.minuteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.minuteLabel.text = @"min";
    [self.snoozePickerView addSubview:self.minuteLabel];
    
    // create the second label
    self.secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.secondLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.secondLabel.text = @"sec";
    [self.snoozePickerView addSubview:self.secondLabel];
}

// move the snooze time picker to the given hour, minute, and second values
- (void)changePickerTimeWithHours:(NSInteger)hours
                          minutes:(NSInteger)minutes
                          seconds:(NSInteger)seconds
                         animated:(BOOL)animated
{
    // set the default values as defined by our constants
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
    cell.textLabel.text = @"Reset Default";
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
    return [NSString stringWithFormat:@"The default snooze time is %02ld:%02ld:%02ld.", (long)kJSDefaultHour,
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

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component) {
        case kJSHourComponent:
            return 24;
        case kJSMinuteComponent:
        case kJSSecondComponent:
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
    // each component in the picker have the same width, enough to make space for the label
    return kJSSnoozePickerLabelWidth;
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
