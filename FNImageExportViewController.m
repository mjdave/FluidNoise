
#import "FNImageExportViewController.h"


@implementation FNImageExportViewController

- (id)initWithSavePanel:(NSSavePanel*)sp
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    BOOL OK = [NSBundle loadNibNamed:@"ImageExportView" owner:self];
    if(!OK)
    {
        NSLog(@"failed to load nib ImageExportView");
    }
    
    NSArray* _imageTypes = [NSArray arrayWithObjects:
                @"PNG",
                @"TIFF",
                @"BMP",
                @"GIF",
                @"JPEG",
                @"JPEG2000",
               // @"EXR",/ - commented out by majicdave before making open souce, OpenEXR support could probably be added realtively easily, but I'm not sure the work involved to use the latest versions, and the very old versions of OpenEXR I was using are no longer working
                    nil];
    
    [_imageType removeAllItems];
    [_imageType addItemsWithTitles:_imageTypes];
    [_imageType selectItemAtIndex:0]; 
    
    _sp = sp;
    [_sp setRequiredFileType:@"png"];
    
    NSArray* _bpp = [NSArray arrayWithObjects:
                @"8 bit Color",
                @"32 bit Grayscale Height Map",
                @"32 bit Color",
                    nil];
    
    [_bitsPerPixel removeAllItems];
    [_bitsPerPixel addItemsWithTitles:_bpp];
    [_bitsPerPixel selectItemAtIndex:0]; 
    
    return self;
}

- (NSView*)view
{
    return _view;
}

- (NSString*)fileType
{
    return [[_imageType selectedItem] title];
}

- (NSNumber*)bpp
{
    switch([_bitsPerPixel indexOfSelectedItem])
    {
        case 0:
            return [NSNumber numberWithInt:8];
        break;
        case 1:
            return [NSNumber numberWithInt:32];
        break;
        case 2:
            return [NSNumber numberWithInt:32];
        break;
        default:
            return [NSNumber numberWithInt:8];
        break;
    }
    
    return [NSNumber numberWithInt:8];
}

- (NSNumber*)grayScale
{
    if([_bitsPerPixel indexOfSelectedItem] == 1)
    {
        return [NSNumber numberWithBool:YES];
    }
    
    return [NSNumber numberWithBool:NO];
}

- (IBAction)fileTypeChanged:(id)sender
{
    NSString* fileType = [[sender selectedItem] title];
    if([fileType isEqualToString:@"JPEG2000"])
    {
        [_sp setRequiredFileType:@"jpeg"];
    }
    else
    {
        [_sp setRequiredFileType:[fileType lowercaseString]];
    }
}

- (IBAction)bppChanged:(id)sender
{
    if([_bitsPerPixel indexOfSelectedItem] == 0)
    {
        NSArray* menuItems = [_imageType itemArray];
        unsigned int i;
        for(i = 0; i < [menuItems count]; i++)
        {
            NSMenuItem* item = [menuItems objectAtIndex:i];
            if(([[item title] isEqualToString:@"EXR"]))
            {
                [item setEnabled:NO];
            }
            else
            {
                [item setEnabled:YES];
            }
        }
    }
    else if([_bitsPerPixel indexOfSelectedItem] == 1)
    {
        NSArray* menuItems = [_imageType itemArray];
        unsigned int i;
        for(i = 0; i < [menuItems count]; i++)
        {
            NSMenuItem* item = [menuItems objectAtIndex:i];
            if(!([[item title] isEqualToString:@"TIFF"] ||  [[item title] isEqualToString:@"EXR"]))
            {
                [item setEnabled:NO];
            }
            else
            {
                [item setEnabled:YES];
            }
        }
        
        if(![[_imageType titleOfSelectedItem] isEqualToString:@"EXR"])
        {
            [_imageType selectItemWithTitle:@"TIFF"];
            [_sp setRequiredFileType:@"tiff"];
        }
    }
    else
    {
        NSArray* menuItems = [_imageType itemArray];
        unsigned int i;
        for(i = 0; i < [menuItems count]; i++)
        {
            NSMenuItem* item = [menuItems objectAtIndex:i];
            if(!([[item title] isEqualToString:@"TIFF"] ||  [[item title] isEqualToString:@"EXR"]))
            {
                [item setEnabled:NO];
            }
        }
        
        if(![[_imageType titleOfSelectedItem] isEqualToString:@"EXR"])
        {
            [_imageType selectItemWithTitle:@"TIFF"];
            [_sp setRequiredFileType:@"tiff"];
        }
    }
}

-(void)dealloc
{
    [super dealloc];
}

@end
