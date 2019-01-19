//
//  SLAlarmPrefs.m
//  Object which includes Sleeper preferences for a specific alarm.
//
//  Created by Joshua Seltzer on 2/21/17.
//
//

#import "SLAlarmPrefs.h"
#import "SLPrefsManager.h"

@implementation SLAlarmPrefs

// custom initialization that creates a new alarm prefs object with the given alarm Id
// and default preferences
- (instancetype)initWithAlarmId:(NSString *)alarmId
{
    self = [super init];
    if (self) {
        self.alarmId = alarmId;
        self.snoozeTimeHour = kSLDefaultSnoozeHour;
        self.snoozeTimeMinute = kSLDefaultSnoozeMinute;
        self.snoozeTimeSecond = kSLDefaultSnoozeSecond;
        self.skipEnabled = kSLDefaultSkipEnabled;
        self.skipTimeHour = kSLDefaultSkipHour;
        self.skipTimeMinute = kSLDefaultSkipMinute;
        self.skipTimeSecond = kSLDefaultSkipSecond;
        self.skipActivationStatus = kSLDefaultSkipActivatedStatus;
        self.customSkipDates = [[NSArray alloc] init];
        [self populateDefaultHolidaySkipDates];
    }
    return self;
}

// invoked in the case that holiday skip dates were not set in the preferences for this alarm
- (void)populateDefaultHolidaySkipDates
{
    // populate all of the countries
    NSMutableDictionary *holidaySkipDates = [[NSMutableDictionary alloc] initWithCapacity:kSLHolidayCountryNumCountries];
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        // get the holidays that correspond to the country's particular resource
        NSString *resourceName = [SLPrefsManager resourceNameForCountry:holidayCountry];
        NSArray *holidays = [SLPrefsManager defaultHolidaysForResourceName:resourceName];
        if (holidays != nil) {
            [holidaySkipDates setObject:holidays forKey:resourceName];
        }
    }
    self.holidaySkipDates = [holidaySkipDates copy];
}

// returns the total number of selected holidays to be skipped for the given alarm
- (NSInteger)totalSelectedHolidays
{
    NSInteger total = 0;
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        NSArray *holidays = [self.holidaySkipDates objectForKey:[SLPrefsManager resourceNameForCountry:holidayCountry]];
        for (NSDictionary *holiday in holidays) {
            if ([[holiday objectForKey:kSLHolidaySelectedKey] boolValue]) {
                ++total;
            }
        }
    }
    return total;
}

@end
