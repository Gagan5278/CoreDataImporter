//
//  ImportOperation.h
//  LargeDataImporter
//
//  Created by Vishal Mishra, Gagan on 10/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef  void(^DownloadPregresssCallBack)(float);
@class CustomPersistentStack;
@interface ImportOperation : NSOperation

@property(nonatomic)float progress;
@property(nonatomic,copy)DownloadPregresssCallBack progressCallback;
-(instancetype)initWithStack:(CustomPersistentStack*)customStack importFileURL:(NSURL*)fileURL;


@end
