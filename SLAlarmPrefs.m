//
//  SLAlarmPrefs.m
//  Object which includes Sleeper preferences for a specific alarm.
//
//  Created by Joshua Seltzer on 2/21/17.
//
//

#import "SLAlarmPrefs.h"
#import "SLPrefsManager.h"
#import "SLLocalizedStrings.h"

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

// updates all dates (custom and holidays) by potentially updating the dates and removing any past dates
- (void)updateSkipDates
{
    // remove any passed dates from the holidays
    NSMutableDictionary *holidaySkipDates = [[NSMutableDictionary alloc] initWithDictionary:self.holidaySkipDates];
    BOOL holidaysUpdated = NO;
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        // get the holidays that correspond to the country's particular resource
        NSString *resourceName = [SLPrefsManager resourceNameForCountry:holidayCountry];

        // check first to see if the 
        NSMutableArray *holidays = [holidaySkipDates objectForKey:resourceName];
        if (holidays) {
            // remove any dates that might have already passed
            BOOL datesUpdated = NO;
            for (NSMutableDictionary *holiday in holidays) {
                NSArray *dates = [holiday objectForKey:kSLHolidayDatesKey];
                NSArray *newDates = [SLPrefsManager removePassedDatesFromArray:dates];
                if (dates.count != newDates.count) {
                    [holiday setObject:newDates forKey:kSLHolidayDatesKey];
                    datesUpdated = YES;
                }
            }
            if (datesUpdated) {
                [holidaySkipDates setObject:[holidays copy] forKey:resourceName];
            }
        }
    }
    if (holidaysUpdated) {
        self.holidaySkipDates = holidaySkipDates;
    }

    // remove any passed dates from the custom skip dates
    NSArray *newCustomSkipDates = [SLPrefsManager removePassedDatesFromArray:self.customSkipDates];
    if (self.customSkipDates.count != newCustomSkipDates.count) {
        self.customSkipDates = newCustomSkipDates;
    }
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
        if (holidays) {
            [holidaySkipDates setObject:[holidays copy] forKey:resourceName];
        }
    }
    self.holidaySkipDates = [holidaySkipDates copy];
}

// returns the total number of selected holidays to be skipped for the given alarm
- (NSInteger)totalSelectedHolidays
{
    NSInteger total = 0;
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        total = total + [self selectedHolidaysForCountry:holidayCountry];
    }
    return total;
}

// returns the number of selected holidays for the given holiday country
- (NSInteger)selectedHolidaysForCountry:(SLHolidayCountry)holidayCountry
{
    NSInteger selectedHolidays = 0;
    NSArray *holidays = [self.holidaySkipDates objectForKey:[SLPrefsManager resourceNameForCountry:holidayCountry]];
    if (holidays) {
        for (NSDictionary *holiday in holidays) {
            if ([[holiday objectForKey:kSLHolidaySelectedKey] boolValue]) {
                ++selectedHolidays;
            }
        }
    }
    return selectedHolidays;
}

// returns a customized string that indicates the number of selected skip dates and/or holidays
- (NSString *)selectedDatesString
{
    // customize the detail text label depending on whether or not we have skip dates enabled
    NSString *selectedDatesString = nil;
    NSString *holidayString = nil;
    NSInteger totalSelectedHolidays = [self totalSelectedHolidays];
    
    // make the holiday string singular or plural based on the count
    if (totalSelectedHolidays == 1) {
        holidayString = kSLHolidayString;
    } else {
        holidayString = kSLHolidaysString;
    }

    // depending on what was selected for this alarm, customize the string to return
    if (self.customSkipDates.count > 0 && totalSelectedHolidays > 0) {
        selectedDatesString = [NSString stringWithFormat:@"%ld (%ld %@)", (long)self.customSkipDates.count,
                                                                          (long)totalSelectedHolidays,
                                                                          holidayString];
    } else if (self.customSkipDates.count > 0) {
        selectedDatesString = [NSString stringWithFormat:@"%ld", (long)self.customSkipDates.count];
    } else if (totalSelectedHolidays > 0) {
        selectedDatesString = [NSString stringWithFormat:@"%ld %@", (long)totalSelectedHolidays, holidayString];
    } else {
        selectedDatesString = kSLNoneString;
    }

    return selectedDatesString;
}

// returns an array of unsorted dates for all of the selected holidays
- (NSArray *)allHolidaySkipDates
{
    NSMutableArray *holidaySkipDates = [[NSMutableArray alloc] init];
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        NSArray *holidays = [self.holidaySkipDates objectForKey:[SLPrefsManager resourceNameForCountry:holidayCountry]];
        for (NSDictionary *holiday in holidays) {
            if ([[holiday objectForKey:kSLHolidaySelectedKey] boolValue]) {
                [holidaySkipDates addObjectsFromArray:[holiday objectForKey:kSLHolidayDatesKey]];
            }
        }
    }
    return [holidaySkipDates copy];
}

// determines whether or not this alarm should be skipped based on the selected skip dates
// and the skip activated status
- (BOOL)shouldSkip
{
    // check to see one of today's dates is included in the skip dates for this alarm
    BOOL shouldSkip = NO;
    
    // first check to see if the skip switch is activated
    if (self.skipEnabled) {
        // check to see if the skip activated status is enabled for this alarm
        if (self.skipActivationStatus == kSLSkipActivatedStatusActivated) {
            shouldSkip = YES;
        } else {
            // check to see if one of the skip dates for this alarm is today
            NSArray *skipDates = [self sortedSkipDates];
            for (NSDate *skipDate in skipDates) {
                if ([[NSCalendar currentCalendar] isDateInToday:skipDate]) {
                    shouldSkip = YES;
                    break;
                }
            }
        }
    }

    return shouldSkip;
}

// gets a sorted list of skip dates for this alarm
- (NSArray *)sortedSkipDates
{
    NSArray *allHolidaySkipDates = [self allHolidaySkipDates];
    
    // get all of the skip dates for that alarm into a single array
    NSMutableArray *sortedSkipDates = [[NSMutableArray alloc] initWithCapacity:self.customSkipDates.count + allHolidaySkipDates.count];
    [sortedSkipDates addObjectsFromArray:self.customSkipDates];
    [sortedSkipDates addObjectsFromArray:allHolidaySkipDates];

    // sort the skip dates
    [sortedSkipDates sortUsingSelector:@selector(compare:)];
    
    return [sortedSkipDates copy];
}

@end
