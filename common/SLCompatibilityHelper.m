//
//  SLCompatibilityHelper.m
//  Functions that are used to maintain system compatibility between different iOS versions.
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

#import "SLCompatibilityHelper.h"
#import "SLLocalizedStrings.h"
#import "SLPrefsManager.h"
#import <objc/runtime.h>

// the name of the image files as it exists in the bundle
#define kSLCheckmarkImageName           @"checkmark"
#define kSLOpenInImageName              @"open_in"

@interface LSApplicationProxy : NSObject

// returns an application proxy object that corresponds to the given bundle identifier
+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)identifier;

// returns weather or not the application corresponding to this application proxy is installed on the device
- (BOOL)isInstalled;

@end

@interface LSApplicationWorkspace : NSObject

// returns the default app workspace for the device (i.e. shared instance)
+ (id)defaultWorkspace;

// opens the application on the device corresponding to the given bundle identifier
- (BOOL)openApplicationWithBundleID:(NSString *)bundleId;

@end

// define some properties that are defined in the iOS 13 SDK for UIColor
@interface UIColor (iOS13)

+ (UIColor *)systemGroupedBackgroundColor;
+ (UIColor *)secondarySystemGroupedBackgroundColor;
+ (UIColor *)quaternaryLabelColor;

@end

// define an extension to UIView to allow for customization of a UIAlertController's background colors using associated objects
@interface UIView (AssociatedObject)

@property (nonatomic, strong) id subviewsBackgroundColor;

@end

@implementation UIView (AssociatedObject)
@dynamic subviewsBackgroundColor;

