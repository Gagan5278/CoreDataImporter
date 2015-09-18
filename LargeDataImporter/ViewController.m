//
//  ViewController.m
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import "ViewController.h"
#import "ImportOperation.h"
#import "UFOSighting+Additions.h"
#import "SimilarObjectViewController.h"
@interface ViewController ()<NSFetchedResultsControllerDelegate>
{
    AppDelegate *objAppDel;
}

@end
#define TableCellIdentifier @"TableCell"
@implementation ViewController
@synthesize fetchResultController=_fetchResultController;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.downloadProgress.progress=0.0;
    objAppDel=[[UIApplication sharedApplication]delegate];
    //Uncomment below code as well as codes in ImportOperation.m & CustomPersistentStack.m for showing data in rableview for each show. But this will increase import time as well as consumed memory.
    /*****************************************1***************************************/
    //self.dataTableView.dataSource=self;
    //self.dataTableView.delegate=self;
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FetchRequestOnNotification) name:LDIMasterConextInitialized object:nil];
    /*****************************************1***************************************/
    [self FetchRequestOnNotification];
}

-(void)FetchRequestOnNotification
{
    
  //  [[NSNotificationCenter defaultCenter]  removeObserver:self name:LDIMasterConextInitialized object:nil];
    self.fetchResultController=nil;
    NSError *fetchError;
    if(![self.fetchResultController performFetch:&fetchError])
    {
        NSLog(@"Fetch Error: %@",fetchError.localizedDescription);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataTableView.dataSource=self;
        self.dataTableView.delegate=self;
        [self.dataTableView reloadData];
    });
}

-(NSFetchedResultsController*)fetchResultController
{
    if(_fetchResultController)
    {
        return _fetchResultController;
    }
    if(objAppDel.masterManagedObjectContext==nil)
    {
        return nil;
    }
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:[UFOSighting entityName]];
    NSSortDescriptor *sortDescriptor =[NSSortDescriptor sortDescriptorWithKey:UFO_KEY_COREDATA_GUID ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    _fetchResultController=[[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:objAppDel.managedObjectContext  sectionNameKeyPath:nil cacheName:nil];
    _fetchResultController.delegate=self;
    return _fetchResultController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(NSOperationQueue*)operationQueue{
    if(_operationQueue)
    {
        return _operationQueue;
    }
    _operationQueue=[[NSOperationQueue alloc]init];
    [_operationQueue addObserver:self forKeyPath:@"ChagedInOperation" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    return _operationQueue;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"ChagedInOperation"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if([[change valueForKey:@"new"] integerValue]>0)
            {
                self.importButton.title=@"Cancel";
            }
            else{
                self.importButton.title=@"Import";
                self.operationQueue=nil;
            }
        });
    }
}

- (IBAction)importButtonPressed:(id)sender {
    if(self.operationQueue.operationCount==0)
    {
        NSURL *flleURL =[[NSBundle mainBundle]URLForResource:@"ufo" withExtension:@"json"];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        AppDelegate *objectAppDel=[[UIApplication sharedApplication] delegate];
        ImportOperation *objectImport =[[ImportOperation alloc]initWithStack:objectAppDel.objectCustomStack importFileURL:flleURL];
        objectImport.progressCallback=^(float progress)
        {
            NSLog(@"progress is : %f",progress);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.downloadProgress.progress=progress;
            });
            if(progress==1.0)
            {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            }
        };
        [self.operationQueue addOperation:objectImport];
    }
    else{
        [self.operationQueue cancelAllOperations];
        self.downloadProgress.progress=0.0;
    }
}

-(void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    UFOSighting *objectSighting = [_fetchResultController objectAtIndexPath:indexPath];
    cell.textLabel.text=objectSighting.location;
    cell.detailTextLabel.text=[NSString stringWithFormat:@"IndexPath : %ld...%@",indexPath.row, objectSighting.duratiion];
}

#pragma mark TableCell Delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [[_fetchResultController sections] count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    id <NSFetchedResultsSectionInfo> sectionInfo  =[[_fetchResultController sections]objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:TableCellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma -mark FectController Delegate
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.dataTableView endUpdates];
}

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.dataTableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeDelete:
            [self.dataTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeInsert:
            [self.dataTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.dataTableView;
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    SimilarObjectViewController*object=segue.destinationViewController;
    object.managedObjectContext=objAppDel.objectCustomStack.managedObjectContext;
}

@end
