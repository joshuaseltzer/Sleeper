//
//  SLLocalizedStrings.h
//  Set of localized strings used throughout the tweak.
//
//  Created by Joshua Seltzer on 1/21/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

// the bundle path which includes all custom localization strings
#define kSLSleeperBundle                        [NSBundle bundleWithPath:@"/Library/Application Support/Sleeper.bundle"]

// the bundle path for the preferences app
#define kSLPreferencesBundle                    [NSBundle bundleWithPath:@"/Applications/Preferences.app"]

// the snooze strings
#define kSLSnoozeTimeString                     [kSLSleeperBundle localizedStringForKey:@"SNOOZE_TIME" value:@"Snooze Time" table:@"Localizable"]
#define kSLHoursString                          [kSLSleeperBundle localizedStringForKey:@"HOURS" value:@"hours" table:@"Localizable"]
#define kSLMinutesString                        [kSLSleeperBundle localizedStringForKey:@"MINUTES" value:@"min" table:@"Localizable"]
#define kSLSecondsString                        [kSLSleeperBundle localizedStringForKey:@"SECONDS" value:@"sec" table:@"Localizable"]
#define kSLResetDefaultString                   [kSLSleeperBundle localizedStringForKey:@"RESET_DEFAULT" value:@"Reset Default" table:@"Localizable"]
#define kSLDefaultSnoozeTimeString(time)        [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"DEFAULT_SNOOZE_TIME" value:@"The default snooze time is %@." table:@"Localizable"], time]

// the skip strings
#define kSLYesString                            [kSLPreferencesBundle localizedStringForKey:@"YES" value:@"Yes" table:@"Localizable"]
#define kSLNoString                             [kSLPreferencesBundle localizedStringForKey:@"NO" value:@"Yes" table:@"Localizable"]
#define kSLSkipString                           [kSLSleeperBundle localizedStringForKey:@"SKIP" value:@"Skip" table:@"Localizable"]
#define kSLSkipTimeString                       [kSLSleeperBundle localizedStringForKey:@"SKIP_TIME" value:@"Skip Time" table:@"Localizable"]
#define kSLSkipAlarmString                      [kSLSleeperBundle localizedStringForKey:@"SKIP_ALARM" value:@"Skip Alarm" table:@"Localizable"]
#define kSLSkipQuestionString(alarmName, time)  [NSString stringWithFormat:[kSLSleeperBundle localizedStringForKey:@"SKIP_QUESTION" value:@"Would you like to skip \"%@\" which is scheduled to go off at %@?" table:@"Localizable"], alarmName, time]
#define kSLSkipExplanationString                [kSLSleeperBundle localizedStringForKey:@"SKIP_EXPLANATION" value:@"Choose an amount of time that you will be prompted to skip the alarm before it fires." table:@"Localizable"]