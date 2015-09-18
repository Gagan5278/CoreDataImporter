//
//  SimilarObjectViewController.m
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 11/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//
#define tableCell @"cellIdentifier"
#import "SimilarObjectViewController.h"
#import "UFOSighting+Additions.h"
#import "CustomCell.h"
@interface SimilarObjectViewController()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic,strong)NSArray *arrayOfRecords;
@end
@implementation SimilarObjectViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setUpArrayForUniqueShape];
}


-(void)setUpArrayForUniqueShape
{
    self.arrayOfRecords=[NSArray array];
    TICK;
    //1. Worst Case
    //[self setUpArrayWithForLoop];
    //2. Good but not Best
    //[self setUpTableDataFromDictionary];
    //3. Best Approach with Less time
       [self setUpTableFromNSExpression];
    TOCK;
}

-(void)setUpArrayWithForLoop
{
    NSFetchRequest *fetchRequest =[NSFetchRequest fetchRequestWithEntityName:[UFOSighting entityName]];
    NSError *errorFetch=nil;
    NSArray *arrayOfRecord=[self.managedObjectContext executeFetchRequest:fetchRequest error:&errorFetch];
    NSMutableDictionary *dictionaryOfRecord=[NSMutableDictionary dictionary];
    for (UFOSighting *ufoSightObject in arrayOfRecord) {
        NSString *objectShape =ufoSightObject.shape;
        if([dictionaryOfRecord valueForKey:objectShape]==nil)
        {
            [dictionaryOfRecord setValue:@"1" forKey:objectShape];
        }
        else{
            [dictionaryOfRecord setValue:[NSString stringWithFormat:@"%d",[[dictionaryOfRecord valueForKey:objectShape]intValue]+1] forKey:objectShape];
        }
    }
    
    NSMutableArray *arrayTemp=[NSMutableArray array];
    for (NSString *key in dictionaryOfRecord)
    {
        NSMutableDictionary *dictionaryData=[NSMutableDictionary dictionary];
        [dictionaryData setValue:key forKey:@"shape"];
        [dictionaryData setValue:[dictionaryOfRecord valueForKey:key] forKey:@"count"];
        [arrayTemp addObject:dictionaryData];
    }
    self.arrayOfRecords=[arrayTemp sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [[obj1 valueForKey:@"shape"] compare:[obj2 valueForKey:@"shape"]];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.shapetableView reloadData];
    });
}

-(void)setUpTableDataFromDictionary
{
    NSFetchRequest *fetchRequest =[NSFetchRequest fetchRequestWithEntityName:[UFOSighting entityName]];
    [fetchRequest setResultType:NSDictionaryResultType];
    [fetchRequest setPropertiesToFetch:@[UFO_KEY_COREDATA_SHAPE]];
    NSError *fetchError=nil;
    NSArray *arrayOfRecord=[self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    NSMutableDictionary *dictionaryData=[NSMutableDictionary dictionary];
    for(NSDictionary *dict in arrayOfRecord)
    {
        NSString *shape=[dict valueForKey:@"shape"];
        if([dictionaryData valueForKey:shape]==nil)
        {
            [dictionaryData setValue:@"1" forKey:shape];
        }
        else{
            [dictionaryData setValue:[NSString stringWithFormat:@"%ld",[[dictionaryData valueForKey:shape] integerValue]+1] forKey:shape];
        }
    }
    NSMutableArray *tempArray=[NSMutableArray array];
    for(NSString *key in dictionaryData)
    {
        NSMutableDictionary *dictRecord=[NSMutableDictionary dictionary];
        [dictRecord setValue:key forKey:@"shape"];
        [dictRecord setValue:[dictionaryData valueForKey:key] forKey:@"count"];
        [tempArray addObject:dictRecord];
    }
    NSArray *sortedArry =[tempArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [[obj1 valueForKey:@"shape"] compare:[obj2 valueForKey:@"shape"]];
    }];
    self.arrayOfRecords=sortedArry.mutableCopy;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.shapetableView reloadData];
    });
}

-(void)setUpTableFromNSExpression
{
    NSExpressionDescription *exprsssinDescription=[[NSExpressionDescription alloc]init];
    [exprsssinDescription setName:@"count"];
    [exprsssinDescription setExpression:[NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:UFO_KEY_COREDATA_SHAPE]]]];
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:[UFOSighting entityName]];
    [fetchRequest setPropertiesToFetch:@[UFO_KEY_COREDATA_SHAPE,exprsssinDescription]];
    [fetchRequest setResultType:NSDictionaryResultType];
    [fetchRequest setPropertiesToGroupBy:@[UFO_KEY_COREDATA_SHAPE]];
    NSError *errorDescription;
    NSArray *arrayOfRecords=[self.managedObjectContext executeFetchRequest:fetchRequest error:&errorDescription];
    NSArray *sortedArray=[arrayOfRecords sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary * obj2) {
        return [[obj1 valueForKey:@"count"] compare:[obj2 valueForKey:@"count"]];
    }];
    self.arrayOfRecords=sortedArray.copy;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.shapetableView reloadData];
    });
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrayOfRecords.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomCell *cell =[tableView dequeueReusableCellWithIdentifier:tableCell];
    cell.titleLabel.text=[[self.arrayOfRecords objectAtIndex:indexPath.row]valueForKey:@"shape"];
    cell.shapeCountLabel.text=[[self.arrayOfRecords objectAtIndex:indexPath.row]valueForKey:@"count"];
    return cell;
}

@end
