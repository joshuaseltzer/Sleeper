//
//  SLSunManager.h
//  A singleton object that will be used to manage changes to the user's sunrise/sunset time.
//
//  Created by Joshua Seltzer on 6/27/20.
//  Copyright (c) 2020 Joshua Seltzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLAlarmPrefs.h"

// manager that will be used to monitor changes to the sunrise/sunset changes
@interface SLSunManager : NSObject

// return a singleton instance of this manager
+ (instancetype)sharedInstance;

// starts monitoring for changes to the sunrise/sunset times (only if alarms are enabled)
- (void)startMonitoringForSunChangesIfNecessary;

// stops monitoring for changes to the sunrise/sunset times
- (void)stopMonitoringForSunChanges;

@end
