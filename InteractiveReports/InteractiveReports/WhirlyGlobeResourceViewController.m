//
//  WhirlyGlobeResourceViewController.m
//  InteractiveReports
//
//  Created by Robert St. John on 12/11/14.
//  Copyright (c) 2014 mil.nga. All rights reserved.
//

#import "WhirlyGlobeResourceViewController.h"


@interface WhirlyGlobeResourceViewController ()

@end

@implementation WhirlyGlobeResourceViewController {
    WhirlyGlobeViewController *globeView;
}

- (void)handleResource:(NSURL *)resource forReport:(Report *)report
{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create an empty globe and add it to the view
    globeView = [[WhirlyGlobeViewController alloc] init];
    [self.view addSubview:globeView.view];
    globeView.view.frame = self.view.bounds;
    [self addChildViewController:globeView];

    // we want a black background for a globe, a white background for a map.
    globeView.clearColor = [UIColor blackColor];
    
    // and thirty fps if we can get it; ­change this to 3 if you find your app is struggling
    globeView.frameInterval = 2;
    
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
    [globeView addLayer:layer];

    globeView.height = 0.8;
    [globeView animateToPosition:MaplyCoordinateMakeWithDegrees(-122.4192,37.7793) time:1.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
