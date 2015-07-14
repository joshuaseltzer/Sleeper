//
//  JSPrefsManager.h
//  Sleeper
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import <Foundation/Foundation.h>

// constant keys for the values we are going to add to the preferences file
static NSString *const kJSAlarmIdKey =          @"alarmId";
static NSString *const kJSAlarmsKey =           @"Alarms";
static NSString *const kJSSnoozeHourKey =       @"snoozeTimeHour";
static NSString *const kJSSnoozeMinuteKey =     @"snoozeTimeMinute";
static NSString *const kJSSnoozeSecondKey =     @"snoozeTimeSecond";

// constants that define the default snooze time
static NSInteger const kJSDefaultSnoozeHour =   0;
static NSInteger const kJSDefaultSnoozeMinute = 9;
static NSInteger const kJSDefaultSnoozeSecond = 0;

// manager that manages the retrieval, saving, and deleting of custom snooze times
@interface JSPrefsManager : NSObject

// Return a dictionary with snooze information for a given alarm id.  Returns nil when no alarm is found
+ (NSMutableDictionary *)snoozeTimeForId:(NSString *)alarmId;

// save custom snooze time for an alarm with the given alarm id and snooze time attributes
+ (void)saveSnoozeTimeForAlarmId:(NSString *)alarmId
                           hours:(NSInteger)hours
                         minutes:(NSInteger)minutes
                         seconds:(NSInteger)seconds;

// delete an alarm from our snooze time settings
+ (void)deleteSnoozeTimeForAlarmId:(NSString *)alarmId;

@end
