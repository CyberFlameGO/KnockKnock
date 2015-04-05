//
//  PluginBase.h
//  BlockBlock
//
//  Created by Patrick Wardle on 9/25/14.
//  Copyright (c) 2014 Synack. All rights reserved.
//

#import "Consts.h"
#import "../Results/ItemBase.h"
#import <Foundation/Foundation.h>

@interface PluginBase : NSObject
{
    
}

//name
@property(retain, nonatomic)NSString* name;

//description
@property(retain, nonatomic)NSString* description;

//all detected items
@property(retain, nonatomic)NSMutableArray* allItems;

//unknown items
@property(retain, nonatomic)NSMutableArray* unknownItems;

//flagged items
@property(retain, nonatomic)NSMutableArray* flaggedItems;

//icon
@property(retain, nonatomic)NSString* icon;

/* METHODS */

//init method
//-(id)initWithParams:(NSDictionary*)params;

//reset
// ->remove all items
-(void)reset;

//scan
-(void)scan;

//process and item
// ->save and report (if necessary)
-(void)processItem:(ItemBase*)item;





@end
