//
//  Card.h
//  Cast Against Humanity
//
//  Created by James Robert on 11/21/13.
//  Copyright (c) 2013 TMJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Card : NSObject <NSCopying>

@property (nonatomic, strong, retain) NSString *text;
@property (nonatomic) int cardID;

- (id)init;

@end
