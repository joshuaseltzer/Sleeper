//
//  SLSkipTimeViewController.m
//  Customized picker table view controller for selecting the skip time.
//
//  Created by Joshua Seltzer on 7/19/15.
//  Copyright (c) 2015 Joshua Seltzer. All rights reserved.
//

#import "SLSkipTimeViewController.h"
#import "SLLocalizedStrings.h"

@implementation SLSkipTimeViewController

// override to customize the view upon load
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title of the view controller
    self.title = kSLSkipTimeString;
    self.optionsTableView.scrollEnabled = NO;
}

#pragma mark - UITableViewDataSource

// returns the number of sections for a table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // return a single section so that we can display a footer message in the table
    return 1;
}

// returns the number of rows for a table view
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // there are no rows for this table
    return 0;
}

// returns a cell for a table at an index path
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Since we are not creating any cells, this function will never get called.  Therefore we are
    // safe returning nil here.
    return nil;
}

// return a footer view for each table view section
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return kSLSkipExplanationString;
}

#pragma mark - UITableViewDelegate

// return to include some space between the time picker view and the message we will display in the
// footer
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 5.0f;
}

@end
