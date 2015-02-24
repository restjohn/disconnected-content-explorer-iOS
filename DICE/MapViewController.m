//
//  MapViewController.m
//  InteractiveReports
//

#import "MapViewController.h"

#import "ImportProgressTableController.h"
#import "ReportAPI.h"

#define METERS_PER_MILE = 1609.344

@interface MapViewController ()

@property (weak, nonatomic) IBOutlet UIView *noLocationsView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *importIndicator;
@property (weak, nonatomic) IBOutlet UIView *importProgressView;
@property (weak, nonatomic) IBOutlet UITableView *importProgressTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *importProgressWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *importProgressHeight;

@property (strong, nonatomic) ImportProgressTableController *importProgressTable;

- (IBAction)importIndicatorTapped:(UITapGestureRecognizer *)sender;
- (IBAction)testImportBegin;
- (IBAction)testImportFinish;

@end

@implementation MapViewController
{
    BOOL polygonsAdded;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.noLocationsView.layer.cornerRadius = 10.0;
    self.mapView.delegate = self;
    polygonsAdded = NO;
    
    self.importProgressTable = [[ImportProgressTableController alloc] initWithTableView:self.importProgressTableView];
    [self.importProgressTable willMoveToParentViewController:self];
    [self addChildViewController:self.importProgressTable];
    self.importProgressView.layer.cornerRadius = self.importIndicator.bounds.size.width / 2;
//    self.importProgressView.hidden = YES;
//    self.importProgressWidth.constant = self.importIndicator.bounds.size.width;
//    self.importProgressHeight.constant = self.importIndicator.bounds.size.height;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!polygonsAdded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addOverlays:[OfflineMapUtility getPolygons]];
            polygonsAdded = YES;
        });
    }
    
    self.noLocationsView.hidden = NO;

    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 40.740848;
    zoomLocation.longitude= -73.991145;
    
    NSMutableArray *notUserLocations = [NSMutableArray arrayWithArray:self.mapView.annotations];
    [notUserLocations removeObject:self.mapView.userLocation];
    [self.mapView removeAnnotations:notUserLocations];

    for (Report * report in self.reports) {
        // TODO: this check needs to be a null check or hasLocation or something else better
        if (report.lat != 0.0f && report.lon != 0.0f) {
            ReportMapAnnotation *annotation = [[ReportMapAnnotation alloc] initWithReport:report];
            [self.mapView addAnnotation:(id)annotation];
            self.noLocationsView.hidden = YES;
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark Map view delegate methods
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation
{
    if([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *annotationIdentifier = @"ReportMapAnnotation";
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    
    if ([annotation isKindOfClass:[ReportMapAnnotation class]]) {
        ReportMapAnnotation *customAnnotation = annotation;
        
        if (!annotationView) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
            annotationView.canShowCallout = YES;
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        } else {
            annotationView.annotation = customAnnotation;
        }
        
        annotationView.image = [UIImage imageNamed:@"map-point"];
    }
    
    return annotationView;
}


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    MKPolygonView *polygonView = [[MKPolygonView alloc] initWithOverlay:overlay];
    
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        
        if ([overlay.title isEqualToString:@"ocean"]) {
            polygonView.fillColor = [UIColor colorWithRed:127/255.0 green:153/255.0 blue:151/255.0 alpha:1.0];
            polygonView.strokeColor = [UIColor clearColor];
            polygonView.lineWidth = 0.0;
            polygonView.opaque = TRUE;
        }
        else if ([overlay.title isEqualToString:@"feature"]) {
            polygonView.fillColor = [UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1.0];
            polygonView.strokeColor = [UIColor clearColor];
            polygonView.lineWidth = 0.0;
            polygonView.opaque = TRUE;
        }
        else {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *maptype = [defaults stringForKey:@"maptype"];
            if ([@"Offline" isEqual:maptype]) {
                polygonView.fillColor = [[UIColor whiteColor] colorWithAlphaComponent:1.0];
            }
            else {
                polygonView.fillColor = [[UIColor yellowColor] colorWithAlphaComponent:0.2];
            }
            polygonView.lineWidth = 2;
            polygonView.strokeColor = [UIColor orangeColor];
        }
        
		return polygonView;
	}
	return nil;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    _selectedReport = ((ReportMapAnnotation *)view.annotation).report;
    [self.delegate reportSelectedToView:_selectedReport];
}

- (IBAction)importIndicatorTapped:(UITapGestureRecognizer *)sender
{
    [self toggleImportProgressView];
}

- (IBAction)testImportBegin
{
    NSUInteger total = (NSUInteger)floor((drand48() * 25.0));
    NSString *id = [[NSUUID UUID] UUIDString];
    Report *report = [Report reportWithTitle:[NSString stringWithFormat:@"Test - %@", id]];
    report.reportID = id;
    report.totalNumberOfFiles = total;
    report.progress = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:[ReportNotification reportImportBegan] object:nil
             userInfo:@{@"report":report}];
        [self testImportAdvanceProgressForReport:report];
    });
}

- (IBAction)testImportFinish
{
}

- (void)testImportAdvanceProgressForReport:(Report *)report
{
    if (report.progress == report.totalNumberOfFiles) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:[ReportNotification reportImportFinished] object:nil
                userInfo:@{@"report":report}];
        });
        return;
    }

    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        report.progress++;
        [[NSNotificationCenter defaultCenter] postNotificationName:[ReportNotification reportImportProgress] object:nil
            userInfo:@{
                @"report":report,
                @"totalNumberOfFiles":[NSString stringWithFormat:@"%lu", report.totalNumberOfFiles],
                @"progress":[NSString stringWithFormat:@"%lu", report.progress]
            }];
        [self testImportAdvanceProgressForReport:report];
    });
}

- (void)toggleImportProgressView
{
    if (self.importProgressView.hidden) {
        [self showImportProgressView];
    }
    else {
        [self hideImportProgressView];
    }
}

- (void)showImportProgressView
{
    self.importProgressView.hidden = NO;
    self.importProgressWidth.constant = 320.0;
    self.importProgressHeight.constant = 92.0;
    [UIView animateWithDuration:0.25 animations:^{
        [self.importProgressView layoutIfNeeded];
    }];
}

- (void)hideImportProgressView
{
    self.importProgressWidth.constant = self.importIndicator.frame.size.width;
    self.importProgressHeight.constant = self.importIndicator.frame.size.height;
    [UIView animateWithDuration:0.25 animations:^{
            [self.importProgressView layoutIfNeeded];
        }
        completion:^(BOOL finished) {
            self.importProgressView.hidden = YES;
        }];
}

@end
