//
//  SLPrefsManager.m
//  The preferences manager for the tweak.
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "SLPrefsManager.h"
#import "SLLocalizedStrings.h"

// the path of our settings that is used to store the alarm snooze times
#define SETTINGS_PATH    [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.joshuaseltzer.sleeper.plist"]

// keep a single static instance of the date formatter that will be used to display the skip dates to the user
static NSDateFormatter *sSLSkipDatesDateFormatter;

@implementation SLPrefsManager

// Return an SLAlarmPrefs object with alarm information for a given alarm Id.  Return nil if no alarm is found.
+ (SLAlarmPrefs *)alarmPrefsForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the alarm preferences exist, attempt to get the alarms
    if (prefs) {
        // get the array of dictionaries of all of the alarms
        NSArray *alarms = [prefs objectForKey:kSLAlarmsKey];
        
        // iterate through the alarms until we the find the one with a matching id
        for (NSDictionary *alarm in alarms) {
            if ([[alarm objectForKey:kSLAlarmIdKey] isEqualToString:alarmId]) {
                // create a preferences object for the given alarm
                SLAlarmPrefs *alarmPrefs = [[SLAlarmPrefs alloc] init];
                alarmPrefs.alarmId = alarmId;
                alarmPrefs.snoozeTimeHour = [[alarm objectForKey:kSLSnoozeHourKey] integerValue];
                alarmPrefs.snoozeTimeMinute = [[alarm objectForKey:kSLSnoozeMinuteKey] integerValue];
                alarmPrefs.snoozeTimeSecond = [[alarm objectForKey:kSLSnoozeSecondKey] integerValue];
                alarmPrefs.skipEnabled = [[alarm objectForKey:kSLSkipEnabledKey] boolValue];
                alarmPrefs.skipTimeHour = [[alarm objectForKey:kSLSkipHourKey] integerValue];
                alarmPrefs.skipTimeMinute = [[alarm objectForKey:kSLSkipMinuteKey] integerValue];
                alarmPrefs.skipTimeSecond = [[alarm objectForKey:kSLSkipSecondKey] integerValue];
                alarmPrefs.skipActivationStatus = [[alarm objectForKey:kSLSkipActivatedStatusKey] integerValue];
                
                // check to see if the prefs contain any of the skip dates options (added in v4.1.0)
                NSDictionary *skipDates = [alarm objectForKey:kSLSkipDatesKey];
                if (skipDates != nil) {
                    alarmPrefs.customSkipDates = [skipDates objectForKey:kSLCustomSkipDatesKey];
                    alarmPrefs.holidaySkipDates = [skipDates objectForKey:kSLHolidaySkipDatesKey];

                    // update the skip dates, by potentially adding ones from a new update or removing dates that might have passed
                    [alarmPrefs updateCustomSkipDates];
                } else {
                    // if an alarm did not have a skip dates key in the preferences, we need to add the default
                    // holiday skip dates
                    alarmPrefs.customSkipDates = [[NSArray alloc] init];
                    alarmPrefs.holidaySkipDates = [[NSDictionary alloc] init];
                }
                
                return alarmPrefs;
            }
        }
    }
    return nil;
}

