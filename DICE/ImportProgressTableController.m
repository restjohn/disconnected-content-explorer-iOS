//
//  ImportProgressViewController.m
//  DICE
//
//  Created by Robert St. John on 2/18/15.
//  Copyright (c) 2015 mil.nga. All rights reserved.
//

#import "ImportProgressTableController.h"

#import "ReportAPI.h"

@interface ImportProgressTableController ()

@end

@implementation ImportProgressTableController
{
    NSMutableArray *pendingReports;
}

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.tableView = tableView;
    tableView.delegate = self;
    tableView.dataSource = self;
    
    pendingReports = [self findPendingReports];
    
    NSNotificationCenter *notifications = [NSNotificationCenter defaultCenter];
    
    [notifications addObserver:self selector:@selector(reportImportBegan:) name:[ReportNotification reportImportBegan] object:nil];
    [notifications addObserver:self selector:@selector(reportImportProgress:) name:[ReportNotification reportImportProgress] object:nil];
    [notifications addObserver:self selector:@selector(reportImportFinished:) name:[ReportNotification reportImportFinished] object:nil];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pendingReports removeAllObjects];
    pendingReports = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reportImportBegan:(NSNotification *)notification
{
    Report *report = notification.userInfo[@"report"];
    [pendingReports insertObject:report atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
}

- (void)reportImportProgress:(NSNotification *)notification
{
    Report *report = notification.userInfo[@"report"];
    if (![pendingReports containsObject:report]) {
        [self reportImportBegan:notification];
    }
    else {
        NSUInteger reportIndex = [pendingReports indexOfObject:report];
        UITableViewCell *reportCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:reportIndex inSection:0]];
        [self updateValuesForReportCell:reportCell fromReport:report];
    }
}

- (UITableViewCell *)updateValuesForReportCell:(UITableViewCell *)reportCell fromReport:(Report *)report
{
    reportCell.textLabel.text = report.title;
    reportCell.detailTextLabel.text = [NSString stringWithFormat:@"%lu/%lu files extacted", report.progress, report.totalNumberOfFiles];
    return reportCell;
}

- (void)reportImportFinished:(NSNotification *)notification
{
    dispatch_time_t showReportUntil = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC);
    dispatch_after(showReportUntil, dispatch_get_main_queue(), ^{
        Report *report = notification.userInfo[@"report"];
        [pendingReports removeObject:report];
        [self.tableView reloadData];
    });
}

- (NSMutableArray *)findPendingReports
{
    NSMutableArray *reports = [[[ReportAPI sharedInstance] getReports] mutableCopy];
    [reports filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Report *report, NSDictionary *bindings) {
        return !report.isEnabled && report.totalNumberOfFiles > 0;
    }]];
    return reports;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return pendingReports.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pendingReportCell" forIndexPath:indexPath];
    Report *report = pendingReports[indexPath.row];
    return [self updateValuesForReportCell:cell fromReport:report];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
