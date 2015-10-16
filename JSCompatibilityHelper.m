//
//  JSCompatibilityHelper.m
//  Functions that are used to maintain system compatibility between different iOS versions
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

#import "JSCompatibilityHelper.h"

@implementation JSCompatibilityHelper

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm
{
    // the alarm Id we will return
    NSString *alarmId = nil;
    
    // check the version of iOS that the device is running to determine where to get the alarm Id
    if (SYSTEM_VERSION_IOS9) {
        alarmId = alarm.alarmID;
    } else {
        alarmId = alarm.alarmId;
    }
    
    return alarmId;
}

@end