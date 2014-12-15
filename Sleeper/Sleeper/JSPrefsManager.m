//
//  JSPrefsManager.m
//  Sleeper
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "JSPrefsManager.h"

// the path of our settings that is used to store the alarm snooze times
#define kJSSettingsPath    [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.joshuaseltzer.sleeper.plist"]

@implementation JSPrefsManager

// Return a dictionary with snooze information for a given alarm id.  Returns nil when no alarm is found
+ (NSMutableDictionary *)snoozeTimeForId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kJSSettingsPath];
    
    // if the clock preferences exist, attempt to get the alarms
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

// save custom snooze time for an alarm with the given alarm id and snooze time attributes
+ (void)saveSnoozeTimeForAlarmId:(NSString *)alarmId
                           hours:(NSInteger)hours
                         minutes:(NSInteger)minutes
                         seconds:(NSInteger)seconds
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kJSSettingsPath];
    
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
                [alarm setObject:[NSNumber numberWithInteger:hours] forKey:kJSHourKey];
                [alarm setObject:[NSNumber numberWithInteger:minutes] forKey:kJSMinuteKey];
                [alarm setObject:[NSNumber numberWithInteger:seconds] forKey:kJSSecondKey];
                break;
            }
        }
    }
    
    // check if the alarm was found, if so replace it
    if (!alarm) {
        // create a new alarm with the snooze time information
        NSDictionary *newAlarm = [NSDictionary dictionaryWithObjectsAndKeys:alarmId, kJSAlarmIdKey,
                                  [NSNumber numberWithInteger:hours], kJSHourKey,
                                  [NSNumber numberWithInteger:minutes], kJSMinuteKey,
                                  [NSNumber numberWithInteger:seconds], kJSSecondKey, nil];
        
        // add the object to the array
        [alarms addObject:newAlarm];
    }
    
    // add the alarms array to the preferences dictionary
    [prefs setObject:alarms forKey:kJSAlarmsKey];
    
    // write the updated preferences
    [prefs writeToFile:kJSSettingsPath atomically:YES];
}

// delete an alarm from our snooze time settings
+ (void)deleteSnoozeTimeForAlarmId:(NSString *)alarmId
{
    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kJSSettingsPath];
    
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
                [prefs writeToFile:kJSSettingsPath atomically:YES];
            }
        }
    }
}

@end
