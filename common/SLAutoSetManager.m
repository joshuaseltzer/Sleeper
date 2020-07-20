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

// this is a timer that will be able to fire even when SpringBoard is backgrounded
@interface PCSimpleTimer : NSObject

// initializer that will be used to create a persistent timer
- (id)initWithFireDate:(NSDate *)fireDate serviceIdentifier:(NSString *)serviceIdentifier target:(id)target selector:(SEL)selector userInfo:(NSDictionary *)userInfo;

// just like NSTimer, this will invalidate the timer object
- (void)invalidate;

// schedules the timer in the specified run loop
- (void)scheduleInRunLoop:(NSRunLoop *)runLoop;

@end

// this is the today model which will be instantiated when the singleton class is created
@interface WATodayAutoupdatingLocationModel : WATodayModel

// forces the location model to update it's forecast data
- (BOOL)_reloadForecastData:(BOOL)reload;

@end

@interface SLAutoSetManager ()

// the today model which will be used to observe for changes to the sunrise/sunset times
@property (nonatomic, strong) WATodayAutoupdatingLocationModel *autoupdatingTodayModel;

// the persistent timers that will be used to periodically update the auto-set alarms
@property (nonatomic, strong) PCSimpleTimer *startOfDayTimer;
@property (nonatomic, strong) PCSimpleTimer *midDayTimer;

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

// invoked when one of the persistent timers is fired
- (void)persistentTimerFired:(PCSimpleTimer *)timer
{
    NSLog(@"SELTZER - persistentTimerFired %@", timer);

    // force a reload of the forecast data with the today model
    BOOL hasUpdatedAutoSetTimes = [self.autoupdatingTodayModel _reloadForecastData:YES];

    // re-create the timer that was fired to be scheduled for the next day
    if ([timer isEqual:self.startOfDayTimer]) {
        [self createStartOfDayTimer];
    } else if ([timer isEqual:self.midDayTimer]) {
        [self createMidDayTimer];
    }

    NSDictionary *forecast = @{@"FromWhichCall":@"persistentTimerFired", @"_reloadForecastData":[NSNumber numberWithBool:hasUpdatedAutoSetTimes], @"Sunrise":self.autoupdatingTodayModel.forecastModel.sunrise, @"Sunset":self.autoupdatingTodayModel.forecastModel.sunset, @"LocationDescription":self.autoupdatingTodayModel.forecastModel.location.description, @"ForecastModelDescription":self.autoupdatingTodayModel.forecastModel.description};
    [SLPrefsManager debugWriteForecastUpdateToFile:forecast];
}

// creates the start of day timer for the following day and potentially invalidating/destroying the previous timer
- (void)createStartOfDayTimer
{
    // check to see if the start of day timer was already created
    if (self.startOfDayTimer) {
        [self.startOfDayTimer invalidate];
        self.startOfDayTimer = nil;
    }

    // create the date and timer that will fire at the start of the day tomorrow
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *adjustDateComponents = [[NSDateComponents alloc] init];
    adjustDateComponents.day = 1;
    adjustDateComponents.minute = arc4random_uniform(5) + 1;
    adjustDateComponents.second = arc4random_uniform(59) + 1;
    NSDate *startOfDayDate = [calendar dateByAddingComponents:adjustDateComponents toDate:[calendar startOfDayForDate:today] options:0];

    // as a sanity check, ensure that the new date that was calculated is in the future since we end up in an infinite loop otherwise
    if ([today compare:startOfDayDate] == NSOrderedAscending) {
        self.startOfDayTimer = [[objc_getClass("PCSimpleTimer") alloc] initWithFireDate:startOfDayDate
                                                                      serviceIdentifier:kSLBundleIdentifier
                                                                                 target:self
                                                                               selector:@selector(persistentTimerFired:)
                                                                               userInfo:nil];
        [self.startOfDayTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
    }
}

// creates the mid-day timer and potentially invalidating/destroying the previous timer
- (void)createMidDayTimer
{
    // check to see if the mid-day timer was already created
    if (self.midDayTimer) {
        [self.midDayTimer invalidate];
        self.midDayTimer = nil;
    }

    // create the date for the middle of the day either for the current day or the next day
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *adjustDateComponents = [[NSDateComponents alloc] init];
    adjustDateComponents.hour = 12;
    adjustDateComponents.minute = arc4random_uniform(5) + 1;
    adjustDateComponents.second = arc4random_uniform(59) + 1;
    NSDateComponents *todayDateComponents = [calendar components:NSCalendarUnitHour fromDate:today];
    if (todayDateComponents.hour > 11) {
        adjustDateComponents.day = 1;
    }
    NSDate *midDayDate = [calendar dateByAddingComponents:adjustDateComponents toDate:[calendar startOfDayForDate:today] options:0];

    // as a sanity check, ensure that the new date that was calculated is in the future since we end up in an infinite loop otherwise
    if ([today compare:midDayDate] == NSOrderedAscending) {
        self.midDayTimer = [[objc_getClass("PCSimpleTimer") alloc] initWithFireDate:midDayDate
                                                                  serviceIdentifier:kSLBundleIdentifier
                                                                             target:self
                                                                           selector:@selector(persistentTimerFired:)
                                                                           userInfo:nil];
        [self.midDayTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
    }
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

        // destroy the persistent timers that are scheduled to fire
        if (self.startOfDayTimer) {
            [self.startOfDayTimer invalidate];
            self.startOfDayTimer = nil;
        }
        if (self.midDayTimer) {
            [self.midDayTimer invalidate];
            self.midDayTimer = nil;
        }
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
    }

    // if the persistent timers are not running, create them now to periodically update all of the auto-set alarms
    if (self.startOfDayTimer == nil) {
        [self createStartOfDayTimer];
    }
    if (self.midDayTimer == nil) {
        [self createMidDayTimer];
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
    }

    NSDictionary *forecast = @{@"FromWhichCall":@"todayModelWantsUpdate", @"Sunrise":self.autoupdatingTodayModel.forecastModel.sunrise, @"Sunset":self.autoupdatingTodayModel.forecastModel.sunset, @"LocationDescription":self.autoupdatingTodayModel.forecastModel.location.description, @"ForecastModelDescription":self.autoupdatingTodayModel.forecastModel.description};
    [SLPrefsManager debugWriteForecastUpdateToFile:forecast];
}

// invoked whenever the forecast model is updated (from within the Weather application)
- (void)todayModel:(id)todayModel forecastWasUpdated:(WAForecastModel *)forecastModel
{
    NSLog(@"SELTZER - forecastWasUpdated");
    NSLog(@"SELTZER - forecastModel %@", forecastModel);

    // ensure that our today model has the correct and updated information needed to update the alarms
    if ([self hasUpdatedAutoSetTimes]) {
        [self bulkUpdateAutoSetAlarms:[SLPrefsManager allAutoSetAlarms]];
    }

    NSDictionary *forecast = @{@"FromWhichCall":@"forecastWasUpdated", @"Sunrise":self.autoupdatingTodayModel.forecastModel.sunrise, @"Sunset":self.autoupdatingTodayModel.forecastModel.sunset, @"LocationDescription":self.autoupdatingTodayModel.forecastModel.location.description, @"ForecastModelDescription":self.autoupdatingTodayModel.forecastModel.description};
    [SLPrefsManager debugWriteForecastUpdateToFile:forecast];
}

@end
