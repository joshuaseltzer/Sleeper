//
//  JSPrefsManager.h
//  Sleeper
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import <Foundation/Foundation.h>

// constant keys for the values we are going to add to the preferences file
static NSString *const kJSAlarmIdKey =              @"alarmId";
static NSString *const kJSAlarmsKey =               @"Alarms";
static NSString *const kJSSnoozeHourKey =           @"snoozeTimeHour";
static NSString *const kJSSnoozeMinuteKey =         @"snoozeTimeMinute";
static NSString *const kJSSnoozeSecondKey =         @"snoozeTimeSecond";
static NSString *const kJSSkipEnabledKey =          @"skipEnabled";
static NSString *const kJSSkipHoursKey =            @"skipHours";
static NSString *const kJSSkipActivatedStatusKey =  @"skipActivatedStatus";

// constants that define the default values
static NSInteger const kJSDefaultSnoozeHour =   0;
static NSInteger const kJSDefaultSnoozeMinute = 9;
static NSInteger const kJSDefaultSnoozeSecond = 0;
static NSInteger const kJSDefaultSkipHours =    3;

// enum to define the different options that can be returned for the alarm's skip activation
typedef enum JSPrefsSkipActivatedStatus : NSInteger {
    kJSSkipActivatedStatusActivated,
    kJSSkipActivatedStatusDisabled,
    kJSSkipActivatedStatusUnknown
} JSPrefsSkipActivatedStatus;

// manager that manages the retrieval, saving, and deleting of custom snooze times
@interface JSPrefsManager : NSObject

// Return a dictionary with alarm information for a given alarm Id.  Return nil if no alarm is found.
+ (NSMutableDictionary *)alarmInfoForAlarmId:(NSString *)alarmId;

// Return a boolean that signifies whether or not skip is enabled for a given alarm Id.  Return NO
// if no alarm is found.
+ (BOOL)skipEnabledForAlarmId:(NSString *)alarmId;

// Return the number of hours to skip the alarm for a given alarm Id.  Return NSNotFound if no skip
// hours were found.
+ (NSInteger)skipHoursForAlarmId:(NSString *)alarmId;

// save all attributes for an alarm given the alarm Id
+ (void)saveAlarmForAlarmId:(NSString *)alarmId
                snoozeHours:(NSInteger)snoozeHours
              snoozeMinutes:(NSInteger)snoozeMinutes
              snoozeSeconds:(NSInteger)snoozeSeconds
                skipEnabled:(BOOL)skipEnabled
                  skipHours:(NSInteger)skipHours;

// save the skip activation status for a given alarm
+ (void)setSkipActivatedStatusForAlarmId:(NSString *)alarmId
                     skipActivatedStatus:(JSPrefsSkipActivatedStatus)skipActivatedStatus;

// Return the status that signifies whether or not skip is activated for a given alarm Id.  Return
// NSNotFound if no alarm is found.
+ (JSPrefsSkipActivatedStatus)skipActivatedStatusForAlarmId:(NSString *)alarmId;

// delete an alarm from our settings
+ (void)deleteAlarmForAlarmId:(NSString *)alarmId;

@end