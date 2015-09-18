//
//  NSString+Addition.m
//  CoreDataMultiple
//
//  Created by Vishal Mishra, Gagan on 04/09/15.
//  Copyright (c) 2015 Vishal Mishra, Gagan. All rights reserved.
//

#import "NSString+Addition.h"

@implementation NSString (Addition)
+(BOOL)isNullOrEmptyString:(NSString *)inString
{
    if ([inString isKindOfClass:[[NSNull null] class]])
    {
        return YES;
    }
    else if (inString.length==0)
    {
        return YES;
    }
    else
        return NO;
}

@end
