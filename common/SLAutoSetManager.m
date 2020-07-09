//
//  SLAutoSetManager.m
//  A singleton object that will be used to manage the auto-set feature.
//
//  Created by Joshua Seltzer on 6/27/20.
//  Copyright (c) 2020 Joshua Seltzer. All rights reserved.
//

#import "SLAutoSetManager.h"
#import "SLPrefsManager.h"
#import "SLCommonHeaders.h"
#import <objc/runtime.h>

// this is the today model which will be instantiated when the singleton class is created
@interface WATodayAutoupdatingLocationModel : WATodayModel
@end

@interface SLAutoSetManager ()

// the today model which will be used to observe for changes to the sunrise/sunset times
@property (nonatomic, strong) WATodayAutoupdatingLocationModel *autoupdatingTodayModel;

// the last sunrise hour and minute components that were obtained from the today model
@property (nonatomic) NSInteger lastSunriseHour;
@property (nonatomic) NSInteger lastSunriseMinute;

// the last sunrise date that was obtained from the today model
@property (nonatomic) NSInteger lastSunsetHour;
@property (nonatomic) NSInteger lastSunsetMinute;

@end

@implementation SLAutoSetManager

// return a singleton instance of this manager
+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

// override the default initializer to potentially start monitoring for changes
- (id)init
{
    self = [super init];
    if (self) {
        // check to see if any auto-set alarms exist and update them immediately
        [self alarmsWithAutoSetUpdated];
        self.lastSunriseHour = -1;
        self.lastSunriseMinute = -1;
        self.lastSunsetHour = -1;
        self.lastSunsetMinute = -1;
    }
    return self;
}

// invoked whenever an alarm's preferences is updated to potentially start or stop monitoring for auto-set changes
- (void)alarmsWithAutoSetUpdated
{
    // grab all of the auto-set alarms from the preferences file
    NSDictionary *autoSetAlarms = [SLPrefsManager allAutoSetAlarms];
    if (autoSetAlarms != nil) {
        // if the today model isn't already running, create it now
        if (self.autoupdatingTodayModel == nil) {
            //self.autoupdatingTodayModel = [objc_getClass("WATodayModel") autoupdatingLocationModelWithPreferences:[[objc_getClass("WeatherPreferences") alloc] init] effectiveBundleIdentifier:nil];
            self.autoupdatingTodayModel = [objc_getClass("WATodayModel") autoupdatingLocationModelWithPreferences:[objc_getClass("WeatherPreferences") sharedPreferences] effectiveBundleIdentifier:nil];
            [self.autoupdatingTodayModel addObserver:self];
            NSLog(@"SELTZER - creating autoupdatingTodayModel %@", self.autoupdatingTodayModel);
        }

        // attempt to update the alarms with the forecast model as long as it exists
        if (self.autoupdatingTodayModel.forecastModel && self.autoupdatingTodayModel.forecastModel.sunrise && self.autoupdatingTodayModel.forecastModel.sunset && self.autoupdatingTodayModel.forecastModel.location) {
            // update any of the auto-set alarms if necessary
            if ([self hasUpdatedAutoSetTimeWithSunriseDate:self.autoupdatingTodayModel.forecastModel.sunrise
                                             andSunsetDate:self.autoupdatingTodayModel.forecastModel.sunset
                                                inTimeZone:self.autoupdatingTodayModel.forecastModel.location.timeZone]) {
                [self updateAutoSetAlarms:[SLPrefsManager allAutoSetAlarms]];
            }
        }
    } else if (self.autoupdatingTodayModel != nil) {
        // if there are no auto-set alarms and the today model exists, we can destroy it now
        [self.autoupdatingTodayModel removeObserver:self];
        self.autoupdatingTodayModel = nil;
    }
}

