#import "JSSkipAlarmAlertItem.h"
#import <UIKit/UIKit.h>

SBAppSwitcherController *controller;

%subclass JSSkipAlarmAlertItem : SBAlertItem

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode
{
    %orig;
    
    self.alertSheet.delegate = self;
    self.alertSheet.title = @"Fuck me?";
    
    [self.alertSheet addButtonWithTitle:@"Yes"];
    [self.alertSheet addButtonWithTitle:@"No"];
    [self.alertSheet addButtonWithTitle:@"Yes (In the Ass)"];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
    [self dismiss];
}

%end