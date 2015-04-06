//
//  ItemTableController.m
//  KnockKnock
//
//  Created by Patrick Wardle on 2/18/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//


#import "File.h"
#import "Consts.h"
#import "Command.h"
#import "VTButton.h"
#import "Extension.h"
#import "Utilities.h"
#import "AppDelegate.h"
#import "Results/ItemBase.h"
#import "ItemTableController.h"
#import "InfoWindowController.h"

#import <AppKit/AppKit.h>

@implementation ItemTableController

@synthesize itemTableView;
@synthesize vtWindowController;
@synthesize infoWindowController;

//invoked automatically while nib is loaded
// ->note: outlets are nil here...
-(id)init
{
    self = [super init];
    if(nil != self)
    {
        ;
    }
    
    return self;
}

//table delegate
// ->return number of rows, which is just number of items in the currently selected plugin
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    //rows
    NSUInteger rows = 0;
    
    //invoke helper function to get array
    // ->then just return its count
    rows =  [[self getTableItems] count];
    
    //if there are no items
    // ->say there is 1, for 'no items found' row
    if(0 == rows)
    {
        //add extra
        rows++;
    }
    
    return rows;
}

//table delegate method
// ->return cell for row
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //item cell
    NSTableCellView *itemCell = nil;
    
    //plugin object
    PluginBase* selectedPluginObj = nil;
    
    //array backing table
    // ->based on filtering options, will either be all items, or only unknown ones
    NSArray* tableItems = nil;
    
    //plugin item for row
    // ->this can be a File, Command, or Extension obj
    ItemBase* item = nil;
    
    //virus total button
    // ->for File objects only...
    VTButton* vtButton;
    
    //attribute dictionary
    NSMutableDictionary *stringAttributes = nil;
    
    //paragraph style
    NSMutableParagraphStyle *paragraphStyle = nil;
    
    //truncate path
    NSString* truncatedPath = nil;
    
    //tracking area
    NSTrackingArea* trackingArea = nil;
    
    //set selected plugin
    selectedPluginObj =  ((AppDelegate*)[[NSApplication sharedApplication] delegate]).selectedPlugin;
  
    //get array backing table
    tableItems = [self getTableItems];
    
    //if not items have been found
    // ->display 'not found' msg
    if( (0 == row) &&
        (0 == [tableItems count]) )
    {
        //cell is of type 'NoResultsCell'
        itemCell = [tableView makeViewWithIdentifier:@"NoResultsCell" owner:self];
        
        //only set msg if plugin isn't nil
        if(nil != selectedPluginObj)
        {
            //set text to not found msg
            [itemCell.textField setStringValue:[NSString stringWithFormat:@"no %@ found", [selectedPluginObj.name lowercaseString]]];
        }
        //plugin nil
        // ->just set string to blank
        else
        {
            //set text to not found msg
            [itemCell.textField setStringValue:@""];
        }
      
        //exit early
        goto bail;
    }

    
    //make table cell
    itemCell = [tableView makeViewWithIdentifier:@"ImageCell" owner:self];
    if(nil == itemCell)
    {
        //bail
        goto bail;
    }
    
    
    //extract plugin item for row
    item = tableItems[row];

    //set main text
    // ->name
    [itemCell.textField setStringValue:item.name];
    
    //init tracking area
    // ->for 'show' button
    trackingArea = [[NSTrackingArea alloc] initWithRect:[[itemCell viewWithTag:TABLE_ROW_SHOW_BUTTON] bounds]
                    options:(NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways)
                    owner:self userInfo:@{@"tag":[NSNumber numberWithUnsignedInteger:TABLE_ROW_SHOW_BUTTON]}];
    //add tracking area to 'show' button
    [[itemCell viewWithTag:TABLE_ROW_SHOW_BUTTON] addTrackingArea:trackingArea];
    
    //init tracking area
    // ->for 'info' button
    trackingArea = [[NSTrackingArea alloc] initWithRect:[[itemCell viewWithTag:TABLE_ROW_INFO_BUTTON] bounds]
                    options:(NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways)
                    owner:self userInfo:@{@"tag":[NSNumber numberWithUnsignedInteger:TABLE_ROW_INFO_BUTTON]}];
    
    //add tracking area to 'info' button
    [[itemCell viewWithTag:TABLE_ROW_INFO_BUTTON] addTrackingArea:trackingArea];
    
    //set detailed text
    // ->path
    if(YES == [item isKindOfClass:[File class]])
    {
        //truncate path
        truncatedPath = stringByTruncatingString([itemCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG], [item path], itemCell.frame.size.width-TABLE_BUTTONS_FILE);
        
        //set detailed text
        // ->always item's path
        [[itemCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG] setStringValue:truncatedPath];

        //set image
        // ->app's icon
        itemCell.imageView.image = getIconForBinary(((File*)item).path, ((File*)item).bundle);
        
        //grab virus total button
        vtButton = [itemCell viewWithTag:TABLE_ROW_VT_BUTTON];
        
        //configure/show VT info
        // ->only if 'disable' preference not set
        if(YES != ((AppDelegate*)[[NSApplication sharedApplication] delegate]).prefsWindowController.disableVTQueries)
        {
            //set button delegate
            vtButton.delegate = self;
            
            //save file obj
            vtButton.fileObj = ((File*)item);
            
            //check if have vt results
            if(nil != ((File*)item).vtInfo)
            {
                //set font
                [vtButton setFont:[NSFont fontWithName:@"Menlo-Bold" size:25]];
                
                //enable
                vtButton.enabled = YES;
                
                //got VT results
                //...set colored icon for files known by virus total
                if(YES == [((File*)item).vtInfo[VT_RESULTS_FOUND] boolValue])
                {
                    //alloc paragraph style
                    paragraphStyle = [[NSMutableParagraphStyle alloc]init];
                    
                    //center the text
                    [paragraphStyle setAlignment:NSCenterTextAlignment];
                    
                    //alloc attributes dictionary
                    stringAttributes = [NSMutableDictionary dictionary];
                    
                    //set underlined attribute
                    stringAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                    
                    //set alignment (center)
                    stringAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
                    
                    //set font
                    stringAttributes[NSFontAttributeName] = [NSFont fontWithName:@"Menlo-Bold" size:15];
                    
                    //known 'good' files (0 positivies)
                    if(0 == [((File*)item).vtInfo[VT_RESULTS_POSITIVES] unsignedIntegerValue])
                    {
                        //set color (black)
                        stringAttributes[NSForegroundColorAttributeName] = [NSColor blackColor];
                        
                        //set string (vt ratio), with attributes
                        [vtButton setAttributedTitle:[[NSAttributedString alloc] initWithString:((File*)item).vtInfo[VT_RESULTS_RATIO] attributes:stringAttributes]];
                        
                        //set color (gray)
                        stringAttributes[NSForegroundColorAttributeName] = [NSColor grayColor];
                        
                        //set selected text color
                        [vtButton setAttributedAlternateTitle:[[NSAttributedString alloc] initWithString:((File*)item).vtInfo[VT_RESULTS_RATIO] attributes:stringAttributes]];
                    }
                    else
                    {
                        //set color (red)
                        stringAttributes[NSForegroundColorAttributeName] = [NSColor redColor];
                        
                        //set string (vt ratio), with attributes
                        [vtButton setAttributedTitle:[[NSAttributedString alloc] initWithString:((File*)item).vtInfo[VT_RESULTS_RATIO] attributes:stringAttributes]];
                        
                        //set color (light red)
                        //stringAttributes[NSForegroundColorAttributeName] = [NSColor colorWithCalibratedRed:(255/255.0f) green:(1.0/255.0f) blue:(1.0/255.0f) alpha:0.5];
                        
                        //set selected text color
                        [vtButton setAttributedAlternateTitle:[[NSAttributedString alloc] initWithString:((File*)item).vtInfo[VT_RESULTS_RATIO] attributes:stringAttributes]];
                    }
                    
                    //enable
                    [vtButton setEnabled:YES];
                }
            
                //file is not known
                // ->reset title to '?'
                else
                {
                    //set title
                    [vtButton setTitle:@"?"];
                }
            }
        
            //no VT results (e.g. unknown file)
            else
            {
                //set font
                [vtButton setFont:[NSFont fontWithName:@"Menlo-Bold" size:8]];
                
                //set title
                [vtButton setTitle:@"▪ ▪ ▪"];
                
                //disable
                vtButton.enabled = NO;
            }
            
            //show virus total button
            vtButton.hidden = NO;
            
            //show virus total label
            [[itemCell viewWithTag:TABLE_ROW_VT_BUTTON+1] setHidden:NO];
            
        }//show VT info (pref not disabled)
        
        //hide VT info
        else
        {
            //hide virus total button
            vtButton.hidden = YES;
            
            //hide virus total button label
            [[itemCell viewWithTag:TABLE_ROW_VT_BUTTON+1] setHidden:YES];
        }

    }
    //EXTENSIONS
    else if(YES == [item isKindOfClass:[Extension class]])
    {
        //truncate path
        truncatedPath = stringByTruncatingString([itemCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG], [item path], itemCell.frame.size.width-TABLE_BUTTONS_EXTENTION);
        
        //set detailed text
        // ->always item's path
        [[itemCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG] setStringValue:truncatedPath];

        //set image
        // ->will be browser's icon
        itemCell.imageView.image = getIconForBinary(((Extension*)item).browser, nil);
        
        //hide virus total icon
        [[itemCell viewWithTag:TABLE_ROW_VT_BUTTON] setHidden:YES];
        
        //hide virus total label
        [[itemCell viewWithTag:TABLE_ROW_VT_BUTTON+1] setHidden:YES];
    }

