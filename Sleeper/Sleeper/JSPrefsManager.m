//
//  JSPrefsManager.m
//  Sleeper
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "JSPrefsManager.h"

// the path of our settings that is used to store the alarm snooze times
#define SETTINGS_PATH    [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.joshuaseltzer.sleeper.plist"]

@implementation JSPrefsManager

// Return a dictionary with alarm information for a given alarm Id.  Return nil if no alarm is found.
+ (NSMutableDictionary *)alarmInfoForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the alarm preferences exist, attempt to get the alarms
    if (prefs) {
        // get the array of dictionaries of all of the alarms
        NSMutableArray *alarms = [prefs objectForKey:kJSAlarmsKey];
        
        // iterate through the alarms until we the find the one with a matching id
        for (NSMutableDictionary *alarm in alarms) {
            if ([[alarm objectForKey:kJSAlarmIdKey] isEqualToString:alarmId]) {
                return alarm;
            }
        }
    }
    
    // return nil if no alarm is found
    return nil;
}

// Return a boolean that signifies whether or not skip is enabled for a given alarm Id.  Return NO
// if no alarm is found
+ (BOOL)skipEnabledForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the alarm preferences exist, attempt to get the alarms
    if (prefs) {
        // get the array of dictionaries of all of the alarms
        NSMutableArray *alarms = [prefs objectForKey:kJSAlarmsKey];
        
        // iterate through the alarms until we the find the one with a matching id
        for (NSMutableDictionary *alarm in alarms) {
            if ([[alarm objectForKey:kJSAlarmIdKey] isEqualToString:alarmId]) {
                return [[alarm objectForKey:kJSSkipEnabledKey] boolValue];
            }
        }
    }
    
    // return NO if no alarm is found
    return NO;
}

// Return the number of hours to skip the alarm for a given alarm Id.  Return NSNotFound if no skip
// hours were found.
+ (NSInteger)skipHoursForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the alarm preferences exist, attempt to get the alarms
    if (prefs) {
        // get the array of dictionaries of all of the alarms
        NSMutableArray *alarms = [prefs objectForKey:kJSAlarmsKey];
        
        // iterate through the alarms until we the find the one with a matching id
        for (NSMutableDictionary *alarm in alarms) {
            if ([[alarm objectForKey:kJSAlarmIdKey] isEqualToString:alarmId]) {
                return [[alarm objectForKey:kJSSkipHoursKey] integerValue];
            }
        }
    }
    
    // return NSNotFound if no alarm is found
    return NSNotFound;
}

// save all attributes for an alarm given the alarm Id
+ (void)saveAlarmForAlarmId:(NSString *)alarmId
                snoozeHours:(NSInteger)snoozeHours
              snoozeMinutes:(NSInteger)snoozeMinutes
              snoozeSeconds:(NSInteger)snoozeSeconds
                skipEnabled:(BOOL)skipEnabled
                  skipHours:(NSInteger)skipHours
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the clock preferences don't exist, create a new mutable dictionary now
    if (!prefs) {
        prefs = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    // array of dictionaries of all of the alarms
    NSMutableArray *alarms = [prefs objectForKey:kJSAlarmsKey];
    
    // if the alarms do not exist in our preferences, create the alarms array now
    NSMutableDictionary *alarm = nil;
    if (!alarms) {
        alarms = [[NSMutableArray alloc] initWithCapacity:1];
    } else {
        // otherwise attempt to find the desired alarm in the array
        for (alarm in alarms) {
            if ([[alarm objectForKey:kJSAlarmIdKey] isEqualToString:alarmId]) {
                // update the alarm dictionary with the values given
                [alarm setObject:[NSNumber numberWithInteger:snoozeHours] forKey:kJSSnoozeHourKey];
                [alarm setObject:[NSNumber numberWithInteger:snoozeMinutes] forKey:kJSSnoozeMinuteKey];
                [alarm setObject:[NSNumber numberWithInteger:snoozeSeconds] forKey:kJSSnoozeSecondKey];
                [alarm setObject:[NSNumber numberWithBool:skipEnabled] forKey:kJSSkipEnabledKey];
                [alarm setObject:[NSNumber numberWithInteger:skipHours] forKey:kJSSkipHoursKey];
                [alarm setObject:[NSNumber numberWithInteger:kJSSkipActivatedStatusUnknown]
                          forKey:kJSSkipActivatedStatusKey];
                break;
            }
        }
    }
    
    // check if the alarm was found, if so replace it
    if (!alarm) {
        // create a new alarm with the given attributes
        NSDictionary *newAlarm = [NSDictionary dictionaryWithObjectsAndKeys:alarmId, kJSAlarmIdKey,
                                  [NSNumber numberWithInteger:snoozeHours], kJSSnoozeHourKey,
                                  [NSNumber numberWithInteger:snoozeMinutes], kJSSnoozeMinuteKey,
                                  [NSNumber numberWithInteger:snoozeSeconds], kJSSnoozeSecondKey,
                                  [NSNumber numberWithBool:skipEnabled], kJSSkipEnabledKey,
                                  [NSNumber numberWithInteger:skipHours], kJSSkipHoursKey,
                                  [NSNumber numberWithInteger:kJSSkipActivatedStatusUnknown],
                                  kJSSkipActivatedStatusKey, nil];
        
        // add the object to the array
        [alarms addObject:newAlarm];
    }
    
    // add the alarms array to the preferences dictionary
    [prefs setObject:alarms forKey:kJSAlarmsKey];
    
    // write the updated preferences
    [prefs writeToFile:SETTINGS_PATH atomically:YES];
}

