
#import "FNButton.h"
#import "OSCheck.h"
#import "FNButtonCell.h"

@implementation FNButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if(!self)
    {
        return nil;
    }
    
    return self;
}

+ (Class)cellClass
{
    if(isLeopardOrAbove())
    {
        return [FNButtonCell class];
    }
    return [super cellClass];
}

- (void)awakeFromNib
{
    [self setTitle:[self title]];
}

/*- (void)setTitle:(NSString*)title
{
    if(isLeopardOrAbove())
    {
        NSAttributedString* currentAttributedTitle = [self attributedTitle];
        NSDictionary* currentAttributes = [currentAttributedTitle attributesAtIndex:0 effectiveRange:NULL];
        
        NSMutableDictionary* newAttributes = [NSMutableDictionary dictionaryWithDictionary:currentAttributes];
        [newAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        
        NSAttributedString* attrString = [[NSAttributedString alloc] initWithString:title attributes:newAttributes];
        [attrString autorelease];
        [self setAttributedTitle:attrString];
    }
    else
    {
        [super setTitle:title];
    }
}*/

- (void)mouseDown:(NSEvent*)event
{
    //NSLog(@"mouseDown");
    [super mouseDown:event];
}

@end
