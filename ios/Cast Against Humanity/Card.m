//
//  Card.m
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import "Card.h"

@implementation Card

@synthesize text;
@synthesize cardID;

- (id) init {
    self = [super init];
    self.text = @"";
    self.cardID = -1;
    return (self);
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy)
    {
        // Copy NSObject subclasses
        [copy setText:[self.text copyWithZone:zone]];
        
        // Set primitives
        [copy setCardID:self.cardID];
    }
    
    return copy;
}

@end
