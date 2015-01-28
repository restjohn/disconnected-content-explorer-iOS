//
//  WhirlyGlobeResourceViewController.m
//  InteractiveReports
//
//  Created by Robert St. John on 12/11/14.
//  Copyright (c) 2014 mil.nga. All rights reserved.
//

#import "WhirlyGlobeResourceViewController.h"

#import "KML.h"
#import "PointRecordParser.h"
#import <math.h>


#define EARTH_RADIUS 6371000.0f

CGFloat degToRad(CGFloat deg) {
    return deg / 180.0F * M_PI;
}

@interface WhirlyGlobePointRecordParserDelegate : NSObject <PointParserDelegate>

@property (weak, nonatomic) WhirlyGlobeResourceViewController *controller;

@end


@implementation WhirlyGlobePointRecordParserDelegate

NSMutableArray *pointCloud;
CGFloat minLon = CGFLOAT_MAX, minLat = CGFLOAT_MAX, maxLon = CGFLOAT_MAX, maxLat = CGFLOAT_MAX, maxHeight = CGFLOAT_MAX;

- (instancetype)initWithController:(WhirlyGlobeResourceViewController *)controller
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.controller = controller;
    pointCloud = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)pointAtX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z
{
    if (minLon == CGFLOAT_MAX) {
        minLon = maxLon = x;
        minLat = maxLat = y;
        maxHeight = z;
    }
    else {
        minLon = fminf(x, minLon);
        minLat = fminf(y, minLat);
        maxLon = fminf(x, maxLon);
        maxLat = fminf(y, maxLat);
        maxHeight = fmaxf(z, maxHeight);
    }
    
    // TODO: convert z to display units
    CGFloat zDisp = z / EARTH_RADIUS;
//    MaplyCoordinate3d coords[1] = { MaplyCoordinate3dMake(degToRad(x), degToRad(y), zDisp) };
    MaplyShapeSphere *shape = [[MaplyShapeSphere alloc] init];
    shape.center = MaplyCoordinateMakeWithDegrees(x, y);
    shape.height = zDisp;
    shape.radius = 0.0001;
//    shape.radius = 0.01;
//    MaplyShapeLinear *shape = [[MaplyShapeLinear alloc] initWithCoords:coords numCoords:1];
//    shape.lineWidth = 1.0;
    shape.color = [UIColor redColor];
    [pointCloud addObject:shape];
}

- (void)parserDidFinish
{
    maxHeight /= EARTH_RADIUS;
    MaplyCoordinate3d bboxCoords[4] = {
        MaplyCoordinate3dMake(degToRad(1.5 * minLon), degToRad(1.5 * minLat), maxHeight),
        MaplyCoordinate3dMake(degToRad(1.5 * minLon), degToRad(1.5 * maxLat), maxHeight),
        MaplyCoordinate3dMake(degToRad(1.5 * maxLon), degToRad(1.5 * maxLat), maxHeight),
        MaplyCoordinate3dMake(degToRad(1.5 * maxLon), degToRad(1.5 * minLat), maxHeight)
    };
    MaplyShapeLinear *bbox = [[MaplyShapeLinear alloc] initWithCoords:bboxCoords numCoords:5];
    bbox.color = [UIColor grayColor];
    bbox.lineWidth = 10;
    [pointCloud addObject:bbox];
    if ([pointCloud.firstObject isKindOfClass:[MaplyShapeSphere class]]) {
        ((MaplyShapeSphere *)pointCloud.firstObject).radius = 0.0001;
    }
    [_controller addShapes:pointCloud desc:nil];
}

- (void)parserDidEncounterError:(NSError *)error
{
    NSLog(@"error parsing points: %@", error);
}

@end


@implementation WhirlyGlobeResourceViewController {
    NSOperationQueue *downloadQueue;
    MaplyCoordinate cameraPosition;
}