//bail
bail:
    
    return itemCell;
}

//automatically invoked when mouse entered
-(void)mouseEntered:(NSEvent*)theEvent
{
    //mouse entered
    // ->highlight (visual) state
    [self buttonAppearance:theEvent shouldReset:NO];
    
    return;
    
}

//automaticall invoked when mouse exits
-(void)mouseExited:(NSEvent*)theEvent
{
    //mouse exited
    // ->so reset button to original (visual) state
    [self buttonAppearance:theEvent shouldReset:YES];
    
    return;
}

//set or unset button's highlight
-(void)buttonAppearance:(NSEvent*)theEvent shouldReset:(BOOL)shouldReset
{
    //mouse point
    NSPoint mousePoint = {0};
    
    //row index
    NSUInteger rowIndex = -1;
    
    //current row
    NSTableCellView* currentRow = nil;
    
    //tag
    NSUInteger tag = 0;
    
    //button
    NSButton* button = nil;
    
    //button's label
    NSTextField* label = nil;
    
    //image name
    NSString* imageName =  nil;
    
    //extract tag
    tag = [((NSDictionary*)theEvent.userData)[@"tag"] unsignedIntegerValue];
    
    //restore button back to default (visual) state
    if(YES == shouldReset)
    {
        //set image name
        // ->'info'
        if(TABLE_ROW_INFO_BUTTON == tag)
        {
            //set
            imageName = @"info";
        }
        //set image name
        // ->'info'
        else if(TABLE_ROW_SHOW_BUTTON == tag)
        {
            //set
            imageName = @"show";
        }
    }
    //highlight button
    else
    {
        //set image name
        // ->'info'
        if(TABLE_ROW_INFO_BUTTON == tag)
        {
            //set
            imageName = @"infoOver";
        }
        //set image name
        // ->'info'
        else if(TABLE_ROW_SHOW_BUTTON == tag)
        {
            //set
            imageName = @"showOver";
        }
    }
    
    //grab mouse point
    mousePoint = [self.itemTableView convertPoint:[theEvent locationInWindow] fromView:nil];
    
    //compute row indow
    rowIndex = [self.itemTableView rowAtPoint:mousePoint];
    
    //sanity check
    if(-1 == rowIndex)
    {
        //bail
        goto bail;
    }

    
    //get row that's about to be selected
    currentRow = [self.itemTableView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
    
    //get button
    // ->tag id of button, passed in userData var
    button = [currentRow viewWithTag:[((NSDictionary*)theEvent.userData)[@"tag"] unsignedIntegerValue]];
    label = [currentRow viewWithTag: 1 + [((NSDictionary*)theEvent.userData)[@"tag"] unsignedIntegerValue]];
    
    
    //[label setFont:[NSFont fontWithName:@"Menlo" size:9]];
    
    /*
    //no image for VT button
    // ->reset text color to black
    if(nil == imageName)
    {
        if(YES == shouldReset)
        {
            NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitle]];
            NSRange titleRange = NSMakeRange(0, [colorTitle length]);
            [colorTitle addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:titleRange];
            [button setAttributedTitle:colorTitle];
        }
        else
        {
            NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitle]];
            NSRange titleRange = NSMakeRange(0, [colorTitle length]);
            [colorTitle addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:titleRange];
            [button setAttributedTitle:colorTitle];
        }
        
    }
    */
    
    //restore default button image
    // ->for 'info' and 'show' buttons
    if(nil != imageName)
    {
        //set image
        [button setImage:[NSImage imageNamed:imageName]];
    }
    
//bail
bail:
    
    return;
}

//scroll back up to top of table
-(void)scrollToTop
{
    //scroll if more than 1 row
    if([self.itemTableView numberOfRows] > 0)
    {
        //top
        [self.itemTableView scrollRowToVisible:0];
    }
}

//helper function
// ->get items array (either all or just unknown)
-(NSArray*)getTableItems
{
    //array backing table
    // ->based on filtering options, will either be all items, or only unknown ones
    NSArray* tableItems = nil;
    
    //plugin object
    PluginBase* selectedPluginObj = nil;

    //set selected plugin from app delegate
    selectedPluginObj =  ((AppDelegate*)[[NSApplication sharedApplication] delegate]).selectedPlugin;
    
    //set array backing table
    // ->case: no filtering (i.e., all items)
    if(YES == ((AppDelegate*)[[NSApplication sharedApplication] delegate]).prefsWindowController.showTrustedItems)
    {
        //set count
        tableItems = selectedPluginObj.allItems;
    }
    //set array backing table
    // ->case: filtering (i.e., unknown items)
    else
    {
        //set count
        tableItems = selectedPluginObj.unknownItems;
    }
    
    return tableItems;
}


//automatically invoked when user clicks the 'show in finder' icon
// ->open Finder to show item
-(IBAction)showInFinder:(id)sender
{
    //selected item
    // ->will either be a File, Extension, or Command obj
    ItemBase* selectedItem = nil;
    
    //index of selected row
    NSInteger selectedRow = 0;
        
    //grab selected row
    selectedRow = [self.itemTableView rowForView:sender];
    
    //extract selected item
    selectedItem = [self getTableItems][selectedRow];
        
    //open Finder
    // ->will reveal binary
    [[NSWorkspace sharedWorkspace] selectFile:[selectedItem pathForFinder] inFileViewerRootedAtPath:nil];
        
    return;
}

//automatically invoked when user clicks the 'info' icon
// ->create/configure/display info window
- (IBAction)showInfo:(id)sender
{
    //selected item
    // ->will either be a File, Extension, or Command obj
    ItemBase* selectedItem = nil;
    
    //index of selected row
    NSInteger selectedRow = 0;

    //grab selected row
    selectedRow = [self.itemTableView rowForView:sender];
    
    //extract selected item
    // ->invoke helper function to get array backing table
    selectedItem = [self getTableItems][selectedRow];
   
    //alloc/init info window
    infoWindowController = [[InfoWindowController alloc] initWithItem:selectedItem];
    
    //show it
    [self.infoWindowController.windowController showWindow:self];
    
    return;
}

//invoked when the user clicks 'virus total' icon
// ->launch browser and browse to virus total's page
-(void)showVTInfo:(NSView*)button
{
    //selected item
    File* selectedItem = nil;

    //row that button was clicked on
    NSUInteger rowIndex = -1;
    
    //get row index
    rowIndex = [self.itemTableView rowForView:button];
    
    //sanity check
    if(-1 != rowIndex)
    {
        //extract selected item
        // ->invoke helper function to get array backing table
        selectedItem = [self getTableItems][rowIndex];
        
        //alloc/init info window
        vtWindowController = [[VTInfoWindowController alloc] initWithItem:selectedItem rowIndex:rowIndex];
        
        //show it
        [self.vtWindowController.windowController showWindow:self];
      
        /*
        //make it modal
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            //modal!
            [[NSApplication sharedApplication] runModalForWindow:vtWindowController.windowController.window];
            
        });
        */
    }
    
    return;
}

@end
