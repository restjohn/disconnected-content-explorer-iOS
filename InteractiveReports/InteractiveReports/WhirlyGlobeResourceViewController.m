//
//  WhirlyGlobeResourceViewController.m
//  InteractiveReports
//
//  Created by Robert St. John on 12/11/14.
//  Copyright (c) 2014 mil.nga. All rights reserved.
//

#import "WhirlyGlobeResourceViewController.h"

#import "KML.h"
#import <math.h>


@implementation WhirlyGlobeResourceViewController {
    NSOperationQueue *downloadQueue;
    MaplyCoordinate cameraPosition;
}

- (float)degToRad:(float)deg
{
    return deg / 180.0F * M_PI;
}

- (void)handleResource:(NSURL *)resource forReport:(Report *)report
{
    NSMutableArray *marks = [[NSMutableArray alloc] init];
    float minLat = 0.0, minLon = 0.0;
    KMLRoot *root = [KMLParser parseKMLAtURL:resource];
    for (KMLPlacemark *placemark in root.placemarks) {
        if ([placemark.geometry isKindOfClass:KMLPoint.class]) {
            KMLPoint *point = (KMLPoint *)placemark.geometry;
            const MaplyCoordinate3d location = MaplyCoordinate3dMake([self degToRad:point.coordinate.longitude], [self degToRad:point.coordinate.latitude], 1.0);
            NSString *iconURLString = placemark.style.iconStyle.icon.href;
            if (iconURLString) {
                NSURL *iconURL = [NSURL URLWithString:iconURLString];
                NSURLRequest *getIcon = [NSURLRequest requestWithURL:iconURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
                // TODO: if we don't need to support iOS 6, we should use NSURLSession
                [NSURLConnection sendAsynchronousRequest:getIcon queue:downloadQueue
                    completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                        UIImage *icon = [UIImage imageWithData:data];
                        [marks addObject:[self makeBillboardAt:location withIcon:icon]];
                    }];
            }
            else {
                UIImage *icon = [UIImage imageNamed:@"map-point"];
                [marks addObject:[self makeBillboardAt:location withIcon:icon]];
            }
        }
    }
    [self addBillboards:marks desc:nil mode:MaplyThreadAny];
}

- (MaplyScreenMarker *)makeMarkerAt:(MaplyCoordinate3d)location withIcon:(UIImage *)icon
{
    MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
    marker.image = icon;
    marker.loc = MaplyCoordinateMakeWithDegrees(location.x, location.y);
    return marker;
}

- (MaplyBillboard *)makeBillboardAt:(MaplyCoordinate3d)location withIcon:(UIImage *)icon
{
    MaplyBillboard *marker = [[MaplyBillboard alloc] init];
    marker.image = icon;
    marker.center = location;
    marker.size = CGSizeMake(0.1, 0.1);
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
