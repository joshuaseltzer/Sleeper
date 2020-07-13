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
        // set defaults for the last known sunrise/sunset times
        self.lastSunriseHour = -1;
        self.lastSunriseMinute = -1;
        self.lastSunsetHour = -1;
        self.lastSunsetMinute = -1;

        // grab all of the auto-set alarms from the preferences file
        NSDictionary *autoSetAlarms = [SLPrefsManager allAutoSetAlarms];

        // if there are no auto-set alarms, do not create the today model
        if (autoSetAlarms != nil) {
            // update all of the auto-set alarms upon initialization
            if ([self hasUpdatedAutoSetTimes]) {
                [self bulkUpdateAutoSetAlarms:autoSetAlarms];
            }
        }
    }
    return self;
}

// Routine that will update the dictionary of multiple auto-set alarms.  This method is meant to be ran on a scheduled basis to check all auto-set alarms at once.
// The dictionary of alarms is keyed by the auto-set option as a number.
- (void)bulkUpdateAutoSetAlarms:(NSDictionary *)autoSetAlarms
{
    NSLog(@"SELTZER - updating all auto-set alarms");

    // only proceed if auto-set alarms exist
    if (autoSetAlarms != nil) {
        // check to ensure that the sunrise/sunset times were set appropriately
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
    } else if (self.autoupdatingTodayModel != nil) {
        // if the today model was already created but no auto-set alarms exist, we can destroy it now
        [self.autoupdatingTodayModel removeObserver:self];
        self.autoupdatingTodayModel = nil;
    }
    
}

// routine to update to a single alarm object that has updated auto-set settings
- (void)updateAutoSetAlarm:(NSDictionary *)alarmDict
{
    NSLog(@"SELTZER - updating a single auto-set alarm");

    // check to ensure a valid alarm dictionary object was passed
    if (alarmDict != nil) {
        NSNumber *autoSetOptionNum = [alarmDict objectForKey:kSLAutoSetOptionKey];
        if (autoSetOptionNum != nil) {
            // create an instance of the alarm manager that will get us the actual alarm objects
            MTAlarmManager *alarmManager = [[objc_getClass("MTAlarmManager") alloc] init];

            // check to ensure we are using the latest auto-set times from the today model (we do not care about the return value here)
            [self hasUpdatedAutoSetTimes];

            // update the alarm according to the auto-set option
            SLAutoSetOption autoSetOption = [autoSetOptionNum integerValue];
            if (autoSetOption == kSLAutoSetOptionSunrise) {
                [self updateAlarms:@[alarmDict] usingAlarmManager:alarmManager withBaseHour:self.lastSunriseHour withBaseMinute:self.lastSunriseMinute];
            } else if (autoSetOption == kSLAutoSetOptionSunset) {
                [self updateAlarms:@[alarmDict] usingAlarmManager:alarmManager withBaseHour:self.lastSunsetHour withBaseMinute:self.lastSunsetMinute];
            }
        } 
    }
}

// Returns whether or not there were updated auto-set times using the today model that will be created and monitored in this instance.
// If there are changes, it saves the new auto-set time components to this instance.
- (BOOL)hasUpdatedAutoSetTimes
{
    // by default, assume there are no changes
    BOOL hasUpdatedAutoSetTime = NO;

    // if the today model is not running, create it now
    if (self.autoupdatingTodayModel == nil) {
        // create the autoupdating today model object to retrieve the sunrise/sunset times
        self.autoupdatingTodayModel = [objc_getClass("WATodayModel") autoupdatingLocationModelWithPreferences:[objc_getClass("WeatherPreferences") sharedPreferences] effectiveBundleIdentifier:nil];
        [self.autoupdatingTodayModel addObserver:self];
        NSLog(@"SELTZER - creating autoupdatingTodayModel %@", self.autoupdatingTodayModel);

        // create the persistent timers that will be used to update all of the auto-set timers twice per day
    }

    // grab some information from the today model's forecast model if it exists
    if (self.autoupdatingTodayModel.forecastModel != nil && self.autoupdatingTodayModel.forecastModel.location != nil) {
        NSDate *sunriseDate = self.autoupdatingTodayModel.forecastModel.sunrise;
        NSDate *sunsetDate = self.autoupdatingTodayModel.forecastModel.sunset;
        NSTimeZone *timeZone = self.autoupdatingTodayModel.forecastModel.location.timeZone;

        // as long as the appropriate information from the forecast model exists, continue checking the times
        if (sunriseDate != nil && sunsetDate != nil && timeZone != nil) {
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
        }
    }

    return hasUpdatedAutoSetTime;
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
                    offsetMinute = [[alarmDict objectForKey:kSLAutoSetOffsetMinuteKey] integerValue];
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
        } else {
            // use this as an opportunity to remove the preferences for this alarm since it likely no longer exists
            [SLPrefsManager deleteAlarmForAlarmId:alarmId];
        }
    }
}

#pragma mark - WATodayModelObserver

// called when a today model is asking for an update
- (void)todayModelWantsUpdate:(id)todayModel
{
    NSLog(@"SELTZER - todayModelWantsUpdate");
    NSLog(@"SELTZER - forecastModel %@", self.autoupdatingTodayModel.forecastModel);

    // ensure that our today model has the correct and updated information needed to update the alarms
    if ([self hasUpdatedAutoSetTimes]) {
        [self bulkUpdateAutoSetAlarms:[SLPrefsManager allAutoSetAlarms]];

        NSDictionary *forecast = @{@"FromWhichCall":@"forecastWasUpdated", @"Sunrise":self.autoupdatingTodayModel.forecastModel.sunrise, @"Sunset":self.autoupdatingTodayModel.forecastModel.sunset, @"LocationDescription":self.autoupdatingTodayModel.forecastModel.location.description, @"ForecastModelDescription":self.autoupdatingTodayModel.forecastModel.description};
        [SLPrefsManager debugWriteForecastUpdateToFile:forecast];
    }
}

// invoked whenever the forecast model is updated (from within the Weather application)
- (void)todayModel:(id)todayModel forecastWasUpdated:(WAForecastModel *)forecastModel
{
    NSLog(@"SELTZER - forecastWasUpdated");
    NSLog(@"SELTZER - forecastModel %@", forecastModel);

    // ensure that our today model has the correct and updated information needed to update the alarms
    if ([self hasUpdatedAutoSetTimes]) {
        [self bulkUpdateAutoSetAlarms:[SLPrefsManager allAutoSetAlarms]];

        NSDictionary *forecast = @{@"FromWhichCall":@"forecastWasUpdated", @"Sunrise":self.autoupdatingTodayModel.forecastModel.sunrise, @"Sunset":self.autoupdatingTodayModel.forecastModel.sunset, @"LocationDescription":self.autoupdatingTodayModel.forecastModel.location.description, @"ForecastModelDescription":self.autoupdatingTodayModel.forecastModel.description};
        [SLPrefsManager debugWriteForecastUpdateToFile:forecast];
    }
}

@end
