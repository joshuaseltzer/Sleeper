//
//  JSCompatibilityHelper.h
//  Functions that are used to maintain system compatibility between different iOS versions
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

#import "AppleInterfaces.h"

// macro to determine which system software this device is running
#define SYSTEM_VERSION_IOS9     [[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0

// interface for version compatibility functions throughout the application
@interface JSCompatibilityHelper : NSObject

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm;

@end