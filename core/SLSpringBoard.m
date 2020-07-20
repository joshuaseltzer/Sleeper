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

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
        %init();
    }
}