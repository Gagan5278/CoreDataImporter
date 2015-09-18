//
//  UFOSighting.h
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UFOSighting : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * duratiion;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * reported;
@property (nonatomic, retain) NSString * shape;
@property (nonatomic, retain) NSDate * sighted;

@end
