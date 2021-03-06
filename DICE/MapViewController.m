//
//  MapViewController.m
//  InteractiveReports
//

#import "MapViewController.h"

#define METERS_PER_MILE = 1609.344

@interface MapViewController ()

@property (weak, nonatomic) IBOutlet UIView *noLocationsView;

@end

@implementation MapViewController {
    BOOL polygonsAdded;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.noLocationsView.layer.cornerRadius = 10.0;
    self.mapView.delegate = self;
    polygonsAdded = NO;
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

@end
