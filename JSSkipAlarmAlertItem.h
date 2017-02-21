//
//  JSSkipAlarmAlertItem.h
//  Custom system alert item to ask the user if he or she would like to skip a given alarm.
//
//  Created by Joshua Seltzer on 8/9/15.
//
//

#import "AppleInterfaces.h"

// system alert for skipping alarms
@interface JSSkipAlarmAlertItem : SBAlertItem

// create a new alert item with a given alarm and fire date
- (id)initWithAlarm:(Alarm *)alarm nextFireDate:(NSDate *)nextFireDate;

@end