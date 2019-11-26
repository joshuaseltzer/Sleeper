//
//  SLLocalizedStrings.h
//  Set of localized strings used throughout the tweak.
//
//  Created by Joshua Seltzer on 1/21/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

#import "SLPrefsManager.h"

// the bundle path for the preferences app
#define kSLPreferencesBundle                    [NSBundle bundleWithPath:@"/Applications/Preferences.app"]

// the bundle path for the MobileTimer app
#define kSLMobileTimerBundle                    [NSBundle bundleWithPath:@"/Applications/MobileTimer.app"]

// the bundle path for the MobileSafari app
#define kSLMobileSafariBundle                   [NSBundle bundleWithPath:@"/Applications/MobileSafari.app"]

// the snooze strings
#define kSLSnoozeTimeString                     [kSLSleeperBundle localizedStringForKey:@"SNOOZE_TIME" value:@"Snooze Time" table:@"Localizable"]
#define kSLHoursString                          [kSLMobileTimerBundle localizedStringForKey:@"hour[plural]" value:@"hours" table:@"Localizable"]
#define kSLMinutesString                        [kSLMobileTimerBundle localizedStringForKey:@"min[plural]" value:@"min" table:@"Localizable"]
#define kSLSecondsString                        [kSLMobileTimerBundle localizedStringForKey:@"sec[plural]" value:@"sec" table:@"Localizable"]
#define kSLResetDefaultString                   [kSLSleeperBundle localizedStringForKey:@"RESET_DEFAULT" value:@"Reset Default" table:@"Localizable"]
#define kSLDefaultSnoozeTimeString(time)        [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"DEFAULT_SNOOZE_TIME" value:@"The default snooze time is %@." table:@"Localizable"], time]
#define kSLSleepAlarmString                     [kSLMobileTimerBundle localizedStringForKey:@"SLEEP_ALARM_SPOTLIGHT_KEYWORD" value:@"Sleep Alarm" table:@"Localizable"]

// the skip time strings
#define kSLYesString                            [kSLPreferencesBundle localizedStringForKey:@"YES" value:@"Yes" table:@"Localizable"]
#define kSLNoString                             [kSLPreferencesBundle localizedStringForKey:@"NO" value:@"No" table:@"Localizable"]
#define kSLSkipString                           [kSLSleeperBundle localizedStringForKey:@"SKIP" value:@"Skip" table:@"Localizable"]
#define kSLSkipTimeString                       [kSLSleeperBundle localizedStringForKey:@"SKIP_TIME" value:@"Skip Time" table:@"Localizable"]
#define kSLSkipAlarmString                      [kSLSleeperBundle localizedStringForKey:@"SKIP_ALARM" value:@"Skip Alarm" table:@"Localizable"]
#define kSLSkipQuestionString(alarmName, time)  [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"SKIP_QUESTION" value:@"Would you like to skip \"%@\" which is scheduled to go off at %@?" table:@"Localizable"], alarmName, time]
#define kSLSkipTimeExplanationString            [kSLSleeperBundle localizedStringForKey:@"SKIP_TIME_EXPLANATION" value:@"Choose an amount of time that you will be prompted to skip the alarm before it fires." table:@"Localizable"]

// the skip date strings
#define kSLCancelString                             [kSLMobileTimerBundle localizedStringForKey:@"CANCEL" value:@"Cancel" table:@"Localizable"]
#define kSLSaveString                               [kSLMobileTimerBundle localizedStringForKey:@"SAVE" value:@"Save" table:@"Localizable"]
#define kSLNoneString                               [kSLMobileTimerBundle localizedStringForKey:@"NONE" value:@"None" table:@"Localizable"]
#define kSLSkipDatesString                          [kSLSleeperBundle localizedStringForKey:@"SKIP_DATES" value:@"Skip Dates" table:@"Localizable"]
#define kSLSelectDateString                         [kSLSleeperBundle localizedStringForKey:@"SELECT_DATE" value:@"Select Date" table:@"Localizable"]
#define kSLNumHolidaysString(num)                   [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_HOLIDAYS" value:@"%ld Holidays" table:@"Localizable"], num]
#define kSLNumHolidayString(num)                    [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_HOLIDAY" value:@"%ld Holiday" table:@"Localizable"], num]
#define kSLNumDatesString(num)                      [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_DATES" value:@"%ld Dates" table:@"Localizable"], num]
#define kSLNumDateString(num)                       [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_DATE" value:@"%ld Date" table:@"Localizable"], num]
#define kSLDefaultSkipDatesString                   [kSLSleeperBundle localizedStringForKey:@"DEFAULT_SKIP_DATES" value:@"Remove all skip dates, including any holiday selections, for this alarm." table:@"Localizable"]
#define kSLSkipDateExplanationString                [kSLSleeperBundle localizedStringForKey:@"SKIP_DATE_EXPLANATION" value:@"This alarm will be skipped on the dates selected." table:@"Localizable"]
#define kSLHolidayExplanationString                 [kSLSleeperBundle localizedStringForKey:@"HOLIDAY_EXPLANATION" value:@"If the holiday falls on a weekend, the observed date is used.  Once a holiday is selected, it will continue to be skipped every year." table:@"Localizable"]
#define kSLAddNewDateString                         [kSLSleeperBundle localizedStringForKey:@"ADD_NEW_DATE" value:@"Add New Date..." table:@"Localizable"]
#define kSLClearString                              [kSLMobileSafariBundle localizedStringForKey:@"Clear" value:@"Clear" table:@"Localizable"]
#define kSLNumberSelectedString(numSelected)        [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUMBER_SELECTED" value:@"%ld Selected" table:@"Localizable"], (long)numSelected]
#define kSLSkipReasonPopupString                    [kSLSleeperBundle localizedStringForKey:@"SKIP_REASON_POPUP" value:@"You have decided to skip this alarm the next time it is set to fire.  This decision will be reset if you save the alarm." table:@"Localizable"]
#define kSLSkipReasonDateString(date)               [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"SKIP_REASON_DATE" value:@"The next skip date you've selected for this alarm is %@." table:@"Localizable"], date]
#define kSLSkipReasonHolidayString(date, holiday)   [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"SKIP_REASON_HOLIDAY" value:@"The next holiday you've selected for this alarm is %@ (%@)." table:@"Localizable"], date, holiday]
#define kSLAllHolidaysString                        [kSLSleeperBundle localizedStringForKey:@"ALL_HOLIDAYS" value:@"All Holidays" table:@"Localizable"]
#define kSLRecommendedHolidaysExplanationString     [kSLSleeperBundle localizedStringForKey:@"RECOMMENDED_HOLIDAYS_EXPLANATION" value:@"These are the recommended holidays based on your device's current locale." table:@"Localizable"]
#define kSLTodayString                              [kSLMobileTimerBundle localizedStringForKey:@"TODAY" value:@"Today" table:@"Localizable"]
#define kSLTomorrowString                           [kSLMobileTimerBundle localizedStringForKey:@"TOMORROW" value:@"Today" table:@"Localizable"]