- (void)handleResource:(NSURL *)resource forReport:(Report *)report
{
    NSString *resourceType = [ResourceTypes typeUtiOf:resource];
    if ([resourceType isEqualToString:@"mil.dod.nga.giat.points-csv"]) {
        [self handlePointCloudResource:resource];
    }
    else if ([resourceType isEqualToString:@"com.google.earth.kml"]) {
        [self handleKMLResource:resource];
    }
    
    MaplyCoordinate3d coords[2];
    coords[0] = MaplyCoordinate3dMake(degToRad(-100), degToRad(30), 0.01);
//    coords[1] = MaplyCoordinate3dMake([self degToRad:-105], [self degToRad:35], 0.01);
    MaplyShapeLinear *line = [[MaplyShapeLinear alloc] initWithCoords:coords numCoords:2];
    line.lineWidth = 1.0;
    line.color = [UIColor redColor];
    MaplyShapeSphere *sphere = [[MaplyShapeSphere alloc] init];
    sphere.center = MaplyCoordinateMakeWithDegrees(-105, 35);
    sphere.height = 0.0;
    sphere.radius = 0.01;
    sphere.color = [UIColor purpleColor];
    MaplyShapeCircle *cir = [[MaplyShapeCircle alloc] init];
    cir.center = MaplyCoordinateMakeWithDegrees(-102, 31);
    cir.radius = 0.01;
    cir.height = 100.0 / EARTH_RADIUS;
    cir.color = [UIColor blueColor];
    [self addShapes:@[line, sphere, cir] desc:nil];
}

- (void)handleKMLResource:(NSURL *)resource
{
    NSMutableArray *marks = [[NSMutableArray alloc] init];
    float minLat = 0.0, minLon = 0.0;
    KMLRoot *root = [KMLParser parseKMLAtURL:resource];
    for (KMLPlacemark *placemark in root.placemarks) {
        if ([placemark.geometry isKindOfClass:KMLPoint.class]) {
            KMLPoint *point = (KMLPoint *)placemark.geometry;
            const MaplyCoordinate3d location = MaplyCoordinate3dMake(degToRad(point.coordinate.longitude), degToRad(point.coordinate.latitude), 1.0);
            NSString *iconURLString = placemark.style.iconStyle.icon.href;
            if (iconURLString) {
                NSURL *iconURL = [NSURL URLWithString:iconURLString];
                NSURLRequest *getIcon = [NSURLRequest requestWithURL:iconURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
                // TODO: if we don't need to support iOS 6, we should use NSURLSession
                [NSURLConnection sendAsynchronousRequest:getIcon queue:downloadQueue
                                       completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                           UIImage *icon = [UIImage imageWithData:data];
                                           [marks addObject:[self makeMarkerAt:location withIcon:icon]];
                                       }];
            }
            else {
                UIImage *icon = [UIImage imageNamed:@"map-point"];
                [marks addObject:[self makeMarkerAt:location withIcon:icon]];
            }
        }
    }
    [self addMarkers:marks desc:nil mode:MaplyThreadAny];
}

- (void)handlePointCloudResource:(NSURL *)resource
{
    WhirlyGlobePointRecordParserDelegate *parserDelegate = [[WhirlyGlobePointRecordParserDelegate alloc] initWithController:self];
    PointRecordParser *parser = [[PointRecordParser alloc] initWithSource:resource delegate:parserDelegate];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [parser parsePoints];
    });
}

- (MaplyScreenMarker *)makeMarkerAt:(MaplyCoordinate3d)location withIcon:(UIImage *)icon
{
    MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
    marker.image = icon;
    marker.loc = MaplyCoordinateMakeWithDegrees(location.x, location.y);
    return marker;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    downloadQueue = [[NSOperationQueue alloc] init];

    // we want a black background for a globe, a white background for a map.
    self.clearColor = [UIColor blackColor];
    
    // and thirty fps if we can get it; ­change this to 3 if you find your app is struggling
    self.frameInterval = 2;
    
    // set up the data source
    MaplyMBTileSource *tileSource =
    [[MaplyMBTileSource alloc] initWithMBTiles:@"geography-class_medres"];
    
    // set up the layer
    MaplyQuadImageTilesLayer *layer =
    [[MaplyQuadImageTilesLayer alloc] initWithCoordSystem:tileSource.coordSys
                                               tileSource:tileSource];
    layer.handleEdges = YES;
    layer.coverPoles = YES;
    layer.requireElev = false;
    layer.waitLoad = false;
    layer.drawPriority = 0;
    layer.singleLevelLoading = false;
    [self addLayer:layer];

    self.height = 0.8;
    [self animateToPosition:MaplyCoordinateMakeWithDegrees(-122.4192,37.7793) time:1.0];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
