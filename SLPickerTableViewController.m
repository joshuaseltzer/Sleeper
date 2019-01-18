//
//  SLPickerTableViewController.m
//  Custom view controller with a time picker (hours, minutes, and seconds) on top with a table view on the bottom.
//
//  Created by Joshua Seltzer on 9/24/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

#import "SLPickerTableViewController.h"
#import "SLLocalizedStrings.h"
#import "SLCompatibilityHelper.h"

// define constants for the view dictionary when creating constraints
static NSString *const kSLTimePickerViewKey =       @"timePickerView";
static NSString *const kSLOptionTableViewKey =      @"optionsTableView";
static NSString *const kSLLabelContainerViewKey =   @"labelContainerView";
static NSString *const kSLHourLabelViewKey =        @"hourLabelView";
static NSString *const kSLMinuteLabelViewKey =      @"minuteLabelView";
static NSString *const kSLSecondLabelViewKey =      @"secondLabelView";

// Constants for the time picker height per orientation.  These numbers are locked by Apple.
static CGFloat const kSLTimePickerHeightPortrait = 216.0;
static CGFloat const kSLTimePickerHeightLandscape = 162.0;

// constants for the widths of the components in the time picker
static CGFloat const kSLTimePickerWidth = 320;
static CGFloat const kSLTimePickerLabelComponentWidth = 42.0;
static CGFloat const kSLTimePickerHiddenComponentWidth = 57.0;

// constants the define the size and layout of the labels
static CGFloat const kSLTimePickerLabelHeight = 60.0;
static CGFloat const kSLTimePickerLabelSpaceBetween = 45.0;
static CGFloat const kSLTimePickerLabelLeadingSpace = 10.0;
static CGFloat const kSLTimePickerLabelWidth = (kSLTimePickerWidth - kSLTimePickerLabelLeadingSpace
                                                  - kSLTimePickerLabelSpaceBetween * 3) / 3;

// constants that define the location of the valued components in our time picker
static NSInteger const kSLHourComponent =   0;
static NSInteger const kSLMinuteComponent = 2;
static NSInteger const kSLSecondComponent = 4;

@interface SLPickerTableViewController ()

// the time picker view, which takes up the top part of the view
@property (nonatomic, strong) UIPickerView *timePickerView;

// the view which contains the different labels for the time picker
@property (nonatomic, strong) UIView *labelContainerView;

// the hour label for the time picker
@property (nonatomic, strong) UILabel *hourLabel;

// the minute label for the time picker
@property (nonatomic, strong) UILabel *minuteLabel;

// the second label for the time picker
@property (nonatomic, strong) UILabel *secondLabel;

// height constraint that defines the height of the time picker
@property (nonatomic, strong) NSLayoutConstraint *timePickerHeightConstraint;

// top space constraint that defines the Y position of the label container view
@property (nonatomic, strong) NSLayoutConstraint *labelContainerViewTopConstraint;

// the initial hours for the picker view
@property (nonatomic) NSInteger initialHours;

// the initial minutes for the picker view
@property (nonatomic) NSInteger initialMinutes;

// the initial seconds for the picker view
@property (nonatomic) NSInteger initialSeconds;

// creates the auto layout constraints that will depend on the orientation given
- (void)createViewConstraintsForInitialOrientation:(UIInterfaceOrientation)orientiation;

// adjusts the constraints for the time picker and label view depending on the given orientation
- (void)adjustTimePickerConstraintsForOrientation:(UIInterfaceOrientation)orientation;

// returns the time picker
- (UIPickerView *)createTimePickerViewWithDelegate:(id)delegate;

// returns the options table
- (UITableView *)createOptionsTableViewWithDelegate:(id)delegate;

// returns the view that contains all of the labels for the time picker
- (UIView *)createLabelContainerView;

@end

@implementation SLPickerTableViewController

// custom initialization method that sets the picker to the initial times given
- (id)initWithHours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds
{
    self = [super init];
    if (self) {
        // save the initial times
        self.initialHours = hours;
        self.initialMinutes = minutes;
        self.initialSeconds = seconds;
    }
    return self;
}

