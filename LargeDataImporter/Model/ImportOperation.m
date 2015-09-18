//
//  ImportOperation.m
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import "ImportOperation.h"
#import "CustomPersistentStack.h"
#import "UFOSighting+Additions.h"
#import "NSString+Addition.h"
@interface ImportOperation()
@property(nonatomic,strong)CustomPersistentStack *persistentStack;
@property(nonatomic,strong)NSURL *fileImportURL;
@property(nonatomic,strong)NSManagedObjectContext *managedObjectContext;
@end
@implementation ImportOperation

-(instancetype)initWithStack:(CustomPersistentStack*)customStack importFileURL:(NSURL*)fileURL
{
    self=[super init];
    if(self)
    {
        self.persistentStack=customStack;
        self.fileImportURL=fileURL;
    }
    return self;
}

-(void)main
{
    TICK;
    @autoreleasepool {
        //1. Worst Case for importing File. Will block UI & takes long time
        //            self.managedObjectContext=self.persistentStack.managedObjectContext;
        //            self.managedObjectContext.undoManager=nil;
        //            [self.managedObjectContext performBlock:^{
        //                [self import];
        //            }];
        
        //2. Bad case for importing file. This time UI will not get block as importing is going on PrivateQueue but on same Stack
        //          self.managedObjectContext=[self.persistentStack newManagedObjectCOntextOnSameStack];
        //          self.managedObjectContext.undoManager=nil;
        //          [self.managedObjectContext performBlock:^{
        //             [self import];
        //          }];
        
        //3. Import with Find & Create . GOOD but will consume too much memeory. Operation will occure on PrivateQueue
        //            self.managedObjectContext=[self.persistentStack newManagedObjectCOntextOnSameStack];
        //            self.managedObjectContext.undoManager=nil;
        //            [self.managedObjectContext performBlockAndWait:^{
        //             [self importWithFindAndCreate];
        //           }];
        
        //4. Very Good. Import on new private Queue on new persistent Stack with Batch Saving
//            self.managedObjectContext=[self.persistentStack newManagedObjectContextOnNewStack];
//            self.managedObjectContext.undoManager=nil;
//            [self.managedObjectContext performBlockAndWait:^{
//               [self importWithFindAndCreate];
//            }];
        //5. Best. Import on new private Queue on new persistent Stack
        self.managedObjectContext=[self.persistentStack newManagedObjectContextOnNewStack];
        self.managedObjectContext.undoManager=nil;
        [self.managedObjectContext performBlockAndWait:^{
              [self importOnNewPrivateQueueAndStackWithBatchSaving];
        }];

    }
    TOCK;
}

-(void)import
{
    NSData *data =[NSData dataWithContentsOfFile:self.fileImportURL.path];
    id arrayOfRecord =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if([arrayOfRecord isKindOfClass:[NSArray class]])
    {
        NSUInteger totalNumberOfObjects =[arrayOfRecord count];
        NSUInteger downloadProgressTrack = totalNumberOfObjects/100;
        
        NSUInteger iterateCounter =0;
        for(NSDictionary *dictOfUFO in arrayOfRecord)
        {
            iterateCounter++;
            if(self.cancelled)
            {
                return;
            }
            [UFOSighting importData:dictOfUFO inContext:self.managedObjectContext];
            //Save
            if(iterateCounter%MDM_BATCH_SIZE_SAVE==0)
            {
                [self saveInManagedContext];
            }
            //Progress Block
            if(iterateCounter%downloadProgressTrack==0)
            {
                [self updateLoadProgress:(float)iterateCounter/(float)downloadProgressTrack];
            }
        }
    }
}

