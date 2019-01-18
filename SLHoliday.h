//
//  SLHoliday.h
//  sleeper-test
//
//  Created by Joshua Seltzer on 1/14/19.
//  Copyright © 2019 Joshua Seltzer. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLHoliday : NSObject

// initialize a holiday object with the given parameters
- (instancetype)initWithLZNameKey:(NSString *)localizedNameKey dates:(NSArray *)dates;

// the localized name key for this holiday
@property (nonatomic, strong) NSString *localizedNameKey;

// the dates that correspond to this holiday
@property (nonatomic, strong) NSArray *dates;

// whether or not this holiday has been selected
@property (nonatomic) BOOL selected;

@end

NS_ASSUME_NONNULL_END