// save the skip activation status for a given alarm
+ (void)setSkipActivatedStatusForAlarmId:(NSString *)alarmId
                     skipActivatedStatus:(JSPrefsSkipActivatedStatus)skipActivatedStatus
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the clock preferences don't exist, create a new mutable dictionary now
    if (!prefs) {
        prefs = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    // array of dictionaries of all of the alarms
    NSMutableArray *alarms = [prefs objectForKey:kJSAlarmsKey];
    
    // if the alarms do not exist in our preferences, create the alarms array now
    NSMutableDictionary *alarm = nil;
    if (!alarms) {
        alarms = [[NSMutableArray alloc] initWithCapacity:1];
    } else {
        // otherwise attempt to find the desired alarm in the array
        for (alarm in alarms) {
            if ([[alarm objectForKey:kJSAlarmIdKey] isEqualToString:alarmId]) {
                // update the alarm dictionary with the values given
                [alarm setObject:[NSNumber numberWithInteger:skipActivatedStatus]
                          forKey:kJSSkipActivatedStatusKey];
                break;
            }
        }
    }
    
    // check if the alarm was found, if so replace it
    if (!alarm) {
        // create a new alarm with the given attributes
        NSDictionary *newAlarm = [NSDictionary dictionaryWithObjectsAndKeys:alarmId, kJSAlarmIdKey,
                                  [NSNumber numberWithInteger:skipActivatedStatus],
                                  kJSSkipActivatedStatusKey, nil];
        
        // add the object to the array
        [alarms addObject:newAlarm];
    }
    
    // add the alarms array to the preferences dictionary
    [prefs setObject:alarms forKey:kJSAlarmsKey];
    
    // write the updated preferences
    [prefs writeToFile:SETTINGS_PATH atomically:YES];
}

// Return the status that signifies whether or not skip is activated for a given alarm Id.  Return
// NSNotFound if no alarm is found.
+ (JSPrefsSkipActivatedStatus)skipActivatedStatusForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // if the alarm preferences exist, attempt to get the alarms
    if (prefs) {
        // get the array of dictionaries of all of the alarms
        NSMutableArray *alarms = [prefs objectForKey:kJSAlarmsKey];
        
        // iterate through the alarms until we the find the one with a matching id
        for (NSMutableDictionary *alarm in alarms) {
            if ([[alarm objectForKey:kJSAlarmIdKey] isEqualToString:alarmId]) {
                return [[alarm objectForKey:kJSSkipActivatedStatusKey] integerValue];
            }
        }
    }
    
    // return NSNotFound if no alarm is found
    return NSNotFound;
}

// delete an alarm from our settings
+ (void)deleteAlarmForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    
    // only continue trying to delete the alarm if our preferences exist
    if (prefs) {
        // array of dictionaries of all of the alarms
        NSMutableArray *alarms = [prefs objectForKey:kJSAlarmsKey];
        
        // only continue if any Alarms exist in the preferences
        if (alarms) {
            // iterate through all of the alarms until we find the one we desire
            BOOL alarmFound = NO;
            for (int i = 0; i < alarms.count; i++) {
                // get the alarm at the given index
                NSDictionary *alarm = [alarms objectAtIndex:i];
                
                // check if this is the desired alarm
                if ([[alarm objectForKey:kJSAlarmIdKey] isEqualToString:alarmId]) {
                    // remove the alarm from the array
                    [alarms removeObjectAtIndex:i];
                    alarmFound = YES;
                    break;
                }
            }
            
            // if an alarm was found and deleted, then update the data source
            if (alarmFound) {
                // add the alarms array to the preferences dictionary
                [prefs setObject:alarms forKey:kJSAlarmsKey];
                
                // write the updated preferences
                [prefs writeToFile:SETTINGS_PATH atomically:YES];
            }
        }
    }
}

@end