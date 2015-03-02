//
//  ImportProgressViewController.m
//  DICE
//
//  Created by Robert St. John on 2/18/15.
//  Copyright (c) 2015 mil.nga. All rights reserved.
//

#import "ImportProgressTableController.h"

#import "ReportAPI.h"


@interface ImportProgressTableController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableHeight;

@end

@implementation ImportProgressTableController
{
    NSMutableArray *pendingReports;
    NSMutableArray *finishedReports;
}

- (void)viewDidLoad
{
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    pendingReports = [self findPendingReports];
    finishedReports = [NSMutableArray array];
    
    NSNotificationCenter *notifications = [NSNotificationCenter defaultCenter];
    
    [notifications addObserver:self selector:@selector(reportImportBegan:) name:[ReportNotification reportImportBegan] object:nil];
    [notifications addObserver:self selector:@selector(reportImportProgress:) name:[ReportNotification reportImportProgress] object:nil];
    [notifications addObserver:self selector:@selector(reportImportFinished:) name:[ReportNotification reportImportFinished] object:nil];
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
    [UIView animateWithDuration:0.25 animations:^{
            _tableHeight.constant += _tableView.rowHeight;
        } completion:^(BOOL finished) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        }];
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
    if (report.progress < report.totalNumberOfFiles) {
        reportCell.detailTextLabel.text = [NSString stringWithFormat:@"%lu/%lu files extracted", report.progress, report.totalNumberOfFiles];
    }
    else {
        reportCell.detailTextLabel.text = [NSString stringWithFormat:@"Complete: %lu files extracted", report.totalNumberOfFiles];
    }
    return reportCell;
}

- (void)reportImportFinished:(NSNotification *)notification
{
}

- (void)showFinishedReport
{
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"importProgressCell" forIndexPath:indexPath];
    Report *report = pendingReports[indexPath.row];
    return [self updateValuesForReportCell:cell fromReport:report];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