// Returns whether or not there were updated auto-set times with the given updated dates for a particular time zone
// If there are changes, it saves the previous auto-set components to this instance.
- (BOOL)hasUpdatedAutoSetTimeWithSunriseDate:(NSDate *)sunriseDate andSunsetDate:(NSDate *)sunsetDate inTimeZone:(NSTimeZone *)timeZone
{
    // by default, assume there are no changes
    BOOL hasUpdatedAutoSetTime = NO;

    // define the calendar with the given time zone
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:timeZone];

    // check the date components for the sunrise date
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:sunriseDate];
    NSInteger newSunriseHour = [dateComponents hour];
    NSInteger newSunriseMinute = [dateComponents minute];
    if (newSunriseHour != self.lastSunriseHour || newSunriseMinute != self.lastSunriseMinute) {
        self.lastSunriseHour = newSunriseHour;
        self.lastSunriseMinute = newSunriseMinute;
        hasUpdatedAutoSetTime = YES;
    }
    
    // check the date components for the sunset date
    dateComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:sunsetDate];
    NSInteger newSunsetHour = [dateComponents hour];
    NSInteger newSunsetMinute = [dateComponents minute];
    if (newSunsetHour != self.lastSunsetHour || newSunsetMinute != self.lastSunsetMinute) {
        self.lastSunsetHour = newSunsetHour;
        self.lastSunsetMinute = newSunsetMinute;
        hasUpdatedAutoSetTime = YES;
    }
    
    return hasUpdatedAutoSetTime;
}

// routine that will update any applicable alarms
- (void)updateAutoSetAlarms:(NSDictionary *)autoSetAlarms
{
    // only proceed if auto set alarms exist and if the sunrise/sunset times were set appropriately
    if (autoSetAlarms != nil && self.lastSunriseHour != -1 && self.lastSunriseMinute != -1 && self.lastSunsetHour != -1 && self.lastSunsetMinute != -1) {
        // grab the array of auto-set alarms for each auto-set option (in NSDictionary format)
        NSArray *sunriseAlarms = [autoSetAlarms objectForKey:[NSNumber numberWithInteger:kSLAutoSetOptionSunrise]];
        NSArray *sunsetAlarms = [autoSetAlarms objectForKey:[NSNumber numberWithInteger:kSLAutoSetOptionSunset]];
        if (sunriseAlarms.count > 0 || sunsetAlarms.count > 0) {
            // create an instance of the alarm manager that will get us the actual alarm objects
            MTAlarmManager *alarmManager = [[objc_getClass("MTAlarmManager") alloc] init];

            // update the alarms with the approprate date
            if (sunriseAlarms.count > 0) {
                [self updateAlarms:sunriseAlarms usingAlarmManager:alarmManager withBaseHour:self.lastSunriseHour withBaseMinute:self.lastSunriseMinute];
            }
            if (sunsetAlarms.count > 0) {
                [self updateAlarms:sunsetAlarms usingAlarmManager:alarmManager withBaseHour:self.lastSunsetHour withBaseMinute:self.lastSunsetMinute];
            }
        }
    }
}

// updates an array of alarms (in dictionary format) using the provided alarm manager with the last saved components
- (void)updateAlarms:(NSArray *)alarms usingAlarmManager:(MTAlarmManager *)alarmManager withBaseHour:(NSInteger)baseHour withBaseMinute:(NSInteger)baseMinute
{
    // update alarms using the auto-set date passed, along with any offset that might be required for the alarm
    for (NSDictionary *alarmDict in alarms) {
        // grab the alarm Id from the alarm dictionary so that we can create a system alarm object
        NSString *alarmId = [alarmDict objectForKey:kSLAlarmIdKey];
        MTAlarm *alarm = [alarmManager alarmWithIDString:alarmId];
        if (alarm != nil) {
            // create a mutable copy of the alarm
            MTMutableAlarm *mutableAlarm = [alarm mutableCopy];
            if (mutableAlarm != nil) {
                // adjust the hour and minute based on the offset preferences
                SLAutoSetOffsetOption offsetOption = [[alarmDict objectForKey:kSLAutoSetOffsetOptionKey] integerValue];
                NSInteger offsetHour = 0;
                NSInteger offsetMinute = 0;
                if (offsetOption != kSLAutoSetOffsetOptionOff) {
                    offsetHour = [[alarmDict objectForKey:kSLAutoSetOffsetHourKey] integerValue];
                    offsetMinute = [[alarmDict objectForKey:kSLAutoSetOffsetHourKey] integerValue];
                    if (offsetOption == kSLAutoSetOffsetOptionBefore) {
                        offsetHour = offsetHour * -1;
                        offsetMinute = offsetMinute * -1;
                    }
                }

                // update the alarm's hour and minute with the appropriate, adjusted time
                [mutableAlarm setHour:baseHour + offsetHour];
                [mutableAlarm setMinute:baseMinute + offsetMinute];

                // persist the changes
                [alarmManager updateAlarm:mutableAlarm];
            }
        }
    }
}