-(void)importWithFindAndCreate
{
    NSData *fileData =[NSData dataWithContentsOfFile:self.fileImportURL.path];
    id arrayOfData =[NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableContainers error:nil];
    if([arrayOfData isKindOfClass:[NSArray class]])
    {
        NSUInteger totalUFOCount = [arrayOfData count];
        NSUInteger downloadProgress = totalUFOCount/100;
        NSUInteger intCounter=0;
        
        //Sorted Array
        NSArray *sortedArray =[arrayOfData sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary *obj2) {
            return  [[obj1 valueForKey:UFO_KEY_COREDATA_GUID] compare:[obj2 valueForKey:UFO_KEY_COREDATA_GUID]];
        } ];
        
        NSFetchRequest *fetchedRequest =[NSFetchRequest fetchRequestWithEntityName:[UFOSighting entityName]];
        NSSortDescriptor *sortDescriptor =[NSSortDescriptor sortDescriptorWithKey:UFO_KEY_COREDATA_GUID ascending:YES];
        [fetchedRequest setSortDescriptors:@[sortDescriptor]];
        NSError *fetchError=nil;
        NSArray *fetchedObject =[self.managedObjectContext executeFetchRequest:fetchedRequest error:&fetchError];
        if(fetchError)
        {
            NSLog(@"fetchError is : %@",fetchError.localizedDescription);
            return;
        }
        //Create Enumerators
        NSEnumerator *jsonEnumerator =[sortedArray objectEnumerator];
        NSDictionary *ufoDictionary =[jsonEnumerator nextObject];
        NSEnumerator *fetchResultEnumerator =[fetchedObject objectEnumerator];
        UFOSighting *objectUFOSight =[fetchResultEnumerator nextObject];
        while (ufoDictionary) {
            BOOL isUpdate=NO;
            intCounter++;
            if([[ufoDictionary valueForKey:UFO_KEY_COREDATA_GUID]isEqualToString:objectUFOSight.guid])
            {
                isUpdate=YES;
            }
            if(!isUpdate)  //Create If not exist
            {
                objectUFOSight=[UFOSighting insertNewObjectIntoCotext:self.managedObjectContext];
                objectUFOSight.guid=[ufoDictionary valueForKey:UFO_KEY_COREDATA_GUID];
            }
            //Otherwise update only
            objectUFOSight.desc =[NSString isNullOrEmptyString:[ufoDictionary valueForKey:UFO_KEY_JSON_DESC]]?@"":[ufoDictionary valueForKey:UFO_KEY_JSON_DESC];
            objectUFOSight.duratiion=[NSString isNullOrEmptyString:[ufoDictionary valueForKey:UFO_KEY_JSON_DURATION] ]?@"":[ufoDictionary valueForKey:UFO_KEY_JSON_DURATION];
            objectUFOSight.location=[NSString isNullOrEmptyString:[ufoDictionary valueForKey:UFO_KEY_JSON_LOCATION] ]?@"":[ufoDictionary valueForKey:UFO_KEY_JSON_LOCATION];
            objectUFOSight.reported=[UFOSighting dateFromString:[NSString isNullOrEmptyString:[ufoDictionary valueForKey:UFO_KEY_JSON_REPORTED]]?@"":[ufoDictionary valueForKey:UFO_KEY_JSON_REPORTED]];
            objectUFOSight.shape=[NSString isNullOrEmptyString:[ufoDictionary valueForKey:UFO_KEY_JSON_SHAPE] ]?@"":[ufoDictionary valueForKey:UFO_KEY_JSON_SHAPE];
            objectUFOSight.sighted=[UFOSighting dateFromString:[NSString isNullOrEmptyString:[ufoDictionary valueForKey:UFO_KEY_JSON_SIGHTED] ]?@"":[ufoDictionary valueForKey:UFO_KEY_JSON_SIGHTED]];
            if(intCounter%MDM_BATCH_SIZE_SAVE==0)
            {
                [self saveInManagedContext];
            }
            if(intCounter%downloadProgress==0)
            {
                float progress= (float)intCounter/(float)totalUFOCount;
                [self updateLoadProgress:progress];
            }
            if(isUpdate)
            {
                ufoDictionary=[jsonEnumerator nextObject];
            }
            else{
                ufoDictionary=[jsonEnumerator nextObject];
                objectUFOSight=[fetchResultEnumerator nextObject];
            }
        }
        [self updateLoadProgress:1.0];
        [self saveInManagedContext];
    }
}

