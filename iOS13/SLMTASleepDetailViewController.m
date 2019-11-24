//
//  SLMTASleepDetailViewController.x
//  The view controller which allows the user to change the sleep schedule for the bedtime alarm (iOS 13).
//
//  Created by Joshua Seltzer on 11/22/19.
//
//

#import "../SLAppleSharedInterfaces.h"
#import "../SLPrefsManager.h"
#import "../SLCompatibilityHelper.h"

// define an enum to reference the sections of the table view
typedef enum SLSleepDetailViewControllerSection : NSUInteger {
    kSLSleepDetailViewControllerSectionScheduleToggle,
    kSLSleepDetailViewControllerSectionDaysOfWeekActive,
    kSLSleepDetailViewControllerNumSections
} SLSleepDetailViewControllerSection;

@interface MTASleepDetailViewController : UITableViewController

// define the data source, which will include the sleep alarm
@property (retain, nonatomic) MTAlarmDataSource *dataSource;

@end

// custom interface for added properties to the options controller
@interface MTASleepDetailViewController (Sleeper)

@property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

@end

%hook MTASleepDetailViewController

// the Sleeper preferences for the special sleep alarm
%property (nonatomic, retain) SLAlarmPrefs *SLAlarmPrefs;

- (void)viewDidLoad
{
    // Load the preferences for the sleep alarm.  The only reason we need the alarm preferences for this controller is to
    // potentially display the skip explanation string in the footer.
    NSString *alarmId = [self.dataSource.sleepAlarm alarmIDString];
    self.SLAlarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];

    %orig;
}

// Override with no implementation to prevent the footer string from being overridden.
// As of iOS 13.2.2, this seems to be unused code / a bug since it is not shown unless we implement the
// "titleForFooterInSection" delegate method.
- (void)updateFooterWithSchedule:(NSInteger)schedule {}

// potentially customize the footer text depending on whether or not the alarm is going to be skipped
%new
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerTitle = nil;
    if (self.SLAlarmPrefs != nil && section == kSLSleepDetailViewControllerSectionScheduleToggle) {
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