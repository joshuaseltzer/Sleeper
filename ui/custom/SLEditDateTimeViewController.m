//
//  SLEditDateTimeViewController.m
//
//  Created by Joshua Seltzer on 1/3/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLEditDateTimeViewController.h"
#import "../../common/SLCompatibilityHelper.h"
#import "../../common/SLLocalizedStrings.h"

// define constants for the view dictionary when creating constraints
#define kSLDatePickerViewKey            @"datePickerView"

// define the private view that is used to handle the UIDatePicker's data source
@interface _UIDatePickerView : UIPickerView
@end

@interface SLEditDateTimeViewController ()

// the picker view which is responsible for showing the date or hours/minutes
@property (nonatomic, strong) UIDatePicker *datePickerView;

// the mode that the picker will be using
@property (nonatomic) UIDatePickerMode datePickerMode;

// the optional initial date
@property (nonatomic, strong) NSDate *initialDate;

// the optional minimum date
@property (nonatomic, strong) NSDate *minimumDate;

// the optional maximum date
@property (nonatomic, strong) NSDate *maximumDate;

// the optional initial hours
@property (nonatomic) NSInteger initialHours;

// the optional initial minutes
@property (nonatomic) NSInteger initialMinutes;

// the optional maximum hours
@property (nonatomic) NSInteger maximumHours;

@end

@implementation SLEditDateTimeViewController

// Initialize this controller with a required title and optional dates.  Using this initilizer will put the picker in date mode.
- (instancetype)initWithTitle:(NSString *)title initialDate:(NSDate *)initialDate minimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate
{
    self = [super init];
    if (self) {
        self.navigationItem.title = title;
        self.initialDate = initialDate;
        self.minimumDate = minimumDate;
        self.maximumDate = maximumDate;
        self.datePickerMode = UIDatePickerModeDate;
    }
    return self;
}

// Initialize this controller with a required title and optional hour/minutes.  Using this initilizer will put the picker in countdown timer mode.
- (instancetype)initWithTitle:(NSString *)title initialHours:(NSInteger)initialHours initialMinutes:(NSInteger)initialMinutes maximumHours:(NSInteger)maximumHours
{
    self = [super init];
    if (self) {
        self.navigationItem.title = title;
        self.initialHours = initialHours;
        self.initialMinutes = initialMinutes;
        self.maximumHours = maximumHours;
        self.datePickerMode = UIDatePickerModeCountDownTimer;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create and customize the date picker's view
    self.datePickerView = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    self.datePickerView.datePickerMode = self.datePickerMode;
    self.datePickerView.backgroundColor = [SLCompatibilityHelper pickerViewBackgroundColor];
    self.view.backgroundColor = [SLCompatibilityHelper pickerViewBackgroundColor];
    [self.datePickerView setValue:[SLCompatibilityHelper defaultLabelColor] forKey:@"textColor"];
    self.datePickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.datePickerView];
    
    // set up the constraints for the date picker
    NSLayoutConstraint *pickerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.datePickerView
                                                                                  attribute:NSLayoutAttributeHeight
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:nil
                                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                                 multiplier:1.0
                                                                                   constant:kSLEditDateTimePickerViewHeight];
    NSLayoutConstraint *pickerViewYConstraint = [NSLayoutConstraint constraintWithItem:self.datePickerView
                                                                             attribute:NSLayoutAttributeBottom
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.view
                                                                             attribute:NSLayoutAttributeBottom
                                                                            multiplier:1.0
                                                                              constant:0.0];
    NSLayoutConstraint *pickerViewXConstraint = [NSLayoutConstraint constraintWithItem:self.datePickerView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.view
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0
                                                                              constant:0.0];
    [self.view addConstraints:@[pickerViewHeightConstraint, pickerViewYConstraint, pickerViewXConstraint]];

    // configure the date picker either with the supplied date properties or hour/minute properties
    if (self.datePickerMode == UIDatePickerModeDate) {
        if (self.minimumDate != nil) {
            [self.datePickerView setMinimumDate:self.minimumDate];
        } else {
            [self.datePickerView setMinimumDate:[NSDate date]];
        }
        if (self.maximumDate != nil) {
            [self.datePickerView setMaximumDate:self.maximumDate];
        }
        if (self.initialDate != nil) {
            self.datePickerView.date = self.initialDate;
        }
    } else if (self.datePickerMode == UIDatePickerModeCountDownTimer) {
        self.datePickerView.countDownDuration = self.initialHours * 60 * 60 + self.initialMinutes * 60;

        // grab the private _UIDatePickerView so that we can implement the data source to set the maximum hours and minutes
        _UIDatePickerView *datePickerView = [self.datePickerView valueForKey:@"_pickerView"];
        if (datePickerView != nil) {
            datePickerView.dataSource = self;
        }
    }
    
    // create a cancel button to dismiss changes
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:kSLCancelString
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    // create a save button to save changes and dismiss the controller
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:kSLSaveString
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(saveButtonPressed:)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

// invoked when the user presses the cancel button
- (void)cancelButtonPressed:(UIBarButtonItem *)cancelButton
{
    // dismiss the controller
    [self dismissViewControllerAnimated:YES completion:^{
        // tell the delegate that the date selection was cancelled
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(SLEditDateTimeViewControllerDidCancelSelection:)]) {
            [self.delegate SLEditDateTimeViewControllerDidCancelSelection:self];
        }
    }];
}

// invoked when the user presses the save button
- (void)saveButtonPressed:(UIBarButtonItem *)saveButton
{
    // dismiss the controller
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate != nil) {
            if (self.datePickerMode == UIDatePickerModeDate && [self.delegate respondsToSelector:@selector(SLEditDateTimeViewController:didSaveDate:)]) {
                // tell the delegate about the selected date
                [self.delegate SLEditDateTimeViewController:self didSaveDate:self.datePickerView.date];
            } else if (self.datePickerMode == UIDatePickerModeCountDownTimer && [self.delegate respondsToSelector:@selector(SLEditDateTimeViewController:didSaveHours:andMinutes:)]) {
                // tell the delegate about the selected hours/minutes
                [self.delegate SLEditDateTimeViewController:self didSaveHours:(self.datePickerView.countDownDuration / 3600) andMinutes:(NSInteger)(self.datePickerView.countDownDuration / 60) % 60];
            }
        }
    }];
}

// allow this view controller to be shown even when the device is in secure mode
- (BOOL)_canShowWhileLocked
{
    return YES;
}

#pragma mark - UIPickerViewDataSource

// the components to return are for the hours and minutes
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// return the number of rows for each component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{

    switch (component) {
        case 0:
            // set the number of hours as defined during initialization
            return self.maximumHours;
        case 1:
            // a default UIDatePicker uses this value for the minutes to make it appear to wrap indefinitely
            return 10000;
        default:
            return 0;
    }
}

@end
