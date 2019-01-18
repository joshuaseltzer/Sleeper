//
//  SLAlarmPrefs.h
//  Object which includes Sleeper preferences for a specific alarm.
//
//  Created by Joshua Seltzer on 2/21/17.
//
//

#import <Foundation/Foundation.h>

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

// invoked in the case that holiday skip dates were not set in the preferences for this alarm
- (void)populateDefaultHolidaySkipDates;

// returns the total number of selected holidays to be skipped for the given alarm
- (NSInteger)totalSelectedHolidays;

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

// a dictionary containing additional dictionaries that correspond to the available holidays per country
@property (nonatomic, strong) NSDictionary *holidaySkipDates;

@end
