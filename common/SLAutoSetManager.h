//
//  SLAutoSetManager.h
//  A singleton object that will be used to manage the auto-set feature.
//
//  Created by Joshua Seltzer on 6/27/20.
//  Copyright (c) 2020 Joshua Seltzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLAlarmPrefs.h"

// the notification key that will be fired when the auto-set options are updated for a specific alarm
static NSString *const kSLAutoSetOptionsUpdatedNotification = @"SLAutoSetOptionsUpdated";

// the location object that will be associated with a forecast model
@interface WFLocation : NSObject

// the time zone that is associated with the location
@property (nonatomic, copy) NSTimeZone *timeZone;

@end

// an object which contains information about the current forecast
@interface WAForecastModel : NSObject

// the sunrise and sunset times for this forecast
@property (nonatomic, retain) NSDate *sunrise;
@property (nonatomic, retain) NSDate *sunset;

// the location object associated with the forecast model
@property (nonatomic, retain) WFLocation *location;

@end

// preferences object that will be used to request the model
@interface WeatherPreferences : NSObject

// the shared preferences that will be utilized to get updates from the today model
+ (id)sharedPreferences;

@end

// the today model which will be used to provide us with the sunrise/sunset times
@interface WATodayModel : NSObject

// returns a WATodayAutoupdatingLocationModel instance that can be used to monitor changes to the today model
+ (id)autoupdatingLocationModelWithPreferences:(WeatherPreferences *)weatherPreferences
                     effectiveBundleIdentifier:(NSString *)bundleIdentifier;

// the forecast model that is associated with this today model
@property (nonatomic, retain) WAForecastModel *forecastModel;

@end

// manager that will be used to automatically update alarms based on the user preferences
@interface SLAutoSetManager : NSObject

// return a singleton instance of this manager
+ (instancetype)sharedInstance;

// routine to update to a single alarm object that has updated auto-set settings
- (void)updateAutoSetAlarm:(NSDictionary *)alarmDict;

@end
