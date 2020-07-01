//
//  SLSunManager.m
//  A singleton object that will be used to manage changes to the user's sunrise/sunset time.
//
//  Created by Joshua Seltzer on 6/27/20.
//  Copyright (c) 2020 Joshua Seltzer. All rights reserved.
//

#import "SLSunManager.h"
#import "SLPrefsManager.h"

@interface SLSunManager ()

// the sunset alarms that are saved in preferences file
@property (nonatomic, strong) NSArray *sunsetAlarms;

// the sunrise alarms that are saved in preferences file
@property (nonatomic, strong) NSArray *sunriseAlarms;

@end

@implementation SLSunManager

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

// starts monitoring for changes to the sunrise/sunset times (only if alarms are enabled)
- (void)startMonitoringForSunChangesIfNecessary
{
    NSLog(@"*** SELTZER *** START MONITORING");

    // grab the sunrise and sunset enabled alarms from the preferences
    NSDictionary *sunriseAndSunsetAlarms = [SLPrefsManager sunriseAndSunsetAlarms];
    self.sunriseAlarms = [sunriseAndSunsetAlarms objectForKey:kSLSunriseAlarmsKey];
    self.sunsetAlarms = [sunriseAndSunsetAlarms objectForKey:kSLSunsetAlarmsKey];

    // start observing for changes if any sunrise or sunset alarms exist
    if (self.sunriseAlarms.count > 0 && self.sunsetAlarms.count > 0) {
        
    }
}

// stops monitoring for changes to the sunrise/sunset times
- (void)stopMonitoringForSunChanges
{

}

@end
