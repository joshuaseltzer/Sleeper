//
//  SLMTAlarm.x
//  The alarm object used for iOS 12+.
//
//  Created by Joshua Seltzer on 7/30/2020.
//
//

#import "../common/SLCompatibilityHelper.h"
#import "../common/SLPrefsManager.h"

%hook MTAlarm

// flag which indicates whether or not the alarm was updated by this tweak or not
%property (nonatomic, assign) BOOL SLWasUpdatedBySleeper;

%end

%ctor {
    // only initialize this file for particular versions
    if (kSLSystemVersioniOS14 || kSLSystemVersioniOS13 || kSLSystemVersioniOS12) {
        %init();
    }
}