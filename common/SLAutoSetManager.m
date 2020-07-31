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
#import "SLCompatibilityHelper.h"
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
- (BOOL)_reloadForecastData:(BOOL)shouldReload;

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

// define the default hour/minute values for the auto-set times
static NSInteger const kSLDefaultHourMinute = -1;

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
        self.lastSunriseHour = kSLDefaultHourMinute;
        self.lastSunriseMinute = kSLDefaultHourMinute;
        self.lastSunsetHour = kSLDefaultHourMinute;
        self.lastSunsetMinute = kSLDefaultHourMinute;

        // attempt to update all of the auto-set alarms
        [self updateAllAutoSetAlarms];
    }
    return self;
}

// invoked when one of the persistent timers is fired
- (void)persistentTimerFired:(PCSimpleTimer *)timer
{
    // Force a reload of the forecast data with the today model.  If there are any updates, this object will receive them via
    // the delegate methods of the observer.
    [self.autoupdatingTodayModel _reloadForecastData:YES];

    // re-create the timer that was fired to be scheduled for the next day
    if ([timer isEqual:self.startOfDayTimer]) {
        [self createStartOfDayTimer];
    } else if ([timer isEqual:self.midDayTimer]) {
        [self createMidDayTimer];
    }
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

// creates the today model if it wasn't already running and new persistent timers
- (void)setupAutoupdatingTodayModel
{
    // check to see if auto set can be enabled
    if ([SLCompatibilityHelper canEnableAutoSet]) {
        // Check if the today model exists, but the forecast does not.  In this situation, destroy the model
        // and then re-create it to get an updated forecast.
        if (self.autoupdatingTodayModel != nil && self.autoupdatingTodayModel.forecastModel == nil) {
            [self teardownAutoupdatingTodayModel];
        }

        // if the today model is not running, create it now
        if (self.autoupdatingTodayModel == nil) {
            // create the autoupdating today model object to retrieve the sunrise/sunset times
            self.autoupdatingTodayModel = [objc_getClass("WATodayModel") autoupdatingLocationModelWithPreferences:[objc_getClass("WeatherPreferences") sharedPreferences] effectiveBundleIdentifier:nil];
            [self.autoupdatingTodayModel addObserver:self];
        }

        // if the persistent timers are not running, create them now to periodically update all of the auto-set alarms
        if (self.startOfDayTimer == nil) {
            [self createStartOfDayTimer];
        }
        if (self.midDayTimer == nil) {
            [self createMidDayTimer];
        }
    } else {
        // if the auto-set feature cannot be enabled, ensure that the today model is destroyed
        [self teardownAutoupdatingTodayModel];
    }
}

// destroys the today model and corresponding timers
- (void)teardownAutoupdatingTodayModel
{
    // if the today model was already created but no auto-set alarms exist, we can destroy it now
    if (self.autoupdatingTodayModel != nil) {
        [self.autoupdatingTodayModel removeObserver:self];
        self.autoupdatingTodayModel = nil;
    }

    // destroy the persistent timers that might be scheduled to fire
    if (self.startOfDayTimer != nil) {
        [self.startOfDayTimer invalidate];
        self.startOfDayTimer = nil;
    }
    if (self.midDayTimer != nil) {
        [self.midDayTimer invalidate];
        self.midDayTimer = nil;
    }

    // reset the times to the defaults
    self.lastSunriseHour = kSLDefaultHourMinute;
    self.lastSunriseMinute = kSLDefaultHourMinute;
    self.lastSunsetHour = kSLDefaultHourMinute;
    self.lastSunsetMinute = kSLDefaultHourMinute;
}

// Routine that will update the dictionary of multiple auto-set alarms.  This method is meant to be ran on a scheduled basis to check all auto-set alarms at once.
// The dictionary of alarms is keyed by the auto-set option as a number.
- (void)bulkUpdateAutoSetAlarms:(NSDictionary *)autoSetAlarms
{
    // only proceed if auto-set alarms exist and valid times were generated
    if (autoSetAlarms != nil && self.lastSunriseHour != -1 && self.lastSunriseMinute != -1 && self.lastSunsetHour != -1 && self.lastSunsetMinute != -1) {
        // grab the array of auto-set alarms for each auto-set option (in NSDictionary format)
        NSArray *sunriseAlarms = [autoSetAlarms objectForKey:[NSNumber numberWithInteger:kSLAutoSetOptionSunrise]];
        NSArray *sunsetAlarms = [autoSetAlarms objectForKey:[NSNumber numberWithInteger:kSLAutoSetOptionSunset]];
        if (sunriseAlarms.count > 0 || sunsetAlarms.count > 0) {
            // update the alarms with the approprate date
            if (sunriseAlarms.count > 0) {
                [SLCompatibilityHelper updateAlarms:sunriseAlarms withBaseHour:self.lastSunriseHour withBaseMinute:self.lastSunriseMinute];
            }
            if (sunsetAlarms.count > 0) {
                [SLCompatibilityHelper updateAlarms:sunsetAlarms withBaseHour:self.lastSunsetHour withBaseMinute:self.lastSunsetMinute];
            }
        }
    }
}

// routine to update to a single alarm object that has updated auto-set settings
- (void)updateAutoSetAlarm:(NSDictionary *)alarmDict
{
    // check to ensure a valid alarm dictionary object was passed
    if (alarmDict != nil) {
        NSNumber *autoSetOptionNum = [alarmDict objectForKey:kSLAutoSetOptionKey];
        if (autoSetOptionNum != nil) {
            BOOL alarmNeedsUpdate = NO;
            if (![self.autoupdatingTodayModel _reloadForecastData:YES]) {
                // check to make sure the today model is running before updating the alarm
                if (self.autoupdatingTodayModel == nil || self.autoupdatingTodayModel.forecastModel == nil) {
                    [self setupAutoupdatingTodayModel];
                }

                // ensure we are using the latest auto-set times from the today model (we do not care about the return value here)
                [self hasUpdatedAutoSetTimes];
                alarmNeedsUpdate = YES;
            }
            
            // update the alarm according to the auto-set option as long as valid times were generated
            if (alarmNeedsUpdate && self.lastSunriseHour != -1 && self.lastSunriseMinute != -1 && self.lastSunsetHour != -1 && self.lastSunsetMinute != -1) {
                SLAutoSetOption autoSetOption = [autoSetOptionNum integerValue];
                if (autoSetOption == kSLAutoSetOptionSunrise) {
                    [SLCompatibilityHelper updateAlarms:@[alarmDict] withBaseHour:self.lastSunriseHour withBaseMinute:self.lastSunriseMinute];
                } else if (autoSetOption == kSLAutoSetOptionSunset) {
                    [SLCompatibilityHelper updateAlarms:@[alarmDict] withBaseHour:self.lastSunsetHour withBaseMinute:self.lastSunsetMinute];
                }
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

    // grab some information from the today model's forecast model if it exists
    if (self.autoupdatingTodayModel != nil && self.autoupdatingTodayModel.forecastModel != nil && self.autoupdatingTodayModel.forecastModel.location != nil) {
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

// updates all auto-set alarms if necessary
- (void)updateAllAutoSetAlarms
{
    // Update all auto-set alarms that might exist.  If there are no auto-set alarms, do not create the today model.
    NSDictionary *autoSetAlarms = [SLPrefsManager allAutoSetAlarms];
    if (autoSetAlarms != nil) {
        // if the today model hasn't been initiated yet, create it now
        if (self.autoupdatingTodayModel == nil) {
            [self setupAutoupdatingTodayModel];
        }

        // update all of the auto-set alarms upon initialization
        if ([self hasUpdatedAutoSetTimes]) {
            [self bulkUpdateAutoSetAlarms:autoSetAlarms];
        }
    } else {
        // attempt to teardown the today model
        [self teardownAutoupdatingTodayModel];
    }
}

#pragma mark - WATodayModelObserver

// called when a today model is asking for an update
- (void)todayModelWantsUpdate:(id)todayModel
{
    // attempt to update all of the auto-set alarms
    [self updateAllAutoSetAlarms];
}

// invoked whenever the forecast model is updated
- (void)todayModel:(id)todayModel forecastWasUpdated:(WAForecastModel *)forecastModel
{
    // attempt to update all of the auto-set alarms
    [self updateAllAutoSetAlarms];
}

@end