// override to customize the view upon load
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // added to account for the navigation bar at the top of the view
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // set the default values of the time picker
    [self changePickerTimeWithHours:self.initialHours
                            minutes:self.initialMinutes
                            seconds:self.initialSeconds
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
    
    // create the time picker
    self.timePickerView = [self createTimePickerViewWithDelegate:self];
    
    // create the table view
    self.optionsTableView = [self createOptionsTableViewWithDelegate:self];
    
    // add the views to our container view
    [containerView addSubview:self.timePickerView];
    [containerView addSubview:self.optionsTableView];
    
    // create the labels that are used to describe the time picker wheels
    self.labelContainerView = [self createLabelContainerView];
    
    // add the label container view to the time picker
    [self.timePickerView addSubview:self.labelContainerView];
    
    // set the view of this controller to the container view
    self.view = containerView;
}

// invoked when the given view is moving to the parent view controller
- (void)willMoveToParentViewController:(UIViewController *)parent
{
    // if the parent is nil, we know we are popping this view controller
    if (!parent && self.delegate) {
        // tell the delegate about the updated picker times
        [self.delegate SLPickerTableViewController:self
                                didUpdateWithHours:[self.timePickerView selectedRowInComponent:kSLHourComponent]
                                           minutes:[self.timePickerView selectedRowInComponent:kSLMinuteComponent]
                                           seconds:[self.timePickerView selectedRowInComponent:kSLSecondComponent]];
    }
}

