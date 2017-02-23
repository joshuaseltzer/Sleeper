//
//  SLPrefsManager.h
//  The preferences manager for the tweak.
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import "SLAlarmPrefs.h"

// constant keys for the values we are going to add to the preferences file
static NSString *const kSLAlarmsKey =               @"Alarms";
static NSString *const kSLAlarmIdKey =              @"alarmId";
static NSString *const kSLSnoozeHourKey =           @"snoozeTimeHour";
static NSString *const kSLSnoozeMinuteKey =         @"snoozeTimeMinute";
static NSString *const kSLSnoozeSecondKey =         @"snoozeTimeSecond";
static NSString *const kSLSkipEnabledKey =          @"skipEnabled";
static NSString *const kSLSkipHourKey =             @"skipTimeHour";
static NSString *const kSLSkipMinuteKey =           @"skipTimeMinute";
static NSString *const kSLSkipSecondKey =           @"skipTimeSecond";
static NSString *const kSLSkipActivatedStatusKey =  @"skipActivatedStatus";

// manager that manages the retrieval, saving, and deleting of custom snooze times
@interface SLPrefsManager : NSObject

// Return an SLAlarmPrefs object with alarm information for a given alarm Id.  Return nil if no alarm is found.
+ (SLAlarmPrefs *)alarmPrefsForAlarmId:(NSString *)alarmId;

// save the specific alarm preferences object
+ (void)saveAlarmPrefs:(SLAlarmPrefs *)alarmPrefs;

// Return the status that signifies whether or not skip is activated for a given alarm Id.  Return
// NSNotFound if no alarm is found.
+ (SLPrefsSkipActivatedStatus)skipActivatedStatusForAlarmId:(NSString *)alarmId;

// save the skip activation status for a given alarm
+ (void)setSkipActivatedStatusForAlarmId:(NSString *)alarmId
                     skipActivatedStatus:(SLPrefsSkipActivatedStatus)skipActivatedStatus;

// delete an alarm from our settings
+ (void)deleteAlarmForAlarmId:(NSString *)alarmId;

@end
