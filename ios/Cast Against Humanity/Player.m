//
//  Player.m
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import "Player.h"

@implementation Player

@synthesize hand;
@synthesize playerID;

- (id) init {
    self = [super init];
    self.hand = [NSMutableArray array];
    self.playerID = -1;
    return (self);
}

//- (id)copyWithZone:(NSZone *)zone
//{
//    id copy = [[[self class] alloc] init];
//    
//    if (copy)
//    {
//        // Copy NSObject subclasses
//        [copy setHand:[self.hand copyWithZone:zone]];
//        
//        // Set primitives
//        [copy setPlayerID:self.playerID];
//    }
//    
//    return copy;
//}

@end
