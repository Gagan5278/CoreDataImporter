//
//  SimilarObjectViewController.h
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 11/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SimilarObjectViewController : UIViewController
@property(nonatomic,strong)NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UITableView *shapetableView;
@end
