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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        alarmId = alarm.alarmID;
    } else {
        alarmId = alarm.alarmId;
    }
    
    return alarmId;
}

// returns the picker view's background color, which will depend on the iOS version
+ (UIColor *)pickerViewBackgroundColor
{
    // the color to return
    UIColor *color = nil;

    // check the version of iOS that the device is running to determine which color to pick
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        color = [UIColor blackColor];
    } else {
        color = [UIColor whiteColor];
    }
    
    return color;
}

// returns the color of the labels in the picker view
+ (UIColor *)pickerViewLabelColor
{
    // the color to return
    UIColor *color = nil;

    // check the version of iOS that the device is running to determine which color to pick
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        color = [UIColor whiteColor];
    } else {
        color = [UIColor blackColor];
    }
    
    return color;
}

// returns the cell selection background color for the picker tables
+ (UIColor *)pickerViewCellBackgroundColor
{
    // the color to return
    UIColor *color = nil;

    // check the version of iOS that the device is running to determine which color to pick
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        color = [UIColor whiteColor];
    } else {
        color = [UIColor blackColor];
    }
    
    return color;
}

@end