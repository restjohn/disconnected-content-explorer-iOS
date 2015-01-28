//
//  PointRecordParser.h
//  InteractiveReports
//
//  Created by Robert St. John on 1/26/15.
//  Copyright (c) 2015 mil.nga. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PointParserDelegate <NSObject>

- (void)pointAtX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z;
- (void)parserDidFinish;
- (void)parserDidEncounterError:(NSError *)error;

@end

/**
 This class parses points from a CSV resource with records of the form x,y,z.
 */
@interface PointRecordParser : NSObject

@property (readonly, weak, nonatomic) NSURL *source;
@property (strong, nonatomic) id<PointParserDelegate> delegate;

- (instancetype)initWithSource:(NSURL *)url delegate:(id<PointParserDelegate>)delegate;
- (void)parsePoints;

@end
