//
//  SLPartialModalPresentationController.m
//
//  Created by Joshua Seltzer on 1/3/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLPartialModalPresentationController.h"

@interface SLPartialModalPresentationController ()

// the blurred view that will add blur to the presenting view controller background
@property (nonatomic, strong) UIView *blurredView;

// the percentage of the screen that should be displayed for this modal controller
@property (nonatomic) CGFloat partialModalPercentage;

// boolean which signifies whether or not we allow a swipe dismissal for the presented view controller
@property (nonatomic) BOOL allowSwipeDismissal;

@end

@implementation SLPartialModalPresentationController

// create a custom initialization to take in a percentage of how much to show the partial modal on
// the screen
- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController
                       presentingViewController:(UIViewController *)presentingViewController
                         partialModalPercentage:(CGFloat)partialModalPercentage
                            allowSwipeDismissal:(BOOL)allowSwipeDismissal
{
    self = [super initWithPresentedViewController:presentedViewController
                         presentingViewController:presentingViewController];
    if (self) {
        // set the partial modal percentage and swipe ability for this modal presentation
        self.partialModalPercentage = partialModalPercentage;
        self.allowSwipeDismissal = allowSwipeDismissal;
    }
    return self;
}

// override the getter for the blurred view
- (UIView *)blurredView
{
    // lazily load the blurred view once
    if (_blurredView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.containerView.bounds.size.width, self.containerView.bounds.size.height)];
        
        // create a blur affect on the view
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = view.bounds;
        [view addSubview:blurEffectView];
        
        // add a swipe gesture to the blurred view to dismiss the presented view controller if enabled
        if (self.allowSwipeDismissal) {
            UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(blurredViewSwiped:)];
            swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
            [view addGestureRecognizer:swipeGesture];
        }
        
        _blurredView = view;
    }
    
    return _blurredView;
}

// invoked when the user swipes down on the blurred view
- (void)blurredViewSwiped:(UITapGestureRecognizer *)tapGesture
{
    // dismiss the presented view controller
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (CGRect)frameOfPresentedViewInContainerView
{
    // create the frame for the view that will be presented based off of the modal percentage
    return CGRectMake(0.0,
                      self.containerView.bounds.size.height * (1.0 - self.partialModalPercentage),
                      self.containerView.bounds.size.width,
                      self.containerView.bounds.size.height * self.partialModalPercentage);
}

- (void)presentationTransitionWillBegin
{
    if (self.containerView != nil && self.presentingViewController.transitionCoordinator != nil) {
        // add the blurred view to the container view
        self.blurredView.alpha = 0.0;
        [self.containerView addSubview:self.blurredView];
        [self.blurredView addSubview:self.presentedViewController.view];
        
        // animate the alpha of the blurred view
        [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            self.blurredView.alpha = 0.9;
        }
                                                                             completion:nil];
    }
}

- (void)dismissalTransitionWillBegin
{
    if (self.presentingViewController.transitionCoordinator != nil) {
        // animate the alpha of the blurred view
        [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            self.blurredView.alpha = 0.0;
        }
                                                                             completion:nil];
    }
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    // once the transition is completed, destroy the blurred view that was created
    if (completed) {
        [self.blurredView removeFromSuperview];
        self.blurredView = nil;
    }
}

@end
