//
//  JSLocalizedStrings.h
//  Sleeper
//
//  Created by Joshua Seltzer on 1/21/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

// the bundle path which includes all localization strings
#define LZ_BUNDLE_PATH          [NSBundle bundleWithPath:@"/Library/Application Support/Sleeper.bundle"]

// the individual strings that are to be localized
#define LZ_SNOOZE_TIME          [LZ_BUNDLE_PATH localizedStringForKey:@"SNOOZE_TIME" value:@"Snooze Time" table:@"Localizable"]
#define LZ_HOURS                [LZ_BUNDLE_PATH localizedStringForKey:@"HOURS" value:@"hours" table:@"Localizable"]
#define LZ_MINUTES              [LZ_BUNDLE_PATH localizedStringForKey:@"MINUTES" value:@"min" table:@"Localizable"]
#define LZ_SECONDS              [LZ_BUNDLE_PATH localizedStringForKey:@"SECONDS" value:@"sec" table:@"Localizable"]
#define LZ_RESET_DEFAULT        [LZ_BUNDLE_PATH localizedStringForKey:@"RESET_DEFAULT" value:@"Reset Default" table:@"Localizable"]
#define LZ_DEFAULT_SNOOZE_TIME  [LZ_BUNDLE_PATH localizedStringForKey:@"DEFAULT_SNOOZE_TIME" value:@"The default snooze time is" table:@"Localizable"]
#define LZ_SKIP                 [LZ_BUNDLE_PATH localizedStringForKey:@"SKIP" value:@"Skip" table:@"Localizable"]
#define LZ_ASK_TO_SKIP          [LZ_BUNDLE_PATH localizedStringForKey:@"ASK_TO_SKIP" value:@"Ask to Skip" table:@"Localizable"]
#define LZ_HOUR                 [LZ_BUNDLE_PATH localizedStringForKey:@"HOUR" value:@"hour" table:@"Localizable"]