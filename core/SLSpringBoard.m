//
//  SLSpringBoard.x
//  Hooks into the SpringBoard application to run our singleton process that will potentially monitor changes to timers.
//
//  Created by Joshua Seltzer on 7/2/2020.
//
//

#import "../common/SLCompatibilityHelper.h"
#import "../common/SLAutoSetManager.h"

void SLAutoSetOptionsUpdated()
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
	});
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	%orig;

    // create the auto-set manager instance to potentially monitor changes
    [SLAutoSetManager sharedInstance];
}

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS12 || kSLSystemVersioniOS13) {
        %init();

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)SLAutoSetOptionsUpdated, CFSTR("com.joshuaseltzer.sleeper/AutoSetOptionsUpdated"), NULL, kNilOptions);
    }
}