// creates the auto layout constraints that will depend on the orientation given
- (void)createViewConstraintsForInitialOrientation:(UIInterfaceOrientation)orientiation
{
    // create view dictionaries for our constraints
    NSDictionary *mainViewDictionary = @{kSLTimePickerViewKey:self.timePickerView,
                                         kSLOptionTableViewKey:self.optionsTableView};
    NSDictionary *labelViewDictionary = @{kSLLabelContainerViewKey:self.labelContainerView,
                                          kSLHourLabelViewKey:self.hourLabel,
                                          kSLMinuteLabelViewKey:self.minuteLabel,
                                          kSLSecondLabelViewKey:self.secondLabel};
    
    // set up the horizontal layout constraints for the time picker
    NSString *pickerLayoutStringH = [NSString stringWithFormat:@"H:|-0-[%@]-0-|", kSLTimePickerViewKey];
    NSArray *pickerConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:pickerLayoutStringH
                                                                          options:0
                                                                          metrics:nil
                                                                            views:mainViewDictionary];
    
    // set up the horizontal layout constraints for the options table
    NSString *optionsLayoutStringH = [NSString stringWithFormat:@"H:|-0-[%@]-0-|", kSLOptionTableViewKey];
    NSArray *optionsConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:optionsLayoutStringH
                                                                           options:0
                                                                           metrics:nil
                                                                             views:mainViewDictionary];
    
    // set up the vertical layout constraints for the entire view
    NSString *layoutStringV = [NSString stringWithFormat:@"V:|-0-[%@]-0-[%@]-0-|", kSLTimePickerViewKey,
                               kSLOptionTableViewKey];
    NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:layoutStringV
                                                                    options:0
                                                                    metrics:nil
                                                                      views:mainViewDictionary];
    
    // create a height constraint on thetimedate picker view that will be set on orientation change
    self.timePickerHeightConstraint = [NSLayoutConstraint constraintWithItem:self.timePickerView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:0
                                                                    multiplier:1.0
                                                                      constant:0.0];
    
    // set up the horizontal layout for all of the time picker labels
    NSString *labelLayoutStringH = [NSString stringWithFormat:@"H:|-%f-[%@(%f)]-%f-[%@(%f)]-%f-[%@(%f)]-0-|",
                                    kSLTimePickerLabelSpaceBetween + kSLTimePickerLabelLeadingSpace,
                                    kSLHourLabelViewKey, kSLTimePickerLabelWidth,
                                    kSLTimePickerLabelSpaceBetween, kSLMinuteLabelViewKey,
                                    kSLTimePickerLabelWidth, kSLTimePickerLabelSpaceBetween,
                                    kSLSecondLabelViewKey, kSLTimePickerLabelWidth];
    
    // if the device supports right to left orientation display, then use leading to trailing direction
    NSLayoutFormatOptions formatOption = NSLayoutFormatDirectionLeftToRight;
    if ([[UIView class] respondsToSelector:@selector(userInterfaceLayoutDirectionForSemanticContentAttribute:)] &&
        [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.view.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft) {
        formatOption = NSLayoutFormatDirectionLeadingToTrailing;
    }
    
    // generate the array of horizontal constraints
    NSArray *labelConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:labelLayoutStringH
                                                                         options:formatOption
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
                                                                                  constant:kSLTimePickerLabelHeight];
    NSLayoutConstraint *minuteLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.minuteLabel
                                                                                   attribute:NSLayoutAttributeHeight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:0
                                                                                   attribute:0
                                                                                  multiplier:1.0
                                                                                    constant:kSLTimePickerLabelHeight];
    NSLayoutConstraint *secondLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.secondLabel
                                                                                   attribute:NSLayoutAttributeHeight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:0
                                                                                   attribute:0
                                                                                  multiplier:1.0
                                                                                    constant:kSLTimePickerLabelHeight];
    
    // create the contraints that define the label container view
    self.labelContainerViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.timePickerView
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0
                                                                         constant:0.0];
    NSLayoutConstraint *labelContainerViewXConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:self.timePickerView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                    multiplier:1.0
                                                                                      constant:0.0];
    NSLayoutConstraint *labelContainerViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                                         attribute:NSLayoutAttributeWidth
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:nil
                                                                                         attribute:0
                                                                                        multiplier:1.0
                                                                                          constant:kSLTimePickerWidth];
    NSLayoutConstraint *labelContainerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.labelContainerView
                                                                                          attribute:NSLayoutAttributeHeight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:nil
                                                                                          attribute:0
                                                                                         multiplier:1.0
                                                                                           constant:kSLTimePickerLabelHeight];
    
    // set up the constraints for the time picker and labels depending on what orientation was given
    [self adjustTimePickerConstraintsForOrientation:orientiation];
    
    // add the individual label constraints to the label container
    [self.labelContainerView addConstraints:labelConstraintsH];
    [self.labelContainerView addConstraint:hourLabelYConstraint];
    [self.labelContainerView addConstraint:minuteLabelYConstraint];
    [self.labelContainerView addConstraint:secondLabelYConstraint];
    [self.labelContainerView addConstraint:hourLabelHeightConstraint];
    [self.labelContainerView addConstraint:minuteLabelHeightConstraint];
    [self.labelContainerView addConstraint:secondLabelHeightConstraint];
    
    // add the label container constraints to the time picker view
    [self.timePickerView addConstraint:self.labelContainerViewTopConstraint];
    [self.timePickerView addConstraint:labelContainerViewXConstraint];
    [self.timePickerView addConstraint:labelContainerViewWidthConstraint];
    [self.timePickerView addConstraint:labelContainerViewHeightConstraint];
    
    // add our constraints to the parent view
    [self.view addConstraints:pickerConstraintsH];
    [self.view addConstraints:optionsConstraintsH];
    [self.view addConstraints:constraintsV];
    [self.view addConstraint:self.timePickerHeightConstraint];
}

// adjusts the constraints for the time picker and label view depending on the given device orientation
- (void)adjustTimePickerConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        // change the height of the time picker to the landscape height
        self.timePickerHeightConstraint.constant = kSLTimePickerHeightLandscape;
    } else {
        // change the height of the time picker to the portrait height
        self.timePickerHeightConstraint.constant = kSLTimePickerHeightPortrait;
    }
    
    // adjust the height of the leftmost label
    self.labelContainerViewTopConstraint.constant = self.timePickerHeightConstraint.constant / 2 - kSLTimePickerLabelHeight / 2;
}

