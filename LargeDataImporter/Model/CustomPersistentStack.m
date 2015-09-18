//
//  CustomPersistentStack.m
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import "CustomPersistentStack.h"
@interface CustomPersistentStack()

@property(nonatomic,strong) NSURL *storeURL;
@property(nonatomic,strong) NSURL *modelURL;
@end
@implementation CustomPersistentStack
-(instancetype)initWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL
{
    self = [super init];
    if(self)
    {
        self.storeURL=storeURL;
        self.modelURL=modelURL;
        [self setUpPersistentStack]; //work on iOS 7 & Above for below iOS 6 use Async
    }
    return self;
}

-(void)setUpPersistentStack
{
    NSManagedObjectModel *model=[[NSManagedObjectModel alloc]initWithContentsOfURL:self.modelURL];
    if(!model)
    {
        NSLog(@"Model Data Base does not exist");
        NSAssert(NO, @"Failed:");
    }
    
    //PersistentStore Coordinator
    NSPersistentStoreCoordinator *storeCoordinator =[[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:model];
    if(!storeCoordinator)
    {
        NSLog(@"Can not create storeCoordinator");
        NSAssert(NO, @"Failed:");
    }
    
    NSDictionary *dictionary =@{NSInferMappingModelAutomaticallyOption:@YES, NSMigratePersistentStoresAutomaticallyOption:@YES};
    NSError *error=nil;
    NSPersistentStore *persistentStore =[storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:dictionary error:&error];
    if(!persistentStore)
    {
        NSLog(@"Can not create persistentStore: %@",error.localizedDescription);
        NSAssert(NO, @"Failed:");
        NSError *deleteError=nil;
        if([[NSFileManager defaultManager]removeItemAtURL:self.storeURL error:&deleteError])
        {
            persistentStore =[storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:dictionary error:&error];
            if(!persistentStore)
            {
                NSLog(@"error in deleting content : %@",deleteError.localizedDescription);
                abort();
            }
        }
    }
    self.managedObjectContext=[[NSManagedObjectContext alloc]initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.managedObjectContext setPersistentStoreCoordinator:storeCoordinator];
    if(!self.managedObjectContext)
    {
        NSLog(@"failed  in creating managedObjectContext");
        abort();
    }
    [self setUpSaveNotification];
    [self setInitialzedStackNotification];
}

-(void)setUpSaveNotification
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didSaveManagedObjectContext:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

-(void)didSaveManagedObjectContext:(NSNotification*)notification
{
    NSManagedObjectContext *saveContext=[notification object];
    if(self.managedObjectContext != saveContext)
    {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }
}

-(void)setInitialzedStackNotification
{
    [[NSNotificationCenter defaultCenter]postNotificationName:LDIInitializedStackNotification object:nil userInfo:nil];
}

-(NSManagedObjectContext*)newManagedObjectCOntextOnSameStack
{
    NSManagedObjectContext *managedObjectContext=[[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [managedObjectContext setPersistentStoreCoordinator:self.managedObjectContext.persistentStoreCoordinator];
    return managedObjectContext;
}

-(NSManagedObjectContext*)newManagedObjectContextOnNewStack
{
    NSManagedObjectModel *model =[[NSManagedObjectModel alloc]initWithContentsOfURL:self.modelURL];
    if(!model)
    {
        NSLog(@"failed in model creation");
        abort();
    }
    NSPersistentStoreCoordinator *storeCoordinator =[[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:model];
    if(storeCoordinator==nil)
    {
        NSLog(@"Failed in storeCoordinator creation");
        abort();
    }
    NSDictionary *dictionary =@{NSInferMappingModelAutomaticallyOption:@YES, NSMigratePersistentStoresAutomaticallyOption:@YES};
    NSError *storeError=nil;
    NSPersistentStore *persistentStore =[storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:dictionary error:&storeError];
    if(!persistentStore)
    {
        NSLog(@"Failed in store Creation in private queue");
        abort();
    }
    NSManagedObjectContext *privateContext =[[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //Uncomment Below lines 1. If you want to show data in tableView on each batch save.
    //NOTE: Please comment Line Code 2.
     /*******************************-----1-----*********************************/
         //AppDelegate *objAppDel=[[UIApplication sharedApplication]delegate];
         //[objAppDel.masterManagedObjectContext setPersistentStoreCoordinator:storeCoordinator];
        // privateContext.parentContext=objAppDel.masterManagedObjectContext;
     /*******************************-----1-----**********************************/

    
      /******************************-----2-----***********************************/
         [privateContext setPersistentStoreCoordinator:storeCoordinator];
    /******************************-----2-----***********************************/
    return privateContext;
}
@end
