//
//  SLAutoSetManager.m
//  A singleton object that will be used to manage the auto-set feature.
//
//  Created by Joshua Seltzer on 6/27/20.
//  Copyright (c) 2020 Joshua Seltzer. All rights reserved.
//

#import "SLAutoSetManager.h"
#import "SLPrefsManager.h"

@interface SLAutoSetManager ()

@end

@implementation SLAutoSetManager

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

    // start observing for changes if any sunrise or sunset alarms exist
    /*if () {
        
    }*/
}

// stops monitoring for changes to the sunrise/sunset times
- (void)stopMonitoringForSunChanges
{

}

@end
