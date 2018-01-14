

#import "FNTextLabel.h"
#import "OSCheck.h"

@implementation FNTextLabel

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if(!self) 
    {
        return nil;
    }
    
    [self setBordered:NO];
    [self setDrawsBackground:NO];
    
    if(!isLeopardOrAbove())
    {
        [self setTextColor:[NSColor blackColor]];
    }
    else
    {
        [self setTextColor:[NSColor whiteColor]];
    }
    
    return self;
}

- (void)awakeFromNib
{
    if(!isLeopardOrAbove())
    {
        [self setTextColor:[NSColor blackColor]];
    }
    else
    {
        [self setTextColor:[NSColor whiteColor]];
    }
}

@end
