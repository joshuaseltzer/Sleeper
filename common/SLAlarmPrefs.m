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
        self.sunOption = kSLDefaultSunOption;
        self.customSkipDates = [[NSArray alloc] init];
        self.holidaySkipDates = [[NSDictionary alloc] init];
    }
    return self;
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
    NSString *datesString = nil;
    NSString *holidaysString = nil;

    // make the skip date string singular or plural based on the count
    if (self.customSkipDates.count == 1) {
        datesString = kSLNumDateString((long)self.customSkipDates.count);
    } else {
        datesString = kSLNumDatesString((long)self.customSkipDates.count);
    }
    
    // make the holiday string singular or plural based on the count
    NSInteger totalSelectedHolidays = [self totalSelectedHolidays];
    if (totalSelectedHolidays == 1) {
        holidaysString = kSLNumHolidayString((long)totalSelectedHolidays);
    } else {
        holidaysString = kSLNumHolidaysString((long)totalSelectedHolidays);
    }

    // depending on what was selected for this alarm, customize the string to return
    if (self.customSkipDates.count == 0 && totalSelectedHolidays == 0) {
        return kSLNoneString;
    } else {
        return [NSString stringWithFormat:@"%@, %@", datesString, holidaysString];
    }
}

// determines whether or not this alarm should be skipped
- (BOOL)shouldSkipToday
{
    NSDate *today = [NSDate date];
    return self.skipEnabled && ([self shouldSkipFromPopupDecision] || [self shouldSkipFromSelectedDatesOnDate:today] || [self shouldSkipFromSelectedHolidaysOnDate:today]);
}

// determines whether or not the alarm should be skipped on a given date
- (BOOL)shouldSkipOnDate:(NSDate *)date
{
    return self.skipEnabled && ([self shouldSkipFromPopupDecision] || [self shouldSkipFromSelectedDatesOnDate:date] || [self shouldSkipFromSelectedHolidaysOnDate:date]);
}

// determines whether or not the alarm should be skipped from activating the popup
- (BOOL)shouldSkipFromPopupDecision
{
    return self.skipActivationStatus == kSLSkipActivatedStatusActivated;
}

// determines whether or not the alarm will be skipped from a custom skip date in a particular date
- (BOOL)shouldSkipFromSelectedDatesOnDate:(NSDate *)date
{
    for (NSString *skipDateString in self.customSkipDates) {
        NSDate *skipDate = [[SLPrefsManager plistDateFormatter] dateFromString:skipDateString];
        if ([[NSCalendar currentCalendar] isDate:skipDate inSameDayAsDate:date]) {
            return YES;
        }
    }
    return NO;
}

// determines whether or not the first selected holiday name falls on a particular date
- (BOOL)shouldSkipFromSelectedHolidaysOnDate:(NSDate *)date
{
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        // check to see if any holidays are selected for the given holiday country
        NSArray *selectedHolidayNames = [self.holidaySkipDates objectForKey:[SLPrefsManager resourceNameForHolidayCountry:holidayCountry]];
        if (selectedHolidayNames != nil) {
            for (NSString *holidayName in selectedHolidayNames) {
                NSDate *firstHolidayDate = [SLPrefsManager firstSkipDateForHolidayName:holidayName inHolidayCountry:holidayCountry];
                if (firstHolidayDate != nil && [[NSCalendar currentCalendar] isDate:firstHolidayDate inSameDayAsDate:date]) {
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
    // declare the skip explanation strings that will potentially be concatinated and displayed
    NSMutableString *skipExplanation = nil;

    // if the skip decision has been activated, add that to the string
    if ([self shouldSkipFromPopupDecision]) {
        skipExplanation = [NSMutableString stringWithString:kSLSkipReasonPopupString];
    }

    // check to see if there are any custom skip dates to display
    if (self.customSkipDates != nil && self.customSkipDates.count > 0) {
        // append or create the skip explanation string
        NSDate *skipDate = [[SLPrefsManager plistDateFormatter] dateFromString:[self.customSkipDates objectAtIndex:0]];
        NSString *skipExplanationDateString = kSLSkipReasonDateString([SLPrefsManager skipDateStringForDate:skipDate showRelativeString:YES]);
        if (skipExplanation != nil) {
            [skipExplanation appendString:@"\n\n"];
            [skipExplanation appendString:skipExplanationDateString];
        } else {
            skipExplanation = [NSMutableString stringWithString:skipExplanationDateString];
        }
    }
    
    // grab the first available selected holiday date and name
    NSString *firstSelectedHolidayName = nil;
    NSDate *firstSelectedHolidayDate = nil;
    for (SLHolidayCountry holidayCountry = 0; holidayCountry < kSLHolidayCountryNumCountries; holidayCountry++) {
        // check to see if any holidays are selected for the given holiday country
        NSArray *selectedHolidayNames = [self.holidaySkipDates objectForKey:[SLPrefsManager resourceNameForHolidayCountry:holidayCountry]];
        if (selectedHolidayNames != nil) {
            for (NSString *holidayName in selectedHolidayNames) {
                NSDate *firstHolidayDate = [SLPrefsManager firstSkipDateForHolidayName:holidayName inHolidayCountry:holidayCountry];
                if (firstHolidayDate != nil && (firstSelectedHolidayDate == nil || [firstHolidayDate compare:firstSelectedHolidayDate] == NSOrderedAscending)) {
                    firstSelectedHolidayDate = firstHolidayDate;
                    firstSelectedHolidayName = holidayName;
                }
            }
        }
    }

    // if there was a holiday country, display it
    if (firstSelectedHolidayDate != nil) {
        // append or create the skip explanation string
        NSString *skipExplanationHolidayString = kSLSkipReasonHolidayString([SLPrefsManager skipDateStringForDate:firstSelectedHolidayDate showRelativeString:YES], firstSelectedHolidayName);
        if (skipExplanation != nil) {
            [skipExplanation appendString:@"\n\n"];
            [skipExplanation appendString:skipExplanationHolidayString];
        } else {
            skipExplanation = [NSMutableString stringWithString:skipExplanationHolidayString];
        }
    }

    return [skipExplanation copy];
}

@end