// save the specific alarm preferences object
+ (void)saveAlarmPrefs:(SLAlarmPrefs *)alarmPrefs
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if no preferences exist, create a new mutable dictionary now
    if (!prefs) {
        prefs = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    // array of dictionaries of all of the alarms
    NSMutableArray *alarms = [prefs objectForKey:kSLAlarmsKey];
    
    // if the alarms do not exist in our preferences, create the alarms array now
    NSMutableDictionary *alarm = nil;
    if (!alarms) {
        alarms = [[NSMutableArray alloc] initWithCapacity:1];
    } else {
        // otherwise attempt to find the desired alarm in the array
        for (alarm in alarms) {
            if ([[alarm objectForKey:kSLAlarmIdKey] isEqualToString:alarmPrefs.alarmId]) {
                // update the alarm dictionary with the values given
                [alarm setObject:[NSNumber numberWithInteger:alarmPrefs.snoozeTimeHour]
                          forKey:kSLSnoozeHourKey];
                [alarm setObject:[NSNumber numberWithInteger:alarmPrefs.snoozeTimeMinute]
                          forKey:kSLSnoozeMinuteKey];
                [alarm setObject:[NSNumber numberWithInteger:alarmPrefs.snoozeTimeSecond]
                          forKey:kSLSnoozeSecondKey];
                [alarm setObject:[NSNumber numberWithBool:alarmPrefs.skipEnabled]
                          forKey:kSLSkipEnabledKey];
                [alarm setObject:[NSNumber numberWithInteger:alarmPrefs.skipTimeHour]
                          forKey:kSLSkipHourKey];
                [alarm setObject:[NSNumber numberWithInteger:alarmPrefs.skipTimeMinute]
                          forKey:kSLSkipMinuteKey];
                [alarm setObject:[NSNumber numberWithInteger:alarmPrefs.skipTimeSecond]
                          forKey:kSLSkipSecondKey];
                [alarm setObject:[NSNumber numberWithInteger:kSLSkipActivatedStatusUnknown]
                          forKey:kSLSkipActivatedStatusKey];
                [alarm setObject:@{kSLCustomSkipDatesKey:alarmPrefs.customSkipDates,
                                   kSLHolidaySkipDatesKey:alarmPrefs.holidaySkipDates}
                          forKey:kSLSkipDatesKey];
                break;
            }
        }
    }
    
    // check if the alarm was found, if not add a new one
    if (!alarm) {
        // create a new alarm with the given attributes
        NSDictionary *newAlarm = [NSDictionary dictionaryWithObjectsAndKeys:alarmPrefs.alarmId, kSLAlarmIdKey,
                                  [NSNumber numberWithInteger:alarmPrefs.snoozeTimeHour], kSLSnoozeHourKey,
                                  [NSNumber numberWithInteger:alarmPrefs.snoozeTimeMinute], kSLSnoozeMinuteKey,
                                  [NSNumber numberWithInteger:alarmPrefs.snoozeTimeSecond], kSLSnoozeSecondKey,
                                  [NSNumber numberWithBool:alarmPrefs.skipEnabled], kSLSkipEnabledKey,
                                  [NSNumber numberWithInteger:alarmPrefs.skipTimeHour], kSLSkipHourKey,
                                  [NSNumber numberWithInteger:alarmPrefs.skipTimeMinute], kSLSkipMinuteKey,
                                  [NSNumber numberWithInteger:alarmPrefs.skipTimeSecond], kSLSkipSecondKey,
                                  [NSNumber numberWithInteger:kSLSkipActivatedStatusUnknown], kSLSkipActivatedStatusKey,
                                  @{kSLCustomSkipDatesKey:alarmPrefs.customSkipDates, kSLHolidaySkipDatesKey:alarmPrefs.holidaySkipDates}, kSLSkipDatesKey,
                                  nil];
        
        // add the object to the array
        [alarms addObject:newAlarm];
    }
    
    // add the alarms array to the preferences dictionary
    [prefs setObject:alarms forKey:kSLAlarmsKey];
    
    // write the updated preferences
    [prefs writeToFile:SETTINGS_PATH atomically:YES];
}

// save the skip activation status for a given alarm
+ (void)setSkipActivatedStatusForAlarmId:(NSString *)alarmId
                     skipActivatedStatus:(SLPrefsSkipActivatedStatus)skipActivatedStatus
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the clock preferences don't exist, create a new mutable dictionary now
    if (!prefs) {
        prefs = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    // array of dictionaries of all of the alarms
    NSMutableArray *alarms = [prefs objectForKey:kSLAlarmsKey];
    
    // if the alarms do not exist in our preferences, create the alarms array now
    NSMutableDictionary *alarm = nil;
    if (!alarms) {
        alarms = [[NSMutableArray alloc] initWithCapacity:1];
    } else {
        // otherwise attempt to find the desired alarm in the array
        for (alarm in alarms) {
            if ([[alarm objectForKey:kSLAlarmIdKey] isEqualToString:alarmId]) {
                // update the alarm dictionary with the values given
                [alarm setObject:[NSNumber numberWithInteger:skipActivatedStatus]
                          forKey:kSLSkipActivatedStatusKey];
                break;
            }
        }
    }
    
    // check if the alarm was found, if so replace it
    if (!alarm) {
        // create a new alarm with the given attributes
        NSDictionary *newAlarm = [NSDictionary dictionaryWithObjectsAndKeys:alarmId, kSLAlarmIdKey,
                                  [NSNumber numberWithInteger:skipActivatedStatus],
                                  kSLSkipActivatedStatusKey, nil];
        
        // add the object to the array
        [alarms addObject:newAlarm];
    }
    
    // add the alarms array to the preferences dictionary
    [prefs setObject:alarms forKey:kSLAlarmsKey];
    
    // write the updated preferences
    [prefs writeToFile:SETTINGS_PATH atomically:YES];
}

