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
    kSLHolidayCountryAruba,
    kSLHolidayCountryAustralia,
    kSLHolidayCountryAustria,
    kSLHolidayCountryBelarus,
    kSLHolidayCountryBelgium,
    kSLHolidayCountryBrazil,
    kSLHolidayCountryBulgaria,
    kSLHolidayCountryCanada,
    kSLHolidayCountryColombia,
    kSLHolidayCountryCroatia,
    kSLHolidayCountryCzechia,
    kSLHolidayCountryDenmark,
    kSLHolidayCountryDominicanRepublic,
    kSLHolidayCountryEgypt,
    kSLHolidayCountryEstonia,
    kSLHolidayCountryFinland,
    kSLHolidayCountryFrance,
    kSLHolidayCountryGermany,
    kSLHolidayCountryHungary,
    kSLHolidayCountryIceland,
    kSLHolidayCountryIndia,
    kSLHolidayCountryIreland,
    kSLHolidayCountryIsrael,
    kSLHolidayCountryItaly,
    kSLHolidayCountryJapan,
    kSLHolidayCountryKenya,
    kSLHolidayCountryKorea,
    kSLHolidayCountryLithuania,
    kSLHolidayCountryLuxembourg,
    kSLHolidayCountryMexico,
    kSLHolidayCountryMorocco,
    kSLHolidayCountryNetherlands,
    kSLHolidayCountryNewZealand,
    kSLHolidayCountryNicaragua,
    kSLHolidayCountryNigeria,
    kSLHolidayCountryNorway,
    kSLHolidayCountryParaguay,
    kSLHolidayCountryPeru,
    kSLHolidayCountryPoland,
    kSLHolidayCountryPortugal,
    kSLHolidayCountryRussia,
    kSLHolidayCountrySerbia,
    kSLHolidayCountrySingapore,
    kSLHolidayCountrySlovakia,
    kSLHolidayCountrySlovenia,
    kSLHolidayCountrySouthAfrica,
    kSLHolidayCountrySpain,
    kSLHolidayCountrySweden,
    kSLHolidayCountrySwitzerland,
    kSLHolidayCountryTurkey,
    kSLHolidayCountryUkraine,
    kSLHolidayCountryUnitedKingdom,
    kSLHolidayCountryUnitedStates,
    kSLHolidayCountryVietnam,
    kSLHolidayCountryNumCountries
} SLHolidayCountry;

// enum to define the different options that can be returned for the alarm's skip activation
typedef enum SLSkipActivatedStatus : NSInteger {
    kSLSkipActivatedStatusUnknown,
    kSLSkipActivatedStatusActivated,
    kSLSkipActivatedStatusDisabled
} SLSkipActivatedStatus;

// enum to define the options for whether or not an alarm has the auto-set option enabled
typedef enum SLAutoSetOption : NSInteger {
    kSLAutoSetOptionOff,
    kSLAutoSetOptionSunrise,
    kSLAutoSetOptionSunset
} SLAutoSetOption;

// enum to define the offset options for the auto-set feature when it is enabled
typedef enum SLAutoSetOffsetOption : NSInteger {
    kSLAutoSetOffsetOptionOff,
    kSLAutoSetOffsetOptionBefore,
    kSLAutoSetOffsetOptionAfter
} SLAutoSetOffsetOption;

// constants that define the default values
static NSInteger const kSLDefaultSnoozeHour =           0;
static NSInteger const kSLDefaultSnoozeMinute =         9;
static NSInteger const kSLDefaultSnoozeSecond =         0;
static BOOL const kSLDefaultSkipEnabled =               NO;
static NSInteger const kSLDefaultSkipHour =             0;
static NSInteger const kSLDefaultSkipMinute =           30;
static NSInteger const kSLDefaultSkipSecond =           0;
static NSInteger const kSLDefaultSkipActivatedStatus =  kSLSkipActivatedStatusUnknown;
static NSInteger const kSLDefaultAutoSetOption =        kSLAutoSetOptionOff;
static NSInteger const kSLDefaultAutoSetOffsetOption =  kSLAutoSetOffsetOptionOff;
static NSInteger const kSLDefaultAutoSetOffsetHour =    1;
static NSInteger const kSLDefaultAutoSetOffsetMinute =  0;

// Sleeper preferences specific to an alarm
@interface SLAlarmPrefs : NSObject

// custom initialization that creates a new alarm prefs object with the given alarm Id
// and default preferences
- (instancetype)initWithAlarmId:(NSString *)alarmId;

// returns the total number of selected holidays to be skipped for the given alarm
- (NSInteger)totalSelectedHolidays;

// returns a customized string that indicates the total number of selected skip dates and/or holidays
- (NSString *)totalSelectedDatesString;

// determines whether or not this alarm should be skipped today
- (BOOL)shouldSkipToday;

// determines whether or not the alarm should be skipped on a given date
- (BOOL)shouldSkipOnDate:(NSDate *)date;

// returns an explanation of why a given alarm will be skipped
- (NSString *)skipReasonExplanation;

// returns an explanation regarding the use of the auto-set option
- (NSString *)autoSetExplanation;

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
@property (nonatomic) SLSkipActivatedStatus skipActivationStatus;

// the auto-set option
@property (nonatomic) SLAutoSetOption autoSetOption;

// the auto-set offset option
@property (nonatomic) SLAutoSetOffsetOption autoSetOffsetOption;

// the auto-set offset hour
@property (nonatomic) NSInteger autoSetOffsetHour;

// the auto-set offset minute
@property (nonatomic) NSInteger autoSetOffsetMinute;

// an array of NSDate objects that represent the custom skip dates for this alarm
@property (nonatomic, strong) NSArray *customSkipDates;

// a dictionary containing additional dictionaries that correspond to the selected holidays per country
@property (nonatomic, strong) NSDictionary *holidaySkipDates;

@end