-(void)importOnNewPrivateQueueAndStackWithBatchSaving
{
    NSData *fileData =[NSData dataWithContentsOfFile:self.fileImportURL.path];
    id arrayData =[NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableContainers error:nil];
    if([arrayData isKindOfClass:[NSArray class]])
    {
        NSUInteger totolUFOCount =[arrayData count];
        NSUInteger batchCountTotal = totolUFOCount/MDM_BATCH_SIZE_IMPORT;
        NSUInteger downloadProgressCounter =totolUFOCount/100;
        NSArray *sortedArray =[arrayData sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            return [[obj1 valueForKey:UFO_KEY_COREDATA_GUID] compare:[obj2 valueForKey:UFO_KEY_COREDATA_GUID]];
        }];
        
        NSArray *guidArray=[sortedArray valueForKey:UFO_KEY_COREDATA_GUID];
        for(int batchCounter =0 ; batchCounter<=batchCountTotal;batchCounter++)
        {
            NSRange range =NSMakeRange(batchCounter*MDM_BATCH_SIZE_IMPORT, MDM_BATCH_SIZE_IMPORT);
            if(batchCounter==batchCountTotal)
            {
                range.length=totolUFOCount-MDM_BATCH_SIZE_IMPORT*batchCounter;
            }
            NSArray *subGUIDArray = [guidArray subarrayWithRange:range];
            NSFetchRequest *fetchRequest =[NSFetchRequest fetchRequestWithEntityName:[UFOSighting entityName]];
            NSPredicate *predicate =[NSPredicate predicateWithFormat:@"%@ IN %@",UFO_KEY_COREDATA_GUID, subGUIDArray];
            NSSortDescriptor *sortDescriptor =[NSSortDescriptor sortDescriptorWithKey:UFO_KEY_COREDATA_GUID ascending:YES];
            [fetchRequest  setPredicate:predicate];
            [fetchRequest setSortDescriptors:@[sortDescriptor]];
            NSError *fetchError=nil;
            NSArray *arrayOfUFO=[self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
            if(fetchError)
            {
                NSLog(@"fetchError is : %@",fetchError.localizedDescription);
                return;
            }
            
            NSEnumerator *jsonEnumerator =[[sortedArray subarrayWithRange:range] objectEnumerator];
            NSDictionary *dictionaryUFO=[jsonEnumerator nextObject];
            NSEnumerator *ufoObjectENumerator=[arrayOfUFO objectEnumerator];
            UFOSighting *objectUFOSighting=[ufoObjectENumerator nextObject];
            NSUInteger intCounter=0;
            while (dictionaryUFO) {
                BOOL isFound=NO;
                intCounter++;
                if([[dictionaryUFO valueForKey:UFO_KEY_JSON_GUID] isEqualToString:objectUFOSighting.guid])
                {
                    isFound=YES;
                }
                if(!isFound)  //Create If does not exist
                {
                    objectUFOSighting=[UFOSighting insertNewObjectIntoCotext:self.managedObjectContext];
                    objectUFOSighting.guid=[dictionaryUFO valueForKey:UFO_KEY_JSON_GUID];
                }
                //Otherwise update
                objectUFOSighting.desc =[NSString isNullOrEmptyString:[dictionaryUFO valueForKey:UFO_KEY_JSON_DESC]]?@"":[dictionaryUFO valueForKey:UFO_KEY_JSON_DESC];
                objectUFOSighting.duratiion=[NSString isNullOrEmptyString:[dictionaryUFO valueForKey:UFO_KEY_JSON_DURATION] ]?@"":[dictionaryUFO valueForKey:UFO_KEY_JSON_DURATION];
                objectUFOSighting.location=[NSString isNullOrEmptyString:[dictionaryUFO valueForKey:UFO_KEY_JSON_LOCATION] ]?@"":[dictionaryUFO valueForKey:UFO_KEY_JSON_LOCATION];
                objectUFOSighting.reported=[UFOSighting dateFromString:[NSString isNullOrEmptyString:[dictionaryUFO valueForKey:UFO_KEY_JSON_REPORTED]]?@"":[dictionaryUFO valueForKey:UFO_KEY_JSON_REPORTED]];
                objectUFOSighting.shape=[NSString isNullOrEmptyString:[dictionaryUFO valueForKey:UFO_KEY_JSON_SHAPE] ]?@"":[dictionaryUFO valueForKey:UFO_KEY_JSON_SHAPE];
                objectUFOSighting.sighted=[UFOSighting dateFromString:[NSString isNullOrEmptyString:[dictionaryUFO valueForKey:UFO_KEY_JSON_SIGHTED] ]?@"":[dictionaryUFO valueForKey:UFO_KEY_JSON_SIGHTED]];
                if(intCounter%MDM_BATCH_SIZE_IMPORT==0)
                {
                    //Uncomment Below notification line if you want to display data in tableView on Each load. This will increase time as well as memory
                    [self saveInManagedContext];
                   //  [[NSNotificationCenter defaultCenter]postNotificationName:LDIMasterConextInitialized object:nil userInfo:nil];
                }
                if(intCounter%downloadProgressCounter==0)
                {
                    float progress = ((float)intCounter + (float)batchCounter*MDM_BATCH_SIZE_IMPORT)/(float)totolUFOCount;
                    [self updateLoadProgress:progress];
                }
                if(isFound)
                {
                    dictionaryUFO =[jsonEnumerator nextObject];
                    objectUFOSighting=[ufoObjectENumerator nextObject];
                }
                else{
                    dictionaryUFO =[jsonEnumerator nextObject];
                }
            }
        }
        [self saveInManagedContext];
    }
}

-(void)saveInManagedContext
{
    NSError *error=nil;
    if([self.managedObjectContext save:&error])
    {
        NSLog(@"Saved");
    }
}

-(void)updateLoadProgress:(float)progress
{
    if(self.progressCallback)
    {
        self.progressCallback(progress);
    }
}

@end
