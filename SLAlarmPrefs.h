//
//  SLAlarmPrefs.h
//  Object which includes Sleeper preferences for a specific alarm.
//
//  Created by Joshua Seltzer on 2/21/17.
//
//

#import <Foundation/Foundation.h>

// enum that defines the rows countries that are available to choose from for the holiday selection
typedef enum SLHolidayCountry : NSInteger {
    kSLHolidayCountryArgentina,
    kSLHolidayCountryAustralia,
    kSLHolidayCountryBelgium,
    kSLHolidayCountryBrazil,
    kSLHolidayCountryCanada,
    kSLHolidayCountryCzechia,
    kSLHolidayCountryDenmark,
    kSLHolidayCountryFrance,
    kSLHolidayCountryGermany,
    kSLHolidayCountrySweden,
    kSLHolidayCountryUnitedKingdom,
    kSLHolidayCountryUnitedStates,
    kSLHolidayCountryNumCountries
} SLHolidayCountry;

// enum to define the different options that can be returned for the alarm's skip activation
typedef enum SLPrefsSkipActivatedStatus : NSInteger {
    kSLSkipActivatedStatusUnknown,
    kSLSkipActivatedStatusActivated,
    kSLSkipActivatedStatusDisabled
} SLPrefsSkipActivatedStatus;

// constants that define the default values
static NSInteger const kSLDefaultSnoozeHour =           0;
static NSInteger const kSLDefaultSnoozeMinute =         9;
static NSInteger const kSLDefaultSnoozeSecond =         0;
static BOOL const kSLDefaultSkipEnabled =               NO;
static NSInteger const kSLDefaultSkipHour =             0;
static NSInteger const kSLDefaultSkipMinute =           30;
static NSInteger const kSLDefaultSkipSecond =           0;
static NSInteger const kSLDefaultSkipActivatedStatus =  kSLSkipActivatedStatusUnknown;

// Sleeper preferences specific to an alarm
@interface SLAlarmPrefs : NSObject

// custom initialization that creates a new alarm prefs object with the given alarm Id
// and default preferences
- (instancetype)initWithAlarmId:(NSString *)alarmId;

// updates all custom skip dates by potentially removing any past dates
- (void)updateCustomSkipDates;

// returns the total number of selected holidays to be skipped for the given alarm
- (NSInteger)totalSelectedHolidays;

// returns a customized string that indicates the total number of selected skip dates and/or holidays
- (NSString *)totalSelectedDatesString;

// determines whether or not this alarm should be skipped based on the selected skip dates
// and the skip activated status
- (BOOL)shouldSkip;

// alarm Id associated with this preference object
@property (nonatomic, strong) NSString *alarmId;

// the snooze hour
@property (nonatomic) NSInteger snoozeTimeHour;

// the snooze minute
@property (nonatomic) NSInteger snoozeTimeMinute;

// the snooze second
@property (nonatomic) NSInteger snoozeTimeSecond;

// whether or not skip is enabled
@property (nonatomic) BOOL skipEnabled;

// the skip hour
@property (nonatomic) NSInteger skipTimeHour;

// the skip minute
@property (nonatomic) NSInteger skipTimeMinute;

// the skip second
@property (nonatomic) NSInteger skipTimeSecond;

// the skip activation status
@property (nonatomic) SLPrefsSkipActivatedStatus skipActivationStatus;

// an array of NSDate objects that represent the custom skip dates for this alarm
@property (nonatomic, strong) NSArray *customSkipDates;

// a dictionary containing additional dictionaries that correspond to the selected holidays per country
@property (nonatomic, strong) NSDictionary *holidaySkipDates;

@end