// returns the time picker
- (UIPickerView *)createTimePickerViewWithDelegate:(id)delegate
{
    // programatically create the time picker
    UIPickerView *timePicker = [[UIPickerView alloc] init];
    timePicker.translatesAutoresizingMaskIntoConstraints = NO;
    timePicker.backgroundColor = [SLCompatibilityHelper pickerViewBackgroundColor];
    timePicker.delegate = delegate;
    timePicker.dataSource = delegate;
    
    return timePicker;
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

// returns the view that contains all of the labels for the time picker
- (UIView *)createLabelContainerView
{
    // create the container view which will contain the time picker labels
    UIView *labelContainerView = [[UIView alloc] init];
    labelContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // if the device supports right to left display, then change the text alignment we use for the
    // labels
    NSTextAlignment labelTextAlignment = NSTextAlignmentLeft;
    if ([[UIView class] respondsToSelector:@selector(userInterfaceLayoutDirectionForSemanticContentAttribute:)]) {
        labelTextAlignment = NSTextAlignmentNatural;
    }
    
    // create the hour label
    self.hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.hourLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hourLabel.textAlignment = labelTextAlignment;
    self.hourLabel.adjustsFontSizeToFitWidth = YES;
    self.hourLabel.minimumScaleFactor = 8.0 / self.hourLabel.font.pointSize;
    self.hourLabel.text = kSLHoursString;
    self.hourLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
    [labelContainerView addSubview:self.hourLabel];
    
    // create the minute label
    self.minuteLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.minuteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.minuteLabel.textAlignment = labelTextAlignment;
    self.minuteLabel.adjustsFontSizeToFitWidth = YES;
    self.minuteLabel.minimumScaleFactor = 8.0 / self.hourLabel.font.pointSize;
    self.minuteLabel.text = kSLMinutesString;
    self.minuteLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
    [labelContainerView addSubview:self.minuteLabel];
    
    // create the second label
    self.secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    self.secondLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.secondLabel.textAlignment = labelTextAlignment;
    self.secondLabel.adjustsFontSizeToFitWidth = YES;
    self.secondLabel.minimumScaleFactor = 8.0 / self.hourLabel.font.pointSize;
    self.secondLabel.text = kSLSecondsString;
    self.secondLabel.textColor = [SLCompatibilityHelper defaultLabelColor];
    [labelContainerView addSubview:self.secondLabel];
    
    return labelContainerView;
}

// move the time time picker to the given hour, minute, and second values
- (void)changePickerTimeWithHours:(NSInteger)hours
                          minutes:(NSInteger)minutes
                          seconds:(NSInteger)seconds
                         animated:(BOOL)animated
{
    // set the values of the picker view to the specified values with or without animation
    [self.timePickerView selectRow:hours inComponent:kSLHourComponent animated:animated];
    [self.timePickerView selectRow:minutes inComponent:kSLMinuteComponent animated:animated];
    [self.timePickerView selectRow:seconds inComponent:kSLSecondComponent animated:animated];
}

#pragma mark - UIPickerViewDataSource

// return the number of components in the picker view
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    // there are 3 real components, and 3 hidden ones to make room for the labels
    return 6;
}

// return the number of rows for each component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component) {
        case kSLHourComponent:
            // ability to choose between 24 hours
            return 24;
        case kSLMinuteComponent:
        case kSLSecondComponent:
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
        case kSLHourComponent:
        case kSLMinuteComponent:
        case kSLSecondComponent:
            // the components which have options to show have a particular width
            return kSLTimePickerLabelComponentWidth;
        default:
            // the hidden components have a width that is enough to make room for the labels
            return kSLTimePickerHiddenComponentWidth;
    }
}

// handled when a component's row changes
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // disallow a picker time of all zeroes
    if ([pickerView selectedRowInComponent:kSLHourComponent] == 0 &&
        [pickerView selectedRowInComponent:kSLMinuteComponent] == 0 &&
        [pickerView selectedRowInComponent:kSLSecondComponent] == 0) {
        // move the last selected component to the first position
        [pickerView selectRow:1 inComponent:component animated:YES];
    }
}

// handled for setting the text of the picker view
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    // update the text to include the correct color and the row text
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)row]
                                                                     attributes:@{NSForegroundColorAttributeName:[SLCompatibilityHelper defaultLabelColor]}];

    return attrString;
}

@end