- (id)subviewsBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(subviewsBackgroundColor));
}
- (void)setSubviewsBackgroundColor:(id)color
{
    objc_setAssociatedObject(self, @selector(subviewsBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    for (UIView *subview in self.subviews) {
        subview.backgroundColor = color;
    }
}

@end

// define some static color objects that will be used throughout the UI
static UIColor *sSLPickerViewBackgroundColor = nil;
static UIColor *sSLDefaultLabelColor = nil;
static UIColor *sSLDestructiveLabelColor = nil;
static UIColor *sSLTableViewCellBackgroundColor = nil;
static UIColor *sSLTableViewCellSelectedBackgroundColor = nil;
static UIColor *sSLAlertControllerDarkBackgroundColor = nil;
static UIColor *sSLAlertControllerDarkLineSeparatorColor = nil;

// keep a single, static instance of the UIImages used throughout the UI
static UIImage *sSLCheckmarkImage;
static UIImage *sSLOpenInImage;

// define the bundle identifier used for the weather application (required for auto-set)
static NSString *const kSLWeatherAppBundleId = @"com.apple.weather";

@implementation SLCompatibilityHelper

// iOS 8 / iOS 9: modifies a snooze UIConcreteLocalNotification object with the selected snooze time (if applicable)
+ (void)modifySnoozeNotificationForLocalNotification:(UIConcreteLocalNotification *)localNotification
{
    // grab the alarm Id from the notification
    NSString *alarmId = [localNotification.userInfo objectForKey:kSLAlarmIdKey];

    // check to see if a modified snooze time is available to set on this notification record
    NSDate *modifiedSnoozeDate = [SLCompatibilityHelper modifiedSnoozeDateForAlarmId:alarmId withOriginalDate:localNotification.fireDate];
    if (modifiedSnoozeDate) {
        localNotification.fireDate = modifiedSnoozeDate;
    }
}

// iOS 10 / iOS 11: modifies a snooze UNSNotificationRecord object with the selected snooze time (if applicable)
+ (void)modifySnoozeNotificationForNotificationRecord:(UNSNotificationRecord *)notificationRecord
{
    // grab the alarm Id from the notification record
    NSString *alarmId = [notificationRecord.userInfo objectForKey:kSLAlarmIdKey];

    // check to see if a modified snooze time is available to set on this notification record
    NSDate *modifiedSnoozeDate = [SLCompatibilityHelper modifiedSnoozeDateForAlarmId:alarmId withOriginalDate:notificationRecord.triggerDate];
    if (modifiedSnoozeDate) {
        [notificationRecord setTriggerDate:modifiedSnoozeDate];
    }
}

// Returns a modified NSDate object with an appropriately modified snooze time for a given alarm Id and original date
// Returns nil if no modified snooze date is available
+ (NSDate *)modifiedSnoozeDateForAlarmId:(NSString *)alarmId withOriginalDate:(NSDate *)originalDate
{
    // check to see if we have an updated snooze time for this alarm
    NSDate *modifiedSnoozeDate = nil;
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs != nil) {
        // subtract the default snooze time from these values since they have already been added to
        // the fire date
        NSInteger hours = alarmPrefs.snoozeTimeHour - kSLDefaultSnoozeHour;
        NSInteger minutes = alarmPrefs.snoozeTimeMinute - kSLDefaultSnoozeMinute;
        NSInteger seconds = alarmPrefs.snoozeTimeSecond - kSLDefaultSnoozeSecond;
        
        // convert the entire value into seconds
        NSTimeInterval timeInterval = hours * 3600 + minutes * 60 + seconds;
        
        // create the modified date from the original date
        modifiedSnoozeDate = [originalDate dateByAddingTimeInterval:timeInterval];
    }
    return modifiedSnoozeDate;
}

// iOS 8 / iOS 9: Returns the next skippable alarm local notification.  If there is no skippable notification found, return nil.
+ (UIConcreteLocalNotification *)nextSkippableAlarmLocalNotification
{
    // create a comparator block to sort the array of notifications
    NSComparisonResult (^notificationComparator) (UIConcreteLocalNotification *, UIConcreteLocalNotification *) =
    ^(UIConcreteLocalNotification *lhs, UIConcreteLocalNotification *rhs) {
        // get the next fire date of the left hand side notification
        NSDate *lhsNextFireDate = [lhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        // get the next fire date of the right hand side notification
        NSDate *rhsNextFireDate = [rhs nextFireDateAfterDate:[NSDate date]
                                               localTimeZone:[NSTimeZone localTimeZone]];
        
        return [lhsNextFireDate compare:rhsNextFireDate];
    };
    
    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = (SBClockDataProvider *)[objc_getClass("SBClockDataProvider") sharedInstance];
    
    // get the scheduled notifications from the SBClockDataProvider (iOS 8) or the SBClockNotificationManager (iOS 9)
    NSArray *scheduledNotifications = nil;
    if (kSLSystemVersioniOS9) {
        // grab the shared instance of the clock notification manager for the scheduled notifications
        SBClockNotificationManager *clockNotificationManager = (SBClockNotificationManager *)[objc_getClass("SBClockNotificationManager") sharedInstance];
        scheduledNotifications = [clockNotificationManager scheduledLocalNotifications];
    } else {
        // get the scheduled notifications from the clock data provider
        scheduledNotifications = [clockDataProvider _scheduledNotifications];
    }
    
    // take the scheduled notifications and sort them by earliest date
    NSArray *sortedNotifications = [scheduledNotifications sortedArrayUsingComparator:notificationComparator];
    
    // iterate through all of the notifications that are scheduled
    UIConcreteLocalNotification *nextLocalNotification = nil;
    for (UIConcreteLocalNotification *notification in sortedNotifications) {
        // only continue checking if the given notification is an alarm notification and did not
        // originate from a snooze action
        if ([clockDataProvider _isAlarmNotification:notification] && ![Alarm isSnoozeNotification:notification]) {
            // grab the alarm Id from the notification
            NSString *alarmId = [clockDataProvider _alarmIDFromNotification:notification];
            
            // check to see if this notification is skippable
            if ([SLCompatibilityHelper isAlarmLocalNotificationSkippable:notification forAlarmId:alarmId]) {
                // since the array is sorted we know that this is the earliest skippable notification
                nextLocalNotification = notification;
                break;
            }
        }
    }
    
    return nextLocalNotification;
}

// iOS 10 / iOS 11: Returns the next skippable alarm notification request given an array of notification requests.
// If there is no skippable notification found, return nil.
+ (UNNotificationRequest *)nextSkippableAlarmNotificationRequestForNotificationRequests:(NSArray *)notificationRequests
{
    // create a comparator block to sort the array of notification requests
    NSComparisonResult (^notificationRequestComparator) (UNNotificationRequest *, UNNotificationRequest *) =
    ^(UNNotificationRequest *lhs, UNNotificationRequest *rhs) {
        // get the next trigger date of the left hand side notification request
        if ([lhs.trigger isKindOfClass:objc_getClass("UNLegacyNotificationTrigger")] && [rhs.trigger isKindOfClass:objc_getClass("UNLegacyNotificationTrigger")]) {
            NSDate *lhsTriggerDate = [((UNLegacyNotificationTrigger *)lhs.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                           withRequestedDate:nil
                                                                                             defaultTimeZone:[NSTimeZone localTimeZone]];
            
            // get the next trigger date of the right hand side notification request
            NSDate *rhsTriggerDate = [((UNLegacyNotificationTrigger *)rhs.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                           withRequestedDate:nil
                                                                                             defaultTimeZone:[NSTimeZone localTimeZone]];

            return [lhsTriggerDate compare:rhsTriggerDate];
        } else {
            return NSOrderedSame;
        }
    };

    // grab the shared instance of the clock data provider
    SBClockDataProvider *clockDataProvider = (SBClockDataProvider *)[objc_getClass("SBClockDataProvider") sharedInstance];
    
    // take the scheduled notifications and sort them by earliest date by using the sort descriptor
    NSArray *sortedNotificationRequests = [notificationRequests sortedArrayUsingComparator:notificationRequestComparator];

    // iterate through all of the notifications that are scheduled
    UNNotificationRequest *nextNotificationRequest = nil;
    for (UNNotificationRequest *notificationRequest in sortedNotificationRequests) {
        // only continue checking if the given notification is an alarm notification and did not
        // originate from a snooze action
        if ([clockDataProvider _isAlarmNotificationRequest:notificationRequest] && ![notificationRequest.content isFromSnooze]) {
            // grab the alarm Id from the notification request
            NSString *alarmId = [clockDataProvider _alarmIDFromNotificationRequest:notificationRequest];

            // check to see if this notification request is skippable
            if ([SLCompatibilityHelper isAlarmNotificationRequestSkippable:notificationRequest forAlarmId:alarmId]) {
                // since the array is sorted we know that this is the earliest skippable notification
                nextNotificationRequest = notificationRequest;
                break;
            }
        }
    }

    return nextNotificationRequest;
}

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm
{
    // check the version of iOS that the device is running to determine where to get the alarm Id
    NSString *alarmId = nil;
    if (kSLSystemVersioniOS9 || kSLSystemVersioniOS10 || kSLSystemVersioniOS11) {
        alarmId = alarm.alarmID;
    } else {
        alarmId = alarm.alarmId;
    }
    return alarmId;
}

// returns the appropriate title string for a given alarm object
+ (NSString *)alarmTitleForAlarm:(Alarm *)alarm
{
    // check the version of iOS that the device is running along with any indication that the alarm is the sleep alarm
    NSString *alarmTitle = nil;
    if ((kSLSystemVersioniOS10 || kSLSystemVersioniOS11) && [alarm isSleepAlarm]) {
        alarmTitle = kSLSleepAlarmString;
    } else {
        alarmTitle = alarm.uiTitle;
    }
    return alarmTitle;
}

// returns the picker view's background color, which will depend on the iOS version
+ (UIColor *)pickerViewBackgroundColor
{
    // check the version of iOS that the device is running to determine which color to pick
    if (!sSLPickerViewBackgroundColor) {
        if (kSLSystemVersioniOS13) {
            if (@available(iOS 13.0, *)) {
                // use the new system grouped background color if available
                sSLPickerViewBackgroundColor = [UIColor systemGroupedBackgroundColor];
            } else {
                // fallback to the color that was extracted from the time picker
                sSLPickerViewBackgroundColor = [UIColor colorWithRed:0.109804 green:0.109804 blue:0.117647 alpha:1.0];
            }
        } else if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11 || kSLSystemVersioniOS12) {
            sSLPickerViewBackgroundColor = [UIColor blackColor];
        } else {
            sSLPickerViewBackgroundColor = [UIColor whiteColor];
        }
    }

    return sSLPickerViewBackgroundColor;
}

// returns the color of the standard labels used throughout the tweak
+ (UIColor *)defaultLabelColor
{
    // check the version of iOS that the device is running to determine which color to pick
    if (!sSLDefaultLabelColor) {
        if (kSLSystemVersioniOS10 || kSLSystemVersioniOS11 || kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
            sSLDefaultLabelColor = [UIColor whiteColor];
        } else {
            sSLDefaultLabelColor = [UIColor blackColor];
        }
    }
    
    return sSLDefaultLabelColor;
}

// returns the color of the destructive labels used throughout the tweak
+ (UIColor *)destructiveLabelColor
{
    if (!sSLDestructiveLabelColor) {
        sSLDestructiveLabelColor = [UIColor colorWithRed:1.0
                                                   green:0.231373
                                                    blue:0.188235
                                                   alpha:1.0];
    }
    return sSLDestructiveLabelColor;
}

// iOS 13: returns the background color used for cells used in the various views
+ (UIColor *)tableViewCellBackgroundColor
{
    if (!sSLTableViewCellBackgroundColor) {
        if (@available(iOS 13.0, *)) {
            sSLTableViewCellBackgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        } else {
            sSLTableViewCellBackgroundColor = [UIColor colorWithRed:0.172549 green:0.172549 blue:0.180392 alpha:1.0];
        }
    }
    return sSLTableViewCellBackgroundColor;
}

// iOS 10, iOS 11, iOS 12, iOS 13: returns the cell selection background color for cells
+ (UIColor *)tableViewCellSelectedBackgroundColor
{
    if (!sSLTableViewCellSelectedBackgroundColor) {
        if (kSLSystemVersioniOS13) {
            if (@available(iOS 13.0, *)) {
                sSLTableViewCellSelectedBackgroundColor = [UIColor quaternaryLabelColor];
            } else {
                sSLTableViewCellSelectedBackgroundColor = [UIColor colorWithRed:0.921569 green:0.921569 blue:0.960784 alpha:180000];
            }
        } else {
            sSLTableViewCellSelectedBackgroundColor = [UIColor colorWithRed:52.0 / 255.0
                                                                      green:52.0 / 255.0
                                                                       blue:52.0 / 255.0
                                                                      alpha:1.0];
        }
    }
    return sSLTableViewCellSelectedBackgroundColor;
}

// iOS 10, iOS 11, iOS 12: returns the custom background color applied to some of the subviews contained in a UIAlertController to mimic the dark appearance
// Note this is not necessary in iOS 13 since the alert controller uses the native dark mode APIs
+ (UIColor *)alertControllerDarkBackgroundColor
{
    if (!sSLAlertControllerDarkBackgroundColor) {
        sSLAlertControllerDarkBackgroundColor = [UIColor colorWithRed:41.0 / 255.0
                                                                green:41.0 / 255.0
                                                                 blue:41.0 / 255.0
                                                                alpha:1.0];
    }
    return sSLAlertControllerDarkBackgroundColor;
}

// iOS 10, iOS 11, iOS 12: returns the custom background color for the line separators that are used in UIAlertControllers
// Note this is not necessary in iOS 13 since the alert controller uses the native dark mode APIs
+ (UIColor *)alertControllerDarkLineSeparatorColor
{
    if (!sSLAlertControllerDarkLineSeparatorColor) {
        sSLAlertControllerDarkLineSeparatorColor = [UIColor colorWithRed:101.0 / 255.0
                                                                   green:101.0 / 255.0
                                                                    blue:101.0 / 255.0
                                                                   alpha:1.0];
    }
    return sSLAlertControllerDarkLineSeparatorColor;
}

// modifies an alert controller's subviews appropriately if necessary for the current version of iOS
+ (void)updateSubviewsForAlertController:(UIAlertController *)alertController
{
    // iterate through the alert controller's subviews to set the background color of the action buttons (not including the cancel buttons)
    UIView *firstSubview = alertController.view.subviews.firstObject;
    if (firstSubview != nil && firstSubview.subviews.count > 0) {
        UIView *secondSubview = firstSubview.subviews.firstObject;
        for (UIView *subview in secondSubview.subviews) {
            subview.backgroundColor = [SLCompatibilityHelper alertControllerDarkBackgroundColor];
        }
    }

    // for alert styles of UIAlertController, update the title and message font color
    if (alertController.preferredStyle == UIAlertControllerStyleAlert) {
        // modify the title and message text with the correct foreground color
        NSMutableAttributedString *modifiedTitle = [[NSMutableAttributedString alloc] initWithString:alertController.title];
        [modifiedTitle addAttribute:NSForegroundColorAttributeName value:[SLCompatibilityHelper defaultLabelColor] range:NSMakeRange(0, alertController.title.length)];
        [modifiedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:NSMakeRange(0, alertController.title.length)];
        [alertController setValue:modifiedTitle forKey:@"attributedTitle"];
        NSMutableAttributedString *modifiedMessage = [[NSMutableAttributedString alloc] initWithString:alertController.message];
        [modifiedMessage addAttribute:NSForegroundColorAttributeName value:[SLCompatibilityHelper defaultLabelColor] range:NSMakeRange(0, alertController.message.length)];
        [modifiedMessage addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13.0] range:NSMakeRange(0, alertController.message.length)];
        [alertController setValue:modifiedMessage forKey:@"attributedMessage"];
    }
}

// Uses the appearance API to modify the look and feel of a UIAlertController's various views for the current version of iOS
// This method will take care of coloring the header of the alert (only for action sheet alerts), the cancel button, and the separator lines
+ (void)updateDefaultUIAlertControllerAppearance
{
    // modify the header view of an alert controller (only applicable to UIAlertControllerStyleActionSheet)
    ((UIView *)[NSClassFromString(@"_UIInterfaceActionGroupHeaderScrollView") appearance]).subviewsBackgroundColor = [SLCompatibilityHelper alertControllerDarkBackgroundColor];
    
    // modify the cancel button's background view
    ((UIView *)[NSClassFromString(@"_UIAlertControlleriOSActionSheetCancelBackgroundView") appearance]).subviewsBackgroundColor = [SLCompatibilityHelper alertControllerDarkBackgroundColor];

    // modify the colors of various views to display the selection of the action correctly
    ((UIView *)[NSClassFromString(@"_UIBlendingHighlightView") appearanceWhenContainedIn:NSClassFromString(@"_UIInterfaceActionCustomViewRepresentationView"), nil]).backgroundColor = [SLCompatibilityHelper tableViewCellSelectedBackgroundColor];
    ((UIView *)[NSClassFromString(@"_UIBlendingHighlightView") appearanceWhenContainedIn:NSClassFromString(@"_UIAlertControlleriOSActionSheetCancelBackgroundView"), nil]).alpha = 0.92;
    ((UIView *)[NSClassFromString(@"_UIBlendingHighlightView") appearanceWhenContainedIn:NSClassFromString(@"_UIInterfaceActionCustomViewRepresentationView"), nil]).subviewsBackgroundColor = [UIColor clearColor];

    // modify the separator line colors
    ((UIView *)[NSClassFromString(@"_UIInterfaceActionItemSeparatorView_iOS") appearance]).backgroundColor = [SLCompatibilityHelper alertControllerDarkLineSeparatorColor];
    ((UIView *)[NSClassFromString(@"_UIInterfaceActionItemSeparatorView_iOS") appearance]).subviewsBackgroundColor = [UIColor clearColor];
}

// iOS 8 / iOS 9: helper function that will investigate an alarm local notification and alarm Id to see if it is skippable
+ (BOOL)isAlarmLocalNotificationSkippable:(UIConcreteLocalNotification *)localNotification
                               forAlarmId:(NSString *)alarmId
{
    // get the fire date of the notification we are checking
    NSDate *nextFireDate = [localNotification nextFireDateAfterDate:[NSDate date]
                                                      localTimeZone:[NSTimeZone localTimeZone]];
    
    return [SLCompatibilityHelper isAlarmSkippableForAlarmId:alarmId withNextFireDate:nextFireDate];
}

// iOS 10 / iOS 11: helper function that will investigate an alarm notification request and alarm Id to see if it is skippable
+ (BOOL)isAlarmNotificationRequestSkippable:(UNNotificationRequest *)notificationRequest
                                 forAlarmId:(NSString *)alarmId
{
    BOOL skippable = NO;
    if ([notificationRequest.trigger isKindOfClass:objc_getClass("UNLegacyNotificationTrigger")]) {
        // get the fire date of the alarm we are checking
        NSDate *nextTriggerDate = [((UNLegacyNotificationTrigger *)notificationRequest.trigger) _nextTriggerDateAfterDate:[NSDate date]
                                                                                                        withRequestedDate:nil
                                                                                                          defaultTimeZone:[NSTimeZone localTimeZone]];
        
        skippable = [SLCompatibilityHelper isAlarmSkippableForAlarmId:alarmId withNextFireDate:nextTriggerDate];
    }
    
    return skippable;
}

// returns whether or not an alarm is skippable based on the alarm Id
+ (BOOL)isAlarmSkippableForAlarmId:(NSString *)alarmId withNextFireDate:(NSDate *)nextFireDate
{
    // grab the attributes for the alarm
    BOOL skippable = NO;
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    if (alarmPrefs && ![alarmPrefs shouldSkipOnDate:nextFireDate] && alarmPrefs.skipEnabled && alarmPrefs.skipActivationStatus == kSLSkipActivatedStatusUnknown) {
        // create a date components object with the user's selected skip time to see if we are within
        // the threshold to ask the user to skip the alarm
        NSDateComponents *components= [[NSDateComponents alloc] init];
        [components setHour:alarmPrefs.skipTimeHour];
        [components setMinute:alarmPrefs.skipTimeMinute];
        [components setSecond:alarmPrefs.skipTimeSecond];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // create a date that is the amount of time ahead of the current date
        NSDate *thresholdDate = [calendar dateByAddingComponents:components
                                                          toDate:[NSDate date]
                                                         options:0];
        
        // compare the dates to see if this notification is skippable
        skippable = [nextFireDate compare:thresholdDate] == NSOrderedAscending;
    }
    return skippable;
}

// returns the checkmark image used to indicate selection throughout the UI
+ (UIImage *)checkmarkImage
{
    if (!sSLCheckmarkImage) {
        sSLCheckmarkImage = [[UIImage imageNamed:kSLCheckmarkImageName
                                        inBundle:kSLSleeperBundle
                   compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return sSLCheckmarkImage;
}

// returns the "open in" image
+ (UIImage *)openInImage
{
    if (!sSLOpenInImage) {
        sSLOpenInImage = [[UIImage imageNamed:kSLOpenInImageName
                                     inBundle:kSLSleeperBundle
                compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return sSLOpenInImage;
}

// returns whether or not the device is in a state that can use the auto-set feature
+ (BOOL)canEnableAutoSet
{
    // attempt to get the application proxy for the weather application
    LSApplicationProxy *weatherAppProxy = [objc_getClass("LSApplicationProxy") applicationProxyForIdentifier:kSLWeatherAppBundleId];
    if (weatherAppProxy != nil && [weatherAppProxy respondsToSelector:@selector(isInstalled)] && [weatherAppProxy isInstalled]) {
        return YES;
    } else {
        return NO;
    }
}

// navigates the user to the Weather application
+ (void)openWeatherApplication
{
    LSApplicationWorkspace *appWorkspace = [objc_getClass("LSApplicationWorkspace") defaultWorkspace];
    if (appWorkspace != nil && [appWorkspace respondsToSelector:@selector(openApplicationWithBundleID:)]) {
        [appWorkspace openApplicationWithBundleID:kSLWeatherAppBundleId];
    }
}

// Updates the given alarms (represented as SLAlarmPref dictionaries) with the base hour and base minute.
// The implementation of updating the alarms will differ depending on which iOS is currently running.
+ (void)updateAlarms:(NSArray *)alarms withBaseHour:(NSInteger)baseHour withBaseMinute:(NSInteger)baseMinute
{
    // updating the alarms will differ depending on which version of iOS we are on
    if (kSLSystemVersioniOS13 || kSLSystemVersioniOS12) {
        // create an instance of the alarm manager that will get us the actual alarm objects
        MTAlarmManager *alarmManager = [[objc_getClass("MTAlarmManager") alloc] init];

        // update alarms using the auto-set date passed, along with any offset that might be required for the alarm
        NSInteger alarmCount = 0;
        for (NSDictionary *alarmDict in alarms) {
            ++alarmCount;

            // grab the alarm Id from the alarm dictionary so that we can create a system alarm object
            NSString *alarmId = [alarmDict objectForKey:kSLAlarmIdKey];
            MTAlarm *alarm = [alarmManager alarmWithIDString:alarmId];
            if (alarm != nil) {
                // create a mutable copy of the alarm
                MTMutableAlarm *mutableAlarm = [alarm mutableCopy];
                if (mutableAlarm != nil) {
                    // adjust the hour and minute based on the optional offset preferences
                    SLAutoSetOffsetOption offsetOption = [[alarmDict objectForKey:kSLAutoSetOffsetOptionKey] integerValue];
                    NSInteger updatedHour = baseHour;
                    NSInteger updatedMinute = baseMinute;
                    if (offsetOption != kSLAutoSetOffsetOptionOff) {
                        NSInteger offsetHour = [[alarmDict objectForKey:kSLAutoSetOffsetHourKey] integerValue];
                        NSInteger offsetMinute = [[alarmDict objectForKey:kSLAutoSetOffsetMinuteKey] integerValue];
                        if (offsetOption == kSLAutoSetOffsetOptionBefore) {
                            offsetHour = offsetHour * -1;
                            offsetMinute = offsetMinute * -1;
                        }

                        // check to see if the hours or minutes need to be adjusted
                        updatedHour = baseHour + offsetHour;
                        updatedMinute = baseMinute + offsetMinute;
                        if (updatedMinute < 0) {
                            --updatedHour;
                            updatedMinute = 60 + updatedMinute;
                        } else if (updatedMinute > 59) {
                            ++updatedHour;
                            updatedMinute = updatedMinute - 60;
                        }
                        if (updatedHour < 0) {
                            updatedHour = 23 + updatedHour;
                        } else if (updatedHour > 23) {
                            updatedHour = updatedHour - 23;
                        }
                    }

                    // modify the alarm after a small delay since this could happen right after an alarm was just saved
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1 + alarmCount) * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                        // update the alarm's hour and minute with the appropriate, adjusted time
                        [mutableAlarm setHour:updatedHour];
                        [mutableAlarm setMinute:updatedMinute];
                        mutableAlarm.SLWasUpdatedBySleeper = YES;

                        // persist the changes to the system
                        [alarmManager updateAlarm:mutableAlarm];
                    });
                }
            } else {
                // use this as an opportunity to remove the preferences for this alarm since it no longer exists
                [SLPrefsManager deleteAlarmForAlarmId:alarmId];
            }
        }
    } else if (kSLSystemVersioniOS11 || kSLSystemVersioniOS10 || kSLSystemVersioniOS9 || kSLSystemVersioniOS8) {
        // grab the shared alarm manager instance
        AlarmManager *alarmManager = (AlarmManager *)[objc_getClass("AlarmManager") sharedManager];
        [alarmManager loadAlarms];

        // update alarms using the auto-set date passed, along with any offset that might be required for the alarm
        NSInteger alarmCount = 0;
        for (NSDictionary *alarmDict in alarms) {
            ++alarmCount;

            // grab the alarm Id from the alarm dictionary so that we can create a system alarm object
            NSString *alarmId = [alarmDict objectForKey:kSLAlarmIdKey];
            Alarm *alarm = [alarmManager alarmWithId:alarmId];
            if (alarm != nil) {
                // get an editing proxy for the alarm
                [alarm prepareEditingProxy];
                Alarm *editingProxy = [alarm editingProxy];
                if (editingProxy != nil) {
                    // adjust the hour and minute based on the offset preferences
                    SLAutoSetOffsetOption offsetOption = [[alarmDict objectForKey:kSLAutoSetOffsetOptionKey] integerValue];
                    NSInteger updatedHour = baseHour;
                    NSInteger updatedMinute = baseMinute;
                    if (offsetOption != kSLAutoSetOffsetOptionOff) {
                        NSInteger offsetHour = [[alarmDict objectForKey:kSLAutoSetOffsetHourKey] integerValue];
                        NSInteger offsetMinute = [[alarmDict objectForKey:kSLAutoSetOffsetMinuteKey] integerValue];
                        if (offsetOption == kSLAutoSetOffsetOptionBefore) {
                            offsetHour = offsetHour * -1;
                            offsetMinute = offsetMinute * -1;
                        }

                        // check to see if the hours or minutes need to be adjusted
                        updatedHour = baseHour + offsetHour;
                        updatedMinute = baseMinute + offsetMinute;
                        if (updatedMinute < 0) {
                            --updatedHour;
                            updatedMinute = 60 + updatedMinute;
                        } else if (updatedMinute > 59) {
                            ++updatedHour;
                            updatedMinute = updatedMinute - 60;
                        }
                        if (updatedHour < 0) {
                            updatedHour = 23 + updatedHour;
                        } else if (updatedHour > 23) {
                            updatedHour = updatedHour - 23;
                        }
                    }

                    // modify the alarm after a small delay since this could happen right after an alarm was just saved
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)((5 + alarmCount) * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                        // update the alarm's hour and minute with the appropriate, adjusted time
                        [editingProxy setHour:updatedHour];
                        [editingProxy setMinute:updatedMinute];
                        [alarm applyChangesFromEditingProxy];

                        // persist changes to the system
                        [alarmManager updateAlarm:alarm active:[alarm isActive]];
                    });
                }
            } else {
                // use this as an opportunity to remove the preferences for this alarm since it no longer exists
                [SLPrefsManager deleteAlarmForAlarmId:alarmId];
            }
        }
    }
}

@end