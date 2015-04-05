//
//  Extension.m
//  KnockKnock
//
//  Created by Patrick Wardle on 2/19/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "Consts.h"
#import "Extension.h"
#import "AppDelegate.h"

@implementation Extension

//init method
-(id)initWithParams:(NSDictionary*)params
{
    //super
    self = [super initWithParams:params];
    if(nil != self)
    {
        //extract/save id
        self.identifier = params[KEY_EXTENSION_ID];
        
        //extract/save description
        self.details = params[KEY_EXTENSION_DETAILS];
        
        //extract/save description
        self.browser = params[KEY_EXTENSION_BROWSER];
        
        //call into filter object to check if file is known
        // ->signed or whitelisted
        self.isTrusted = [((AppDelegate*)[[NSApplication sharedApplication] delegate]).filterObj isTrustedExtension:self];
    }
    
    return self;
}


//convert object to JSON string
-(NSString*)toJSON
{
    //json string
    NSString *json = nil;
    
    //init json
    json = [NSString stringWithFormat:@"\"name\": \"%@\", \"path\": \"%@\", \"identifier\": \"%@\", \"details\": \"%@\", \"browser\": \"%@\"", self.name, self.path, self.identifier, self.details, self.browser];
    
    return json;
}

@end
