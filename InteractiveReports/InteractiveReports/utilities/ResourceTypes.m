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

+ (void) initialize {
    resourceViewers = [NSDictionary dictionaryWithObjectsAndKeys:
        [GlobeViewController class], @"com.glob3mobile.point_cloud",
        [GlobeViewController class], @"org.asprs.las",
        [GlobeViewController class], @"com.rapidlasso.laszip",
        nil];
}

+ (NSString *)typeUtiOf:(NSURL *)resource
{
    NSString *uti = nil;
    CFStringRef utiRef = NULL;
    [resource getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];
    if (!uti) {
        NSString *resourceExt = [resource pathExtension];
        utiRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)resourceExt, NULL);
        uti = (__bridge NSString *)utiRef;
        [resource setResourceValue: uti forKey: NSURLTypeIdentifierKey error: nil];
    }
    else {
        utiRef = (__bridge CFStringRef)uti;
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
    Class viewer = resourceViewers[uti];
    if (!viewer) {
        return nil;
    }
    return [[viewer alloc] init];
}

@end
