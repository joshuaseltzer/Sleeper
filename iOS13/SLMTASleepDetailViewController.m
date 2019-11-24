//
//  SLMTASleepDetailViewController.x
//  The view controller which allows the user to change the sleep schedule for the bedtime alarm (iOS 13).
//
//  Created by Joshua Seltzer on 11/22/19.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLPrefsManager.h"
#import "../SLLocalizedStrings.h"
#import "../SLCompatibilityHelper.h"
#import "../SLSnoozeTimeViewController.h"
#import "../SLSkipTimeViewController.h"

// define an enum to reference the sections of the table view
typedef enum SLSleepDetailViewControllerSection : NSUInteger {
    kSLSleepDetailViewControllerSectionScheduleToggle,
    kSLSleepDetailViewControllerSectionDaysOfWeekActive,
    kSLSleepDetailViewControllerNumSections
} SLSleepDetailViewControllerSection;

// custom interface for added properties to the options controller
@interface MTASleepDetailViewController (Sleeper)

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

@end

%hook MTASleepDetailViewController

// potentially customize the footer text depending on whether or not the alarm is going to be skipped
%new
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerTitle = nil;
    if (section == kSLSleepDetailViewControllerSectionDaysOfWeekActive) {
        footerTitle = [self.SLAlarmPrefs skipReasonExplanation];
    }
    return footerTitle;
}

%end

%ctor {
    if (kSLSystemVersioniOS13) {
        %init();
    }
}