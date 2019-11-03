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

// custom initialization that creates a new alarm prefs object with the given alarm Id and default preferences
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
        self.holidaySkipDates = [[NSDictionary alloc] init];
    }
    return self;
}

// updates all custom skip dates by potentially removing any past dates
- (void)updateCustomSkipDates
{
    // remove any passed dates from the custom skip dates
    NSArray *newCustomSkipDates = [SLPrefsManager removePassedDatesFromArray:self.customSkipDates];
    if (self.customSkipDates.count != newCustomSkipDates.count) {
        self.customSkipDates = newCustomSkipDates;
    }
}

// returns the total number of selected holidays to be skipped for the given alarm
- (NSInteger)totalSelectedHolidays
{
    NSInteger total = 0;
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        total = total + [self selectedHolidaysForHolidayCountry:holidayCountry];
    }
    return total;
}

// returns the number of selected holidays for the given holiday country
- (NSInteger)selectedHolidaysForHolidayCountry:(SLHolidayCountry)holidayCountry
{
    NSInteger selectedHolidays = 0;
    NSArray *selectedHolidayNames = [self.holidaySkipDates objectForKey:[SLPrefsManager resourceNameForHolidayCountry:holidayCountry]];
    if (selectedHolidayNames != nil) {
        selectedHolidays = selectedHolidayNames.count;
    }
    return selectedHolidays;
}

// returns a customized string that indicates the total number of selected skip dates and/or holidays
- (NSString *)totalSelectedDatesString
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

// determines whether or not this alarm should be skipped
- (BOOL)shouldSkip
{
    return self.skipEnabled && ([self shouldSkipFromPopup] || [self shouldSkipFromDate] || [self shouldSkipFromHoliday]);
}

// determines whether or not the alarm should be skipped from activating the popup
- (BOOL)shouldSkipFromPopup
{
    return self.skipActivationStatus == kSLSkipActivatedStatusActivated;
}

// determines whether or not the alarm will be skipped from a custom skip date
- (BOOL)shouldSkipFromDate
{
    for (NSDate *skipDate in self.customSkipDates) {
        if ([[NSCalendar currentCalendar] isDateInToday:skipDate]) {
            return YES;
        }
    }
    return NO;
}

// determines whether or not the alarm will be skipped from a holiday selection
- (BOOL)shouldSkipFromHoliday
{
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        // check to see if any holidays are selected for the given holiday country
        NSArray *selectedHolidayNames = [self.holidaySkipDates objectForKey:[SLPrefsManager resourceNameForHolidayCountry:holidayCountry]];
        if (selectedHolidayNames != nil) {
            for (NSString *holidayName in selectedHolidayNames) {
                NSDate *firstHolidayDate = [SLPrefsManager firstSkipDateForHolidayName:holidayName inHolidayCountry:holidayCountry];
                if (firstHolidayDate != nil && [[NSCalendar currentCalendar] isDateInToday:firstHolidayDate]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

// returns an explanation of why a given alarm will be skipped
- (NSString *)skipReasonExplanation
{
    NSString *skipExplanation = nil;
    if (self.skipEnabled) {
        if ([self shouldSkipFromPopup]) {
            skipExplanation = kSLSkipReasonPopupString;
        } else if ([self shouldSkipFromDate]) {
            skipExplanation = kSLSkipReasonDateString;
        } else if ([self shouldSkipFromHoliday]) {
            skipExplanation = kSLSkipReasonHolidayString;
        }
    }
    return skipExplanation;
}

@end
