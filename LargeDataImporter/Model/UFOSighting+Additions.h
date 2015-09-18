//
//  UFOSighting+Additions.h
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import "UFOSighting.h"

@interface UFOSighting (Additions)
+(instancetype)importData:(NSDictionary*)dataDictionary inContext:(NSManagedObjectContext*)context;
+(instancetype)FindOrCreateWithIdentifier:(NSString*)identifier inContext:(NSManagedObjectContext*)context;
+(NSString*)entityName;
+(instancetype)insertNewObjectIntoCotext:(NSManagedObjectContext*)conext;
+(NSDate*)dateFromString:(NSString*)dateString;
+(NSString*)stringFromDate:(NSDate*)dateObject;
@end
