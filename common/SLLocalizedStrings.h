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
#define kSLHoursString                          [kSLSleeperBundle localizedStringForKey:@"HOURS" value:@"hours" table:@"Localizable"]
#define kSLMinutesString                        [kSLSleeperBundle localizedStringForKey:@"MINUTES" value:@"min" table:@"Localizable"]
#define kSLSecondsString                        [kSLSleeperBundle localizedStringForKey:@"SECONDS" value:@"sec" table:@"Localizable"]
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
#define kSLSelectNewDateString                      [kSLSleeperBundle localizedStringForKey:@"SELECT_NEW_DATE" value:@"Select New Date" table:@"Localizable"]
#define kSLSelectStartDateString                    [kSLSleeperBundle localizedStringForKey:@"SELECT_START_DATE" value:@"Select Start Date" table:@"Localizable"]
#define kSLSelectEndDateString                      [kSLSleeperBundle localizedStringForKey:@"SELECT_END_DATE" value:@"Select End Date" table:@"Localizable"]
#define kSLEditExistingDateString                   [kSLSleeperBundle localizedStringForKey:@"EDIT_EXISTING_DATE" value:@"Edit Existing Date" table:@"Localizable"]
#define kSLNumHolidaysString(num)                   [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_HOLIDAYS" value:@"%ld Holidays" table:@"Localizable"], num]
#define kSLNumHolidayString(num)                    [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_HOLIDAY" value:@"%ld Holiday" table:@"Localizable"], num]
#define kSLNumDatesString(num)                      [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_DATES" value:@"%ld Dates" table:@"Localizable"], num]
#define kSLNumDateString(num)                       [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUM_DATE" value:@"%ld Date" table:@"Localizable"], num]
#define kSLDefaultSkipDatesString                   [kSLSleeperBundle localizedStringForKey:@"DEFAULT_SKIP_DATES" value:@"Remove all skip dates for this alarm." table:@"Localizable"]
#define kSLConfirmDefaultSkipDatesString            [kSLSleeperBundle localizedStringForKey:@"CONFIRM_DEFAULT_SKIP_DATES" value:@"Are you sure you want to remove all of the skip dates for this alarm?" table:@"Localizable"]
#define kSLDefaultSkipDatesAndHolidaysString        [kSLSleeperBundle localizedStringForKey:@"DEFAULT_SKIP_DATES_AND_HOLIDAYS" value:@"Remove all skip dates, including any holiday selections, for this alarm." table:@"Localizable"]
#define kSLConfirmDefaultSkipDatesAndHolidaysString [kSLSleeperBundle localizedStringForKey:@"CONFIRM_DEFAULT_SKIP_DATES_AND_HOLIDAYS" value:@"Are you sure you want to remove all of the skip dates and holiday selections for this alarm?" table:@"Localizable"]
#define kSLSkipDateExplanationString                [kSLSleeperBundle localizedStringForKey:@"SKIP_DATE_EXPLANATION" value:@"This alarm will be skipped on the dates selected." table:@"Localizable"]
#define kSLHolidayExplanationString                 [kSLSleeperBundle localizedStringForKey:@"HOLIDAY_EXPLANATION" value:@"If this country recognizes observed holidays and the holiday falls on a weekend, the observed date is used.  Once a holiday is selected, it will continue to be skipped every year." table:@"Localizable"]
#define kSLAddNewDateString                         [kSLSleeperBundle localizedStringForKey:@"ADD_NEW_DATE" value:@"Add New Date..." table:@"Localizable"]
#define kSLClearString                              [kSLMobileSafariBundle localizedStringForKey:@"Clear" value:@"Clear" table:@"Localizable"]
#define kSLNumberSelectedString(numSelected)        [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"NUMBER_SELECTED" value:@"%ld Selected" table:@"Localizable"], (long)numSelected]
#define kSLSkipReasonPopupString                    [kSLSleeperBundle localizedStringForKey:@"SKIP_REASON_POPUP" value:@"You have decided to skip this alarm the next time it is set to fire.  This decision will be reset if you save the alarm." table:@"Localizable"]
#define kSLSkipReasonDateString(date)               [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"SKIP_REASON_DATE" value:@"The next skip date you've selected for this alarm is %@." table:@"Localizable"], date]
#define kSLSkipReasonHolidayString(date, holiday)   [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"SKIP_REASON_HOLIDAY" value:@"The next holiday you've selected for this alarm is %@ (%@)." table:@"Localizable"], date, holiday]
#define kSLAllHolidaysString                        [kSLSleeperBundle localizedStringForKey:@"ALL_HOLIDAYS" value:@"All Holidays" table:@"Localizable"]
#define kSLRecommendedHolidaysExplanationString     [kSLSleeperBundle localizedStringForKey:@"RECOMMENDED_HOLIDAYS_EXPLANATION" value:@"These are the recommended holidays based on your device's current locale." table:@"Localizable"]
#define kSLTodayString                              [kSLMobileTimerBundle localizedStringForKey:@"TODAY" value:@"Today" table:@"Localizable"]
#define kSLTomorrowString                           [kSLMobileTimerBundle localizedStringForKey:@"TOMORROW" value:@"Tomorrow" table:@"Localizable"]
#define kSLSingleDateString                         [kSLSleeperBundle localizedStringForKey:@"SINGLE_DATE" value:@"Single Date" table:@"Localizable"]
#define kSLDateRangeString                          [kSLSleeperBundle localizedStringForKey:@"DATE_RANGE" value:@"Date Range" table:@"Localizable"]

