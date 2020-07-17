//
//  SLSpringBoard.x
//  Hooks into the SpringBoard application to run our singleton process that will potentially monitor changes to timers.
//
//  Created by Joshua Seltzer on 7/2/2020.
//
//

#import <Foundation/NSDistributedNotificationCenter.h>
#import "../common/SLCompatibilityHelper.h"
#import "../common/SLAutoSetManager.h"

%hook SpringBoard

// called whenever an auto-set alarm needs to be updated
%new
- (void)SLAutoSetOptionsUpdated:(NSNotification *)notification
{
    NSLog(@"SELTZER - Notification received!!");
    NSLog(@"SELTZER - userInfo: %@", [notification userInfo]);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // notify the auto-set manager that an alarm has updated auto-set options
		[[SLAutoSetManager sharedInstance] updateAutoSetAlarm:[notification userInfo]];
	});
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	%orig;

    // create the auto-set manager instance to potentially monitor changes to alarms
    [SLAutoSetManager sharedInstance];

    // observe changes from the auto-set manager to update alarms with updated auto-set options
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(SLAutoSetOptionsUpdated:) name:kSLAutoSetOptionsUpdatedNotification object:nil];
}

%end

%hook WATodayModel

+(id)autoupdatingLocationModelWithPreferences:(id)arg1 effectiveBundleIdentifier:(id)arg2
{
     NSLog(@"SELTZER - autoupdatingLocationModelWithPreferences");
    %log;

    return %orig;
}

-(void)_executeForecastRetrievalForLocation:(id)arg1 completion:(id)arg2
{
    NSLog(@"SELTZER - _executeForecastRetrievalForLocation");
    %log;

    %orig;
}

-(BOOL)executeModelUpdateWithCompletion:(id)arg1
{
    NSLog(@"SELTZER - executeModelUpdateWithCompletion");
    %log;

    return %orig;
}

-(void)_fireTodayModelWantsUpdate
{
    NSLog(@"SELTZER - _fireTodayModelWantsUpdate");
    %log;

    %orig;
}

%end

%hook WATodayAutoupdatingLocationModel

-(void)_executeLocationUpdateForLocalWeatherCityWithCompletion:(id)arg1
{
    NSLog(@"SELTZER - _executeLocationUpdateForLocalWeatherCityWithCompletion");
    %log;

    %orig;
}

-(void)_executeLocationUpdateForFirstWeatherCityWithCompletion:(id)arg1 
{
    NSLog(@"SELTZER - _executeLocationUpdateForFirstWeatherCityWithCompletion");
    %log;

    %orig;
}

-(void)_executeLocationUpdateWithCompletion:(id)arg1 
{
    NSLog(@"SELTZER - _executeLocationUpdateWithCompletion");
    %log;

    %orig;
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
        %init();
    }
}