// delete an alarm from our settings
+ (void)deleteAlarmForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // only continue trying to delete the alarm if our preferences exist
    if (prefs) {
        // array of dictionaries of all of the alarms
        NSMutableArray *alarms = [prefs objectForKey:kSLAlarmsKey];
        
        // only continue if any Alarms exist in the preferences
        if (alarms) {
            // iterate through all of the alarms until we find the one we desire
            BOOL alarmFound = NO;
            for (int i = 0; i < alarms.count; i++) {
                // get the alarm at the given index
                NSDictionary *alarm = [alarms objectAtIndex:i];
                
                // check if this is the desired alarm
                if ([[alarm objectForKey:kSLAlarmIdKey] isEqualToString:alarmId]) {
                    // remove the alarm from the array
                    [alarms removeObjectAtIndex:i];
                    alarmFound = YES;
                    break;
                }
            }
            
            // if an alarm was found and deleted, then update the data source
            if (alarmFound) {
                // add the alarms array to the preferences dictionary
                [prefs setObject:alarms forKey:kSLAlarmsKey];
                
                // write the updated preferences
                [prefs writeToFile:SETTINGS_PATH atomically:YES];
            }
        }
    }
}

// Returns a dictionary that corresponds to the default holiday source for the given holiday resource name.
// This function will also remove any passed dates.
+ (NSDictionary *)holidayResourceForResourceName:(NSString *)resourceName
{
    NSMutableDictionary *holidayResource = nil;
    NSString *resourcePath = [kSLSleeperBundle pathForResource:resourceName ofType:@"plist"];
    if (resourcePath != nil) {
        // load the list of holidays from the file system
        holidayResource = [[NSMutableDictionary alloc] initWithContentsOfFile:resourcePath];

        // remove any dates that might have already passed
        NSMutableArray *defaultHolidays = [holidayResource objectForKey:kSLHolidayHolidaysKey];
        for (NSMutableDictionary *holiday in defaultHolidays) {
            NSArray *dates = [holiday objectForKey:kSLHolidayDatesKey];
            NSArray *newDates = [SLPrefsManager removePassedDatesFromArray:dates];
            if (dates.count != newDates.count) {
                [holiday setObject:newDates forKey:kSLHolidayDatesKey];
            }
        }
        [holidayResource setObject:[defaultHolidays copy] forKey:kSLHolidayHolidaysKey];
    }
    return [holidayResource copy];
}

// returns an array of new dates that removes any dates from the given array of dates that have passed
+ (NSArray *)removePassedDatesFromArray:(NSArray *)dates
{
    NSMutableArray *newDates = [[NSMutableArray alloc] init];
    for (NSDate *date in dates) {
        NSComparisonResult dateComparison = [[NSCalendar currentCalendar] compareDate:date toDate:[NSDate date] toUnitGranularity:NSCalendarUnitDay];
        if (dateComparison == NSOrderedSame || dateComparison == NSOrderedDescending) {
            [newDates addObject:date];
        }
    }
    return [newDates copy];
}

// Returns the first available skip date for the given holiday name and country.  This function will not take into consideration any passed dates.
+ (NSDate *)firstSkipDateForHolidayName:(NSString *)holidayName inHolidayCountry:(SLHolidayCountry)holidayCountry
{
    // load the resource in the bundle to get the skip dates for the holidays selected
    NSString *resourceName = [SLPrefsManager resourceNameForHolidayCountry:holidayCountry];
    NSString *resourcePath = [kSLSleeperBundle pathForResource:resourceName ofType:@"plist"];
    if (resourcePath != nil) {
        // load the list of holidays from the file system
        NSDictionary *holidayResource = [[NSDictionary alloc] initWithContentsOfFile:resourcePath];
        NSArray *holidays = [holidayResource objectForKey:kSLHolidayHolidaysKey];

        // grab the first date for the matching holiday name (removing any that might have passed)
        for (NSDictionary *holiday in holidays) {
            // match the holiday based on the name
            if ([holidayName isEqualToString:[holiday objectForKey:kSLHolidayNameKey]]) {
                // get the dates for this holiday
                NSArray *dates = [holiday objectForKey:kSLHolidayDatesKey];
                for (NSDate *date in dates) {
                    NSComparisonResult dateComparison = [[NSCalendar currentCalendar] compareDate:date toDate:[NSDate date] toUnitGranularity:NSCalendarUnitDay];
                    if (dateComparison == NSOrderedSame || dateComparison == NSOrderedDescending) {
                        return date;
                    }
                }
            }
        }
    }
    return nil;
}

