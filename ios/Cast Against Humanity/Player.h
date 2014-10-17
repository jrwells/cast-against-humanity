//
//  Player.h
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Player : NSObject

@property (nonatomic, strong) NSMutableArray *hand;
@property (nonatomic) int playerID;

- (id)init;

@end
