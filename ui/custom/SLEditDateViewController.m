//
//  SLEditDateViewController.m
//
//  Created by Joshua Seltzer on 1/3/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLEditDateViewController.h"
#import "../../common/SLCompatibilityHelper.h"
#import "../../common/SLLocalizedStrings.h"

// define constants for the view dictionary when creating constraints
#define kSLDatePickerViewKey            @"datePickerView"

// enum that defines the selectable components in the time picker
typedef enum XFTEditTimePickerViewComponent : NSInteger {
    kXFTEditTimePickerViewComponentMinutes,
    kXFTEditTimePickerViewComponentSeconds,
    kXFTEditTimePickerViewComponentHidden,
    kXFTEditTimePickerViewNumComponents
} XFTEditTimePickerViewComponent;

@interface SLEditDateViewController ()

// the picker view which is responsible for showing the minutes and seconds for picking a time
@property (nonatomic, strong) UIDatePicker *datePickerView;

// the optional initial date
@property (nonatomic, strong) NSDate *initialDate;

// the optional minimum date
@property (nonatomic, strong) NSDate *minimumDate;

// the optional maximum date
@property (nonatomic, strong) NSDate *maximumDate;

@end

@implementation SLEditDateViewController

// initialize this controller with a required title and optional dates
- (instancetype)initWithTitle:(NSString *)title initialDate:(NSDate *)initialDate minimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate
{
    self = [super init];
    if (self) {
        self.navigationItem.title = title;
        self.initialDate = initialDate;
        self.minimumDate = minimumDate;
        self.maximumDate = maximumDate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create and customize the date picker
    self.datePickerView = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    self.datePickerView.datePickerMode = UIDatePickerModeDate;
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
                                                                                   constant:kSLEditDatePickerViewHeight];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// invoked when the user presses the cancel button
- (void)cancelButtonPressed:(UIBarButtonItem *)cancelButton
{
    // dismiss the controller
    [self dismissViewControllerAnimated:YES completion:^{
        // tell the delegate that the date selection was cancelled
        if (self.delegate != nil && [self.delegate conformsToProtocol:@protocol(SLEditDateViewControllerDelegate)]) {
            [self.delegate SLEditDateViewController:self didCancelDate:self.datePickerView.date];
        }
    }];
}

// invoked when the user presses the save button
- (void)saveButtonPressed:(UIBarButtonItem *)saveButton
{
    // dismiss the controller
    [self dismissViewControllerAnimated:YES completion:^{
        // tell the delegate about the saved selected date
        if (self.delegate != nil && [self.delegate conformsToProtocol:@protocol(SLEditDateViewControllerDelegate)]) {
            [self.delegate SLEditDateViewController:self didSaveDate:self.datePickerView.date];
        }
    }];
}

@end
