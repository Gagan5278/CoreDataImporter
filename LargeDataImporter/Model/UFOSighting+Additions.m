//
//  UFOSighting+Additions.m
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import "UFOSighting+Additions.h"
#import "NSString+Addition.h"
@implementation UFOSighting (Additions)
+(instancetype)importData:(NSDictionary*)dataDictionary inContext:(NSManagedObjectContext*)context
{
    NSString *guid =[dataDictionary valueForKey:UFO_KEY_JSON_GUID];
    UFOSighting *objectUFOSighting = [UFOSighting FindOrCreateWithIdentifier:guid inContext:context];
    objectUFOSighting.desc =[NSString isNullOrEmptyString:[dataDictionary valueForKey:UFO_KEY_JSON_DESC]]?@"":[dataDictionary valueForKey:UFO_KEY_JSON_DESC];
    objectUFOSighting.duratiion=[NSString isNullOrEmptyString:[dataDictionary valueForKey:UFO_KEY_JSON_DURATION] ]?@"":[dataDictionary valueForKey:UFO_KEY_JSON_DURATION];
    objectUFOSighting.guid=[NSString isNullOrEmptyString:[dataDictionary valueForKey:UFO_KEY_JSON_GUID] ]?@"":[dataDictionary valueForKey:UFO_KEY_JSON_GUID];
    objectUFOSighting.location=[NSString isNullOrEmptyString:[dataDictionary valueForKey:UFO_KEY_JSON_LOCATION] ]?@"":[dataDictionary valueForKey:UFO_KEY_JSON_LOCATION];
    objectUFOSighting.reported=[UFOSighting dateFromString:[NSString isNullOrEmptyString:[dataDictionary valueForKey:UFO_KEY_JSON_REPORTED]]?@"":[dataDictionary valueForKey:UFO_KEY_JSON_REPORTED]];
    objectUFOSighting.shape=[NSString isNullOrEmptyString:[dataDictionary valueForKey:UFO_KEY_JSON_SHAPE] ]?@"":[dataDictionary valueForKey:UFO_KEY_JSON_SHAPE];
    objectUFOSighting.sighted=[UFOSighting dateFromString:[NSString isNullOrEmptyString:[dataDictionary valueForKey:UFO_KEY_JSON_SIGHTED] ]?@"":[dataDictionary valueForKey:UFO_KEY_JSON_SIGHTED]];
    return objectUFOSighting;
}

+(instancetype)FindOrCreateWithIdentifier:(NSString*)identifier inContext:(NSManagedObjectContext*)context
{
    NSFetchRequest *fetchRequest=[[NSFetchRequest alloc]initWithEntityName:[self entityName]];
    NSPredicate *fetchPredicate =[ NSPredicate predicateWithFormat:@"%@ IN %@",UFO_KEY_COREDATA_GUID,identifier];
    [fetchRequest setPredicate:fetchPredicate];
    fetchRequest.fetchLimit=1;
    NSError *fetchError=nil;
    id object = [[context executeFetchRequest:fetchRequest error:&fetchError] lastObject];
    if(object==nil && !fetchError)  //Object Does Not Exist in DataBase so create new one
    {
        object = [UFOSighting insertNewObjectIntoCotext:context];
    }
    return object;
}

+(instancetype)insertNewObjectIntoCotext:(NSManagedObjectContext*)conext
{
    return ([NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:conext]);
}

+(NSString*)entityName
{
    return NSStringFromClass(self);
}

+(NSDate*)dateFromString:(NSString*)dateString
{
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy:MM:DD"];
    return  [dateFormatter dateFromString:dateString];
}

+(NSString*)stringFromDate:(NSDate*)dateObject
{
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy:MM:DD"];
    return [dateFormatter stringFromDate:dateObject];
}

@end
