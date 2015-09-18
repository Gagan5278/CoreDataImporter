//
//  CustomPersistentStack.h
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@interface CustomPersistentStack : NSObject
@property(nonatomic,strong)NSManagedObjectContext *managedObjectContext;
@property(nonatomic) BOOL disableMergeNotification;

-(instancetype)initWithStoreURL:(NSURL*)storeURL modelURL:(NSURL*)modelURL;

-(NSManagedObjectContext*)newManagedObjectCOntextOnSameStack;
-(NSManagedObjectContext*)newManagedObjectContextOnNewStack;
//@property(nonatomic,strong,readwrite)NSManagedObjectContext *managedObjectContext;
@end
