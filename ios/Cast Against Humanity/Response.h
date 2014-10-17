//
//  Response.h
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Response : NSObject

@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic) int submitterID;

- (id)init;

@end
