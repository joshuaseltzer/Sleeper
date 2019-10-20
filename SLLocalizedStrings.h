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

// the bundle path for the MobilePhone app
#define kSLMobilePhoneBundle                    [NSBundle bundleWithPath:@"/Applications/MobilePhone.app"]

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
#define kSLNoString                             [kSLPreferencesBundle localizedStringForKey:@"NO" value:@"Yes" table:@"Localizable"]
#define kSLSkipString                           [kSLSleeperBundle localizedStringForKey:@"SKIP" value:@"Skip" table:@"Localizable"]
#define kSLSkipTimeString                       [kSLSleeperBundle localizedStringForKey:@"SKIP_TIME" value:@"Skip Time" table:@"Localizable"]
#define kSLSkipAlarmString                      [kSLSleeperBundle localizedStringForKey:@"SKIP_ALARM" value:@"Skip Alarm" table:@"Localizable"]
#define kSLSkipQuestionString(alarmName, time)  [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"SKIP_QUESTION" value:@"Would you like to skip \"%@\" which is scheduled to go off at %@?" table:@"Localizable"], alarmName, time]
#define kSLSkipTimeExplanationString            [kSLSleeperBundle localizedStringForKey:@"SKIP_TIME_EXPLANATION" value:@"Choose an amount of time that you will be prompted to skip the alarm before it fires." table:@"Localizable"]

// the skip date strings
#define kSLCancelString                         [kSLMobileTimerBundle localizedStringForKey:@"CANCEL" value:@"Cancel" table:@"Localizable"]
#define kSLSaveString                           [kSLMobileTimerBundle localizedStringForKey:@"SAVE" value:@"Save" table:@"Localizable"]
#define kSLNoneString                           [kSLMobileTimerBundle localizedStringForKey:@"NONE" value:@"None" table:@"Localizable"]
#define kSLSkipDatesString                      [kSLSleeperBundle localizedStringForKey:@"SKIP_DATES" value:@"Skip Dates" table:@"Localizable"]
#define kSLSelectDateString                     [kSLSleeperBundle localizedStringForKey:@"SELECT_DATE" value:@"Select Date" table:@"Localizable"]
#define kSLHolidaysString                       [kSLSleeperBundle localizedStringForKey:@"HOLIDAYS" value:@"Holidays" table:@"Localizable"]
#define kSLHolidayString                        [kSLSleeperBundle localizedStringForKey:@"HOLIDAY" value:@"Holiday" table:@"Localizable"]
#define kSLDefaultSkipDatesString               [kSLSleeperBundle localizedStringForKey:@"DEFAULT_SKIP_DATES" value:@"Remove all skip dates, including any holiday selections, for this alarm." table:@"Localizable"]
#define kSLSkipDateExplanationString            [kSLSleeperBundle localizedStringForKey:@"SKIP_DATE_EXPLANATION" value:@"This alarm will be skipped on the dates selected." table:@"Localizable"]
#define kSLHolidayExplanationString             [kSLSleeperBundle localizedStringForKey:@"HOLIDAY_EXPLANATION" value:@"If the holiday falls on a weekend, the observed date is used.  Once a holiday is selected, it will continue to be skipped every year." table:@"Localizable"]
#define kSLAddNewDateString                     [kSLSleeperBundle localizedStringForKey:@"ADD_NEW_DATE" value:@"Add New Date..." table:@"Localizable"]
#define kSLClearString                          [kSLMobilePhoneBundle localizedStringForKey:@"CLEAR" value:@"Clear" table:@"Voicemail"]
#define kSLNumberSelectedString(numSelected)    [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUMBER_SELECTED" value:@"%ld Selected" table:@"Localizable"], (long)numSelected]