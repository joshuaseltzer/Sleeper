//
//  SLAutoSetManager.h
//  A singleton object that will be used to manage the auto-set feature.
//
//  Created by Joshua Seltzer on 6/27/20.
//  Copyright (c) 2020 Joshua Seltzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLAlarmPrefs.h"

// manager that will be used to automatically update alarms based on the user preferences
@interface SLAutoSetManager : NSObject

// return a singleton instance of this manager
+ (instancetype)sharedInstance;

// starts monitoring for changes to the sunrise/sunset times (only if alarms have this feature enabled)
- (void)startMonitoringForSunChangesIfNecessary;

// stops monitoring for changes to the sunrise/sunset times
- (void)stopMonitoringForSunChanges;

@end
