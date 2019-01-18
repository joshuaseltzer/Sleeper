//
//  SLHoliday.m
//  sleeper-test
//
//  Created by Joshua Seltzer on 1/14/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import "SLHoliday.h"

@implementation SLHoliday

// initialize a holiday object with the given parameters
- (instancetype)initWithLZNameKey:(NSString *)localizedNameKey dates:(NSArray *)dates
{
    self = [super init];
    if (self) {
        self.localizedNameKey = localizedNameKey;
        self.dates = dates;
        self.selected = NO;
    }
    return self;
}

@end
