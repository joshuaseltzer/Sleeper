//
//  SLPrefsManager.m
//  The preferences manager for the tweak.
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "SLPrefsManager.h"

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

                    // remove any dates that might have passed for this alarm
                    [alarmPrefs removePassedSkipDates];
                } else {
                    // if an alarm did not have a skip dates key in the preferences, we need to add the default
                    // holiday skip dates
                    alarmPrefs.customSkipDates = [[NSArray alloc] init];
                    [alarmPrefs populateDefaultHolidaySkipDates];
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

// Return the status that signifies whether or not skip is activated for a given alarm Id.  Return
// NSNotFound if no alarm is found.
+ (SLPrefsSkipActivatedStatus)skipActivatedStatusForAlarmId:(NSString *)alarmId
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
                return [[alarm objectForKey:kSLSkipActivatedStatusKey] integerValue];
            }
        }
    }
    
    // return NSNotFound if no alarm is found
    return NSNotFound;
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

// returns an array of dictionaries that correspond to the default holidays for a particular resource
+ (NSArray *)defaultHolidaysForResourceName:(NSString *)resourceName
{
    // get the resource name that correponds to the country
    NSMutableArray *defaultHolidays = nil;
    NSString *resourcePath = [kSLSleeperBundle pathForResource:resourceName ofType:@"plist"];
    if (resourcePath != nil) {
        // load the list of holidays from the file system
        defaultHolidays = [[NSMutableArray alloc] initWithContentsOfFile:resourcePath];

        // remove any dates that might have already passed
        for (NSMutableDictionary *holiday in defaultHolidays) {
            NSArray *dates = [holiday objectForKey:kSLHolidayDatesKey];
            NSArray *newDates = [SLPrefsManager removePassedDatesFromArray:dates];
            if (dates.count != newDates.count) {
                [holiday setObject:newDates forKey:kSLHolidayDatesKey];
            }
        }
    }
    return defaultHolidays;
}

// returns a string that corresponds to the resource name for a given holiday country
+ (NSString *)resourceNameForCountry:(SLHolidayCountry)country
{
    NSString *resourceName = nil;
    switch (country) {
        case kSLHolidayCountryUnitedStates:
            resourceName = @"holidays-us";
            break;
        case kSLHolidayCountryNumCountries:
            // this is in invalid country to provide, do nothing
            break;
    }
    return resourceName;
}

// returns the localized, friendly name to be displayed for the given country
+ (NSString *)friendlyNameForCountry:(SLHolidayCountry)country
{
    NSString *friendlyName = nil;
    switch (country) {
        case kSLHolidayCountryUnitedStates:
            friendlyName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode
                                                                 value:@"US"];
            break;
        case kSLHolidayCountryNumCountries:
            // this is in invalid country to provide, do nothing
            break;
    }
    return friendlyName;
}

// gets a sorted list of skip dates for a given alarm Id
+ (NSArray *)sortedSkipDatesForAlarmId:(NSString *)alarmId
{
    NSMutableArray *sortedSkipDates = [[NSMutableArray alloc] init];
    SLAlarmPrefs *alarmPrefs = [SLPrefsManager alarmPrefsForAlarmId:alarmId];
    
    // if the alarm preferences exist, attempt to get the skip dates
    if (alarmPrefs) {
        // if a valid alarm was found get all of the skip dates for that alarm into a single array
        [sortedSkipDates addObjectsFromArray:alarmPrefs.customSkipDates];
        [sortedSkipDates addObjectsFromArray:[alarmPrefs allHolidaySkipDates]];

        // sort the skip dates
        [sortedSkipDates sortUsingSelector:@selector(compare:)];
    }
    
    return [sortedSkipDates copy];
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

// returns a string that represents a date that is going to be skipped
+ (NSString *)skipDateStringForDate:(NSDate *)date
{
    // create the date formatter that will be used to display the dates
    if (sSLSkipDatesDateFormatter == nil) {
        sSLSkipDatesDateFormatter = [[NSDateFormatter alloc] init];
        sSLSkipDatesDateFormatter.dateFormat = @"EEEE, MMMM d, YYYY";
    }
    return [sSLSkipDatesDateFormatter stringFromDate:date];
}

@end
