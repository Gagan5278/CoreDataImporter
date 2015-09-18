//
//  ViewController.h
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic,strong) NSOperationQueue *operationQueue;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *importButton;
@property (weak, nonatomic) IBOutlet UITableView *dataTableView;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;
@property(strong,nonatomic)NSFetchedResultsController *fetchResultController;
- (IBAction)importButtonPressed:(id)sender;

@end