// the auto-set strings
#define kSLAutoSetString                            [kSLSleeperBundle localizedStringForKey:@"AUTO_SET" value:@"Auto-Set" table:@"Localizable"]
#define kSLAutoSetExplanationString                 [kSLSleeperBundle localizedStringForKey:@"AUTO_SET_EXPLANATION" value:@"Choose an auto-set option to have this alarm automatically update its time.  The time for these options will be determined using the primary location set in the Weather application.  The system will routinely update all auto-set alarms using the most up-to-date location information at midnight and noon each day." table:@"Localizable"]
#define kSLAutoSetOffsetExplanationString           [kSLSleeperBundle localizedStringForKey:@"AUTO_SET_OFFSET_EXPLANATION" value:@"When enabled, the offset hours and minutes will be applied either before or after the selected auto-set time.\n\nFor example, if the sunrise auto-set option is selected with a 1-hour-before offset option, the alarm will be set to fire 1 hour before the actual sunrise occurs." table:@"Localizable"]
#define kSLAutoSetOffExplanationString              [kSLSleeperBundle localizedStringForKey:@"AUTO_SET_OFF_EXPLANATION" value:@"You can use the auto-set feature to have this alarm automatically set its time based on various parameters." table:@"Localizable"]
#define kSLAutoSetOnExplanationString(sunType)                                          [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"AUTO_SET_ON_EXPLANATION" value:@"This alarm will be automatically set to the %@ time." table:@"Localizable"], sunType]
#define kSLAutoSetOnWithOffsetExplanationString(hours, minutes, offsetType, sunType)    [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"AUTO_SET_ON_WITH_OFFSET_EXPLANATION" value:@"This alarm will be automatically set to %ld hour(s) and %ld minute(s) %@ the %@ time." table:@"Localizable"], hours, minutes, offsetType, sunType]
#define kSLBeforeString                             [kSLSleeperBundle localizedStringForKey:@"BEFORE" value:@"Before" table:@"Localizable"]
#define kSLAfterString                              [kSLSleeperBundle localizedStringForKey:@"AFTER" value:@"After" table:@"Localizable"]
#define kSLSunriseString                            [kSLMobileTimerBundle localizedStringForKey:@"SUNRISE" value:@"Sunrise" table:@"Localizable"]
#define kSLSunsetString                             [kSLMobileTimerBundle localizedStringForKey:@"SUNSET" value:@"Sunset" table:@"Localizable"]
#define kSLOffString                                [kSLPreferencesBundle localizedStringForKey:@"Off" value:@"Off" table:@"Localizable"]
#define kSLOffsetString                             [kSLSleeperBundle localizedStringForKey:@"OFFSET" value:@"Offset" table:@"Localizable"]
#define kSLOffsetTimeString                         [kSLSleeperBundle localizedStringForKey:@"OFFSET_TIME" value:@"Offset Time" table:@"Localizable"]
#define kSLTimeString                               [kSLPreferencesBundle localizedStringForKey:@"TIME" value:@"Time" table:@"Localizable"]
#define kSLNumHoursString(numString)                [NSString stringWithFormat:[kSLPreferencesBundle localizedStringForKey:@"%@ hours" value:@"%@ Hours" table:@"Localizable"], numString]
#define kSLNumHourString(numString)                 [NSString stringWithFormat:[kSLPreferencesBundle localizedStringForKey:@"%@ hour" value:@"%@ Hour" table:@"Localizable"], numString]
#define kSLNumMinutesString(numString)              [NSString stringWithFormat:[kSLPreferencesBundle localizedStringForKey:@"%@ minutes" value:@"%@ Minutes" table:@"Localizable"], numString]
#define kSLNumMinuteString(numString)               [NSString stringWithFormat:[kSLPreferencesBundle localizedStringForKey:@"%@ minute" value:@"%@ Minute" table:@"Localizable"], numString]