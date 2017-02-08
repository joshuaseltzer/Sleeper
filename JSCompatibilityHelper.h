//
//  JSCompatibilityHelper.h
//  Functions that are used to maintain system compatibility between different iOS versions
//
//  Created by Joshua Seltzer on 10/14/15.
//
//

#import "AppleInterfaces.h"

// interface for version compatibility functions throughout the application
@interface JSCompatibilityHelper : NSObject

// returns a valid alarm Id for a given alarm
+ (NSString *)alarmIdForAlarm:(Alarm *)alarm;

// returns the picker view's background color, which will depend on the iOS version
+ (UIColor *)pickerViewBackgroundColor;

// returns the color of the labels in the picker view
+ (UIColor *)pickerViewLabelColor;

@end