// returns a corresponding country code for any given country
+ (NSString *)countryCodeForHolidayCountry:(SLHolidayCountry)country
{
    NSString *countryCode = nil;
    switch (country) {
        case kSLHolidayCountryArgentina:
            countryCode = @"ar";
            break;
        case kSLHolidayCountryAruba:
            countryCode = @"aw";
            break;
        case kSLHolidayCountryAustralia:
            countryCode = @"au";
            break;
        case kSLHolidayCountryAustria:
            countryCode = @"at";
            break;
        case kSLHolidayCountryBelarus:
            countryCode = @"by";
            break;
        case kSLHolidayCountryBelgium:
            countryCode = @"be";
            break;
        case kSLHolidayCountryBrazil:
            countryCode = @"br";
            break;
        case kSLHolidayCountryBulgaria:
            countryCode = @"bg";
            break;
        case kSLHolidayCountryCanada:
            countryCode = @"ca";
            break;
        case kSLHolidayCountryColombia:
            countryCode = @"co";
            break;
        case kSLHolidayCountryCroatia:
            countryCode = @"hr";
            break;
        case kSLHolidayCountryCzechia:
            countryCode = @"cz";
            break;
        case kSLHolidayCountryDenmark:
            countryCode = @"dk";
            break;
        case kSLHolidayCountryEstonia:
            countryCode = @"ee";
            break;
        case kSLHolidayCountryFinland:
            countryCode = @"fi";
            break;
        case kSLHolidayCountryFrance:
            countryCode = @"fra";
            break;
        case kSLHolidayCountryGermany:
            countryCode = @"de";
            break;
        case kSLHolidayCountryHungary:
            countryCode = @"hu";
            break;
        case kSLHolidayCountryIceland:
            countryCode = @"is";
            break;
        case kSLHolidayCountryIndia:
            countryCode = @"ind";
            break;
        case kSLHolidayCountryIreland:
            countryCode = @"ie";
            break;
        case kSLHolidayCountryItaly:
            countryCode = @"it";
            break;
        case kSLHolidayCountryJapan:
            countryCode = @"jp";
            break;
        case kSLHolidayCountryKenya:
            countryCode = @"ke";
            break;
        case kSLHolidayCountryLithuania:
            countryCode = @"lt";
            break;
        case kSLHolidayCountryLuxembourg:
            countryCode = @"lu";
            break;
        case kSLHolidayCountryMexico:
            countryCode = @"mx";
            break;
        case kSLHolidayCountryNetherlands:
            countryCode = @"nl";
            break;
        case kSLHolidayCountryNewZealand:
            countryCode = @"nz";
            break;
        case kSLHolidayCountryNorway:
            countryCode = @"no";
            break;
        case kSLHolidayCountryPeru:
            countryCode = @"pe";
            break;
        case kSLHolidayCountryPoland:
            countryCode = @"pl";
            break;
        case kSLHolidayCountryPortugal:
            countryCode = @"pt";
            break;
        case kSLHolidayCountryRussia:
            countryCode = @"ru";
            break;
        case kSLHolidayCountrySlovakia:
            countryCode = @"sk";
            break;
        case kSLHolidayCountrySlovenia:
            countryCode = @"si";
            break;
        case kSLHolidayCountrySouthAfrica:
            countryCode = @"za";
            break;
        case kSLHolidayCountrySpain:
            countryCode = @"es";
            break;
        case kSLHolidayCountrySweden:
            countryCode = @"se";
            break;
        case kSLHolidayCountrySwitzerland:
            countryCode = @"ch";
            break;
        case kSLHolidayCountryUkraine:
            countryCode = @"ua";
            break;
        case kSLHolidayCountryUnitedKingdom:
            countryCode = @"uk";
            break;
        case kSLHolidayCountryUnitedStates:
            countryCode = @"us";
            break;
        case kSLHolidayCountryNumCountries:
            // this is in invalid country to provide, do nothing
            break;
    }
    return countryCode;
}

// returns a string that corresponds to the resource name for a given holiday country
+ (NSString *)resourceNameForHolidayCountry:(SLHolidayCountry)country
{
    return [NSString stringWithFormat:@"%@_holidays", [SLPrefsManager countryCodeForHolidayCountry:country]];
}

// returns a string that corresponds to the resource name for a given country code
+ (NSString *)resourceNameForCountryCode:(NSString *)countryCode
{
    return [NSString stringWithFormat:@"%@_holidays", countryCode];
}

// returns the localized, friendly name to be displayed for the given country
+ (NSString *)friendlyNameForHolidayCountry:(SLHolidayCountry)country
{
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode
                                                 value:[SLPrefsManager countryCodeForHolidayCountry:country]];
}

// Returns a string that represents a date that is going to be skipped.  If showRelativeString is enabled,
// a relative string is shown instead (i.e. Today, Tomorrow)
+ (NSString *)skipDateStringForDate:(NSDate *)date showRelativeString:(BOOL)showRelativeString
{
    // create the date formatter that will be used to display the dates
    if (sSLSkipDatesDateFormatter == nil) {
        sSLSkipDatesDateFormatter = [[NSDateFormatter alloc] init];
        sSLSkipDatesDateFormatter.dateFormat = @"EEEE, MMMM d, yyyy";
    }
    
    // check to see if a relative string can be shown instead of the date string
    if (showRelativeString) {
        if ([[NSCalendar currentCalendar] isDateInToday:date]) {
            return kSLTodayString;
        } else if ([[NSCalendar currentCalendar] isDateInTomorrow:date]) {
            return kSLTomorrowString;
        }
    }
    return [sSLSkipDatesDateFormatter stringFromDate:date];
}

@end
