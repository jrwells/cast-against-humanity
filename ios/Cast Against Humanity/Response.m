//
//  Response.m
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import "Response.h"

@implementation Response

@synthesize cards;
@synthesize submitterID;

- (id) init {
    self = [super init];
    self.cards = [NSMutableArray array];
    self.submitterID = -1;
    return (self);
}

//- (id)copyWithZone:(NSZone *)zone
//{
//    id copy = [[[self class] alloc] init];
//    
//    if (copy)
//    {
//        // Copy NSObject subclasses
//        [copy setCards:[self.cards copyWithZone:zone]];
//        
//        // Set primitives
//        [copy setSubmitterID:self.submitterID];
//    }
//    
//    return copy;
//}

@end