#pragma mark - WATodayModelObserver

// called when a today model is asking for an update
- (void)todayModelWantsUpdate:(id)todayModel
{
    NSLog(@"SELTZER - todayModelWantsUpdate");
    NSLog(@"SELTZER - forecastModel %@", self.autoupdatingTodayModel.forecastModel);

    // check to see if the today model being updated is the instance we created
    if (todayModel == self.autoupdatingTodayModel && self.autoupdatingTodayModel.forecastModel && self.autoupdatingTodayModel.forecastModel.sunrise && self.autoupdatingTodayModel.forecastModel.sunset) {
        // update any of the auto-set alarms if necessary
        if ([self hasUpdatedAutoSetTimeWithSunriseDate:self.autoupdatingTodayModel.forecastModel.sunrise
                                         andSunsetDate:self.autoupdatingTodayModel.forecastModel.sunset
                                            inTimeZone:self.autoupdatingTodayModel.forecastModel.location.timeZone]) {
            NSLog(@"SELTZER - updating the auto-set alarms");
            [self updateAutoSetAlarms:[SLPrefsManager allAutoSetAlarms]];

            NSDictionary *forecast = @{@"FromWhichCall":@"forecastWasUpdated", @"Sunrise":self.autoupdatingTodayModel.forecastModel.sunrise, @"Sunset":self.autoupdatingTodayModel.forecastModel.sunset, @"LocationDescription":self.autoupdatingTodayModel.forecastModel.location.description, @"ForecastModelDescription":self.autoupdatingTodayModel.forecastModel.description};
            [SLPrefsManager debugWriteForecastUpdateToFile:forecast];
        }
    }
}

// invoked whenever the forecast model is updated (from within the Weather application)
- (void)todayModel:(id)todayModel forecastWasUpdated:(WAForecastModel *)forecastModel
{
    NSLog(@"SELTZER - forecastWasUpdated");
    NSLog(@"SELTZER - forecastModel %@", forecastModel);

    // check to see if the today model being updated is the instance we created
    if (self.autoupdatingTodayModel.forecastModel && self.autoupdatingTodayModel.forecastModel.sunrise && self.autoupdatingTodayModel.forecastModel.sunset && self.autoupdatingTodayModel.forecastModel.location) {
        // update any of the auto-set alarms if necessary
        if ([self hasUpdatedAutoSetTimeWithSunriseDate:self.autoupdatingTodayModel.forecastModel.sunrise
                                         andSunsetDate:self.autoupdatingTodayModel.forecastModel.sunset
                                            inTimeZone:self.autoupdatingTodayModel.forecastModel.location.timeZone]) {
            NSLog(@"SELTZER - updating the auto-set alarms");
            [self updateAutoSetAlarms:[SLPrefsManager allAutoSetAlarms]];

            NSDictionary *forecast = @{@"FromWhichCall":@"forecastWasUpdated", @"Sunrise":self.autoupdatingTodayModel.forecastModel.sunrise, @"Sunset":self.autoupdatingTodayModel.forecastModel.sunset, @"LocationDescription":self.autoupdatingTodayModel.forecastModel.location.description, @"ForecastModelDescription":self.autoupdatingTodayModel.forecastModel.description};
            [SLPrefsManager debugWriteForecastUpdateToFile:forecast];
        }
    }
}

@end
