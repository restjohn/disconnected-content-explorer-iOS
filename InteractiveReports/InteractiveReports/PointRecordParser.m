//
//  PointRecordParser.m
//  InteractiveReports
//
//  Created by Robert St. John on 1/26/15.
//  Copyright (c) 2015 mil.nga. All rights reserved.
//

#import "PointRecordParser.h"

#import "CHCSVParser.h"


@interface PointRecordParser () <CHCSVParserDelegate>

@property (strong, nonatomic) CHCSVParser *parser;

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber;
- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;
- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex;
- (void)parserDidEndDocument:(CHCSVParser *)parser;

@end


@implementation PointRecordParser

NSInteger lastFieldIndex = -1;
CGFloat x, y, z;
NSString *content;

- (instancetype)initWithSource:(NSURL *)source delegate:(id<PointParserDelegate>)delegate
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _source = source;
    _delegate = delegate;
//    NSString *csvContent = [NSString stringWithContentsOfURL:source encoding:NSUTF8StringEncoding error:nil];
//    _parser = [[CHCSVParser alloc] initWithCSVString:csvContent];
//    _parser.delegate = self;
    
    return self;
}

- (void)parsePoints
{
    @autoreleasepool {
        content = [NSString stringWithContentsOfURL:_source encoding:NSUTF8StringEncoding error:nil];
        [content enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray *fields = [line componentsSeparatedByString:@","];
            CGFloat x, y, z;
            NSString *field = fields[0];
            x = [field floatValue];
            field = fields[1];
            y = [field floatValue];
            field = fields[2];
            z = [field floatValue];
            [_delegate pointAtX:x y:y z:z];
        }];
    }
    [_delegate parserDidFinish];
//    [_parser parse];
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex
{
    switch (fieldIndex) {
        case 0:
            x = [field floatValue];
            break;
        case 1:
            y = [field floatValue];
            break;
        case 2:
            z = [field floatValue];
            break;
        default:
            break;
    }
    lastFieldIndex = fieldIndex;
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber
{
    if (lastFieldIndex < 2) {
        NSString *desc = [NSString stringWithFormat:@"%@ did not have enough fields at record %lud to make a 3D point", self, (unsigned long)recordNumber];
        NSError *err = [NSError errorWithDomain:NSStringFromClass([self class]) code:0
                                       userInfo:@{NSLocalizedDescriptionKey: desc}];
        [_delegate parserDidEncounterError:err];
    }
    [_delegate pointAtX:x y:y z:z];
    lastFieldIndex = -1;
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error
{
    [_delegate parserDidEncounterError:error];
}

- (void)parserDidEndDocument:(CHCSVParser *)parser
{
    [_delegate parserDidFinish];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, source: %@", [super description], _source];
}

@end
