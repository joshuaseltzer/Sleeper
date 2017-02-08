//
//  JSLocalizedStrings.h
//  Sleeper
//
//  Created by Joshua Seltzer on 1/21/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

// the bundle path which includes all custom localization strings
#define LZ_SLEEPER_BUNDLE       [NSBundle bundleWithPath:@"/Library/Application Support/Sleeper.bundle"]

// the bundle path for the preferences app
#define LZ_PREFERENCES_BUNDLE   [NSBundle bundleWithPath:@"/Applications/Preferences.app"]

// the snooze strings
#define LZ_SNOOZE_TIME                      [LZ_SLEEPER_BUNDLE localizedStringForKey:@"SNOOZE_TIME" value:@"Snooze Time" table:@"Localizable"]
#define LZ_HOURS                            [LZ_SLEEPER_BUNDLE localizedStringForKey:@"HOURS" value:@"hours" table:@"Localizable"]
#define LZ_MINUTES                          [LZ_SLEEPER_BUNDLE localizedStringForKey:@"MINUTES" value:@"min" table:@"Localizable"]
#define LZ_SECONDS                          [LZ_SLEEPER_BUNDLE localizedStringForKey:@"SECONDS" value:@"sec" table:@"Localizable"]
#define LZ_RESET_DEFAULT                    [LZ_SLEEPER_BUNDLE localizedStringForKey:@"RESET_DEFAULT" value:@"Reset Default" table:@"Localizable"]
#define LZ_DEFAULT_SNOOZE_TIME(time)        [NSString stringWithFormat:[LZ_SLEEPER_BUNDLE localizedStringForKey:@"DEFAULT_SNOOZE_TIME" value:@"The default snooze time is %@." table:@"Localizable"], time]

// the skip strings
#define LZ_YES                              [LZ_PREFERENCES_BUNDLE localizedStringForKey:@"YES" value:@"Yes" table:@"Localizable"]
#define LZ_NO                               [LZ_PREFERENCES_BUNDLE localizedStringForKey:@"NO" value:@"Yes" table:@"Localizable"]
#define LZ_SKIP                             [LZ_SLEEPER_BUNDLE localizedStringForKey:@"SKIP" value:@"Skip" table:@"Localizable"]
#define LZ_SKIP_TIME                        [LZ_SLEEPER_BUNDLE localizedStringForKey:@"SKIP_TIME" value:@"Skip Time" table:@"Localizable"]
#define LZ_SKIP_ALARM                       [LZ_SLEEPER_BUNDLE localizedStringForKey:@"SKIP_ALARM" value:@"Skip Alarm" table:@"Localizable"]
#define LZ_SKIP_QUESTION(alarmName, time)   [NSString stringWithFormat:[LZ_SLEEPER_BUNDLE localizedStringForKey:@"SKIP_QUESTION" value:@"Would you like to skip \"%@\" which is scheduled to go off at %@?" table:@"Localizable"], alarmName, time]
#define LZ_SKIP_EXPLANATION                 [LZ_SLEEPER_BUNDLE localizedStringForKey:@"SKIP_EXPLANATION" value:@"Choose an amount of time that you will be prompted to skip the alarm before it fires." table:@"Localizable"]