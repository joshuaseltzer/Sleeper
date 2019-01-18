//
//  SLPartialModalPresentationController.h
//
//  Created by Joshua Seltzer on 1/3/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <UIKit/UIKit.h>

// the custom presentation controller which is used to display a partial modal controller
@interface SLPartialModalPresentationController : UIPresentationController

// create a custom initialization to take in a percentage of how much to show the partial modal on
// the screen and whether or not we can swipe to dismiss the presented controller
- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController
                       presentingViewController:(UIViewController *)presentingViewController
                         partialModalPercentage:(CGFloat)partialModalPercentage
                            allowSwipeDismissal:(BOOL)allowSwipeDismissal;

@end
