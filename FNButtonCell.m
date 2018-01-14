
#import "FNButtonCell.h"
#import "OSCheck.h"

static NSImage* _leftImage = nil;
static NSImage* _leftImageInverted = nil;
static NSImage* _rightImage = nil;
static NSImage* _rightImageInverted = nil;

static NSRect   _leftImageRect = {{0, 0}, {0, 0}};
static NSRect   _rightImageRect = {{0, 0}, {0, 0}};

@implementation FNButtonCell

+ (void)load
{
    if(isLeopardOrAbove())
    {
        NSAutoreleasePool*  pool;
        pool = [[NSAutoreleasePool alloc] init];
        
        if (!_leftImage) {
            NSBundle*   bundle;
            bundle = [NSBundle bundleForClass:self];
            
             _leftImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"darkButtonLeft"]];
             _rightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"darkButtonRight"]];
                
            _leftImageRect.size = [_leftImage size];
            _rightImageRect.size = [_rightImage size];
            
            _leftImageInverted = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"darkButtonLeftInverted"]];
            _rightImageInverted = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"darkButtonRightInverted"]];
        }
        
        [pool release];
    }
}

- (void)awakeFromNib
{
    //NSLog(@"I have awoken:%@",[self title]);
    [self setTitle:[self title]];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    if(isLeopardOrAbove())
    {
        float rightImageWidth = _rightImageRect.size.width * (frame.size.height / _rightImageRect.size.height);
        
        BOOL highlighted = [self isHighlighted];
        
        NSRect imageRect;
        imageRect.origin = frame.origin;
        imageRect.size.height = frame.size.height;
        imageRect.size.width = _leftImageRect.size.width * (frame.size.height / _leftImageRect.size.height);
        if (NSIntersectsRect(imageRect, frame))
        {
            if(highlighted)
            {
                [_leftImageInverted drawInRect:imageRect fromRect:_leftImageRect operation:NSCompositeSourceOver fraction:1.0f];
            }
            else
            {
                [_leftImage drawInRect:imageRect fromRect:_leftImageRect operation:NSCompositeSourceOver fraction:1.0f];
            }
        }
        
        NSRect croppedImageRect = NSMakeRect(_leftImageRect.size.width -1, frame.origin.y, 1, frame.size.height / (frame.size.height / _leftImageRect.size.height));
        imageRect.origin.x += imageRect.size.width;
        imageRect.size.width = frame.size.width - imageRect.size.width - rightImageWidth;
        
        if (NSIntersectsRect(imageRect, frame)) 
        {
            if(highlighted)
            {
                [_leftImageInverted drawInRect:imageRect fromRect:croppedImageRect operation:NSCompositeSourceOver fraction:1.0f];
            }
            else
            {
                [_leftImage drawInRect:imageRect fromRect:croppedImageRect operation:NSCompositeSourceOver fraction:1.0f];
            }
        }
        
        imageRect.origin.x += imageRect.size.width;
        imageRect.size.height = frame.size.height;
        imageRect.size.width = rightImageWidth;
        
        if (NSIntersectsRect(imageRect, frame)) 
        {
            if(highlighted)
            {
                [_rightImageInverted drawInRect:imageRect fromRect:_rightImageRect operation:NSCompositeSourceOver fraction:1.0f];
            }
            else
            {
                [_rightImage drawInRect:imageRect fromRect:_rightImageRect operation:NSCompositeSourceOver fraction:1.0f];
            }
        }
    }
    else
    {
        [super drawBezelWithFrame:frame inView:controlView];
    }
}

- (void)setTitle:(NSString*)title
{
    //NSLog(@"setTitle:%@",title);
    if(isLeopardOrAbove())
    {
        NSAttributedString* currentAttributedTitle = [self attributedTitle];
        NSMutableDictionary* newAttributes = NULL;
        if(currentAttributedTitle && [currentAttributedTitle length] > 0)
        {
            NSDictionary* currentAttributes = [currentAttributedTitle attributesAtIndex:0 effectiveRange:NULL];
            [currentAttributes retain];
            
            newAttributes = [NSMutableDictionary dictionaryWithDictionary:currentAttributes];
            [newAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        }
        else
        {
            newAttributes = [NSMutableDictionary dictionary];
            [newAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        }
        
        NSAttributedString* attrString = [[NSAttributedString alloc] initWithString:title attributes:newAttributes];
        [attrString autorelease];
        [self setAttributedTitle:attrString];
    }
    else
    {
        [super setTitle:title];
    }
}

- (void)setAttributedTitle:(NSAttributedString*)title
{
   // NSLog(@"attr:%@",[title string]);
    [super setAttributedTitle:title];
}

@end
