//
//  SLPrefsManager.h
//  The preferences manager for the tweak.
//
//  Created by Joshua Seltzer on 12/8/14.
//  Copyright (c) 2014 Joshua Seltzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLAlarmPrefs.h"

// the bundle path which includes some custom preference files needed for the tweak
#define kSLSleeperBundle                                [NSBundle bundleWithPath:@"/Library/Application Support/Sleeper.bundle"]

// constant keys for the values we are going to add to the preferences file
static NSString *const kSLAlarmsKey =                   @"Alarms";
static NSString *const kSLAlarmIdKey =                  @"alarmId";
static NSString *const kSLSnoozeHourKey =               @"snoozeTimeHour";
static NSString *const kSLSnoozeMinuteKey =             @"snoozeTimeMinute";
static NSString *const kSLSnoozeSecondKey =             @"snoozeTimeSecond";
static NSString *const kSLSkipEnabledKey =              @"skipEnabled";
static NSString *const kSLSkipHourKey =                 @"skipTimeHour";
static NSString *const kSLSkipMinuteKey =               @"skipTimeMinute";
static NSString *const kSLSkipSecondKey =               @"skipTimeSecond";
static NSString *const kSLSkipActivatedStatusKey =      @"skipActivatedStatus";
static NSString *const kSLSkipDatesKey =                @"skipDates";
static NSString *const kSLHolidaySkipDatesKey =         @"holidaySkipDates";
static NSString *const kSLCustomSkipDatesKey =          @"customSkipDates";
static NSString *const kSLCustomSkipDateStringsKey =    @"customSkipDateStrings";
static NSString *const kSLHolidayHolidaysKey =          @"holidays";
static NSString *const kSLHolidayNameKey =              @"name";
static NSString *const kSLHolidayDatesKey =             @"dates";

@class SLAlarmPrefs;

// manager that manages the retrieval, saving, and deleting of custom snooze times
@interface SLPrefsManager : NSObject

// returns the date formatter for converting to and from saving to the plist
+ (NSDateFormatter *)plistDateFormatter;

// Return an SLAlarmPrefs object with alarm information for a given alarm Id.  Return nil if no alarm is found.
+ (SLAlarmPrefs *)alarmPrefsForAlarmId:(NSString *)alarmId;

// save the specific alarm preferences object
+ (void)saveAlarmPrefs:(SLAlarmPrefs *)alarmPrefs;

// save the skip activation status for a given alarm
+ (void)setSkipActivatedStatusForAlarmId:(NSString *)alarmId
                     skipActivatedStatus:(SLPrefsSkipActivatedStatus)skipActivatedStatus;

// delete an alarm from our settings
+ (void)deleteAlarmForAlarmId:(NSString *)alarmId;

// Returns a dictionary that corresponds to the default holiday source for the given holiday resource name.
// This function will also remove any passed dates.
+ (NSDictionary *)holidayResourceForResourceName:(NSString *)resourceName;

// Returns the first available skip date for the given holiday name and country.  This function will not take into consideration any passed dates.
+ (NSDate *)firstSkipDateForHolidayName:(NSString *)holidayName inHolidayCountry:(SLHolidayCountry)holidayCountry;

// returns a corresponding country code for any given country
+ (NSString *)countryCodeForHolidayCountry:(SLHolidayCountry)country;

// returns a string that corresponds to the resource name for a given holiday country
+ (NSString *)resourceNameForHolidayCountry:(SLHolidayCountry)country;

// returns a string that corresponds to the resource name for a given country code
+ (NSString *)resourceNameForCountryCode:(NSString *)countryCode;

// returns the localized, friendly name to be displayed for the given country
+ (NSString *)friendlyNameForHolidayCountry:(SLHolidayCountry)country;

// Returns a string that represents a date that is going to be skipped.  If showRelativeString is enabled,
// a relative string is shown instead (i.e. Today, Tomorrow)
+ (NSString *)skipDateStringForDate:(NSDate *)date showRelativeString:(BOOL)showRelativeString;

@end
