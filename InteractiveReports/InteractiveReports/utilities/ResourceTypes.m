//
//  FileTypes.m
//  InteractiveReports
//
//  Created by Robert St. John on 11/20/14.
//  Copyright (c) 2014 mil.nga. All rights reserved.
//

#import <MobileCoreServices/UTType.h>

#import "ResourceTypes.h"
#import "GlobeViewController.h"


@interface ResourceTypes ()
@end


@implementation ResourceTypes

NSDictionary *resourceViewers;

+ (void) initialize
{
    resourceViewers = @{
        @"com.glob3mobile.json-pointcloud": @"class:WhirlyGlobeResourceViewController",
        @"org.asprs.las": @"storyboard:globeViewController",
        @"com.rapidlasso.laszip": @"storyboard:globeViewController"
    };
}

+ (NSString *)typeUtiOf:(NSURL *)resource
{
    NSString *uti = nil;
    [resource getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];
    if (!uti) {
        NSString *resourceExt = [resource pathExtension];
        CFStringRef utiRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)resourceExt, NULL);
        uti = (__bridge NSString *)utiRef;
        // TODO: does this do anything?
        [resource setResourceValue: uti forKey: NSURLTypeIdentifierKey error: nil];
    }
    return uti;
}

+ (BOOL)canOpenResource:(NSURL *)resource
{
    NSString *uti = [ResourceTypes typeUtiOf:resource];
    NSArray *docTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
    docTypes = [docTypes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *docType, NSDictionary *bindings) {
        NSArray *utiList = [docType objectForKey:@"LSItemContentTypes"];
        return [utiList containsObject:uti];
    }]];
    return docTypes.count > 0;
}

+ (UIViewController<ResourceHandler> *)viewerForResource:(NSURL *)resource
{
    NSString *uti = [self typeUtiOf:resource];
    NSString* viewerSpec = resourceViewers[uti];
    
    if (!viewerSpec) {
        return nil;
    }
    
    NSArray *viewerParts = [viewerSpec componentsSeparatedByString:@":"];
    NSString *viewerType = viewerParts[0];
    NSString *viewerID = viewerParts[1];
    UIViewController<ResourceHandler> *viewController = nil;
    
    if ([viewerType isEqualToString:@"class"]) {
        Class viewerClass = NSClassFromString(viewerID);
        viewController = [[viewerClass alloc] init];
    }
    else if ([viewerType isEqualToString:@"storyboard"]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        viewController = [storyboard instantiateViewControllerWithIdentifier:viewerID];
    }
    
    return viewController;
}

@end
