

#import "FNGradientWell.h"

#import <QuartzCore/QuartzCore.h>

#import "FNGradient.h"
#import "FNTextLabel.h"
#import "FNButton.h"
//#import "OSCheck.h"

#define SWATCH_SIZE 8.0f
#define OUTER_PADDING 8.0f



@implementation FNGradientWell

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if(!self) 
    {
        return nil;
    }
    
    _fngradient = [[FNGradient defaultGradient] retain];
    
    NSFont* font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
    NSRect boundingRectForFont = [font boundingRectForFont];
    
    NSRect percentageRect = NSMakeRect(OUTER_PADDING, OUTER_PADDING + 3.0f, 30.0f, boundingRectForFont.size.height);
    
    _percentageTextLabel = [[FNTextLabel alloc] initWithFrame:percentageRect];
    [[_percentageTextLabel cell] setControlSize:NSMiniControlSize];
    [_percentageTextLabel setEditable:NO];
    [_percentageTextLabel setSelectable:NO];
    [_percentageTextLabel setFont:font];
    [_percentageTextLabel setBezeled:NO];
    [_percentageTextLabel setStringValue:@"100%"];
    [_percentageTextLabel sizeToFit];
    [_deleteButton setFrameOrigin:NSMakePoint(OUTER_PADDING, OUTER_PADDING)];
    [self addSubview:(NSView*)_percentageTextLabel];
    
    NSRect deleteButtonRect = NSMakeRect(OUTER_PADDING, OUTER_PADDING, 1.0f, 1.0f);
    _deleteButton = [[FNButton alloc] initWithFrame:deleteButtonRect];
    [[_deleteButton cell] setControlSize:NSMiniControlSize];
    [_deleteButton setButtonType:NSMomentaryPushInButton];
    [_deleteButton setBezelStyle:NSRoundedBezelStyle];
    [_deleteButton sizeToFit];
    [_deleteButton setFrameOrigin:NSMakePoint(frame.size.width - OUTER_PADDING - [_deleteButton frame].size.width, OUTER_PADDING)];
    [_deleteButton setAutoresizingMask:NSViewMinXMargin];
    
    NSMutableParagraphStyle* paraStyle = [[[NSMutableParagraphStyle alloc]init]autorelease];
    [paraStyle setAlignment:NSCenterTextAlignment];
    
    
    NSAttributedString* stringVal = [[NSAttributedString alloc] initWithString:@"Delete" attributes:
        [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName,
        [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]], NSFontAttributeName,
        paraStyle, NSParagraphStyleAttributeName,
        nil]];
    [stringVal autorelease];
    [_deleteButton setAttributedTitle:stringVal];
    
    
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(deleteButtonClicked:)];
    
    [self addSubview:(NSView*)_deleteButton];
    
    _bottomOffset = [_deleteButton frame].size.height + [_deleteButton frame].origin.y + OUTER_PADDING;
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects:
            NSColorPboardType, nil]];
            
    
    _gridFilter = [[CIFilter filterWithName:@"CICheckerboardGenerator"] retain];
    [_gridFilter setDefaults];
    [_gridFilter setValue:[CIColor colorWithRed:0.4f green:0.4f blue:0.4f] forKey:@"inputColor0"];
    [_gridFilter setValue:[CIColor colorWithRed:0.6f green:0.6f blue:0.6f] forKey:@"inputColor1"];
    [_gridFilter setValue:[NSNumber numberWithFloat:SWATCH_SIZE * 0.5f] forKey:@"inputWidth"];
    [_gridFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f] forKey:@"inputCenter"];
    
    return self;
}

- (void)updateDeleteButton
{
    if([_fngradient numberOfColors] < 2)
    {
        [_deleteButton setEnabled:NO];
    }
    else
    {
        [_deleteButton setEnabled:YES];
    }
}

- (void)awakeFromNib
{
    if([[self window] styleMask] & NSHUDWindowMask)
    {
        _backgroundBorderColor = [[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:0.5f] retain];
        _inverseBackgroundBorderColor = [[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.5f] retain];
        _swatchBorderColor = [[NSColor whiteColor] retain];
    }
    else
    {
        _backgroundBorderColor = [[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.5f] retain];
        _inverseBackgroundBorderColor = [[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:0.5f] retain];
        _swatchBorderColor = [[NSColor blackColor] retain];
    }
    
    [self updateDeleteButton];
}

- (void)setGradient:(FNGradient*)gradient
{
    if(gradient == _fngradient)
    {
        return;
    }
    
    [_fngradient release];
    _fngradient = [gradient retain];
    [self updateDeleteButton];
    [self takeOwnershipOfColorPanel];
    
    [self setNeedsDisplay:YES];
}

- (FNGradient*)gradient
{
    return [[_fngradient copy] autorelease];
}

- (id)objectValue
{
    return [self gradient];
}

- (void)setTarget:(id)target
{
    _target = target;
}

- (void)setAction:(SEL)action
{
    _action = action;
}

- (void)drawGridInRect:(NSRect)inRect fromRect:(NSRect)fromRect
{
    CIImage* outputImage = [_gridFilter valueForKey:@"outputImage"];
    [outputImage drawInRect:inRect fromRect:fromRect operation:NSCompositeCopy fraction:1.0f];
}

- (void)drawRect:(NSRect)rect
{
    [_backgroundBorderColor set];
    
    NSArray* colors = [_fngradient colors];
    
    NSDictionary* selectedColorDict = [colors objectAtIndex:0];
    float selectedFraction = [[selectedColorDict objectForKey:@"fraction"] floatValue];
    [_percentageTextLabel setStringValue:[[NSString stringWithFormat:@"%.2f", selectedFraction * 100.0f] stringByAppendingString:@"%"]];
    [_percentageTextLabel sizeToFit];
    
    NSRect borderRect = NSMakeRect( 0.5f, 0.5f, [self frame].size.width - 1.0f, [self frame].size.height - 1.0f);
    NSBezierPath* backgroundPath = [NSBezierPath bezierPathWithRect:borderRect];
    [backgroundPath setLineJoinStyle:NSMiterLineJoinStyle];
    [backgroundPath setLineWidth:1.0f];
    [backgroundPath stroke];
        
    float swatchSpace = SWATCH_SIZE * 1.5f;
    NSRect gradientRect = rect;
    
    gradientRect.origin.y = rect.origin.y + swatchSpace + _bottomOffset + 1.0f;
    gradientRect.size.height = rect.origin.y + rect.size.height - swatchSpace - _bottomOffset - OUTER_PADDING - 1.0f;
    
    gradientRect.origin.x = SWATCH_SIZE * 0.5f + OUTER_PADDING;
    gradientRect.size.width = rect.size.width - SWATCH_SIZE - OUTER_PADDING * 2.0f;
    
    _gradientRect = gradientRect;
    
    if (NSIntersectsRect(gradientRect, rect)) 
    {
        NSRect gridRect = NSMakeRect(0.0f,0.0f,gradientRect.size.width, gradientRect.size.height);
        if(![_fngradient isOpaque])
        {
            [self drawGridInRect:gradientRect fromRect:gridRect];
        }
        [_fngradient fillRect:gradientRect];
    }
    
    NSMutableArray* swatchRects = [NSMutableArray array];
    
    float swatchYOffset = _bottomOffset;
    
    int i;
    for(i = (int)[colors count] - 1; i >= 0; i--)
    {
        NSDictionary* colorDict = [colors objectAtIndex:i];
        float fraction = [[colorDict objectForKey:@"fraction"] floatValue];
        NSRect swatchRect = NSMakeRect(gradientRect.origin.x + floor(fraction * gradientRect.size.width) - SWATCH_SIZE * 0.5f,
                                    swatchYOffset,
                                    SWATCH_SIZE, SWATCH_SIZE);
                                    
        NSRect colorRect = NSMakeRect(swatchRect.origin.x + 0.5f,
                                    swatchRect.origin.y + 0.5f,
                                    swatchRect.size.width - 1.0f,
                                    swatchRect.size.height - 1.0f);
        
        
        NSRect clickRect = NSMakeRect(gradientRect.origin.x + floor(fraction * gradientRect.size.width) - SWATCH_SIZE * 0.5f,
                                    swatchYOffset,
                                    SWATCH_SIZE + 1.0f, SWATCH_SIZE + 1.0f);
        [swatchRects insertObject:[NSValue valueWithRect:clickRect] atIndex:0];
        
        NSColor* color = [colorDict objectForKey:@"color"];
        
        if([color alphaComponent] < 0.99999f)
        {
            NSRect swatchGridRect = NSMakeRect(0.0f,0.0f,colorRect.size.width, colorRect.size.height);
            [self drawGridInRect:colorRect fromRect:swatchGridRect];
        }
        
        [color set];
        NSBezierPath* path = [NSBezierPath bezierPathWithRect:colorRect];
        [path fill];
        
        float lineWidth = 1.0f;
        
        if(i == 0)
        {
            lineWidth = 1.5f;
        }
        
        NSBezierPath* outline = [NSBezierPath bezierPath];
        [outline setLineJoinStyle:NSMiterLineJoinStyle];
        [outline setLineWidth:lineWidth];
        
        [outline moveToPoint:NSMakePoint(swatchRect.origin.x - 0.5f,
                            swatchRect.origin.y - 0.5f)];
                            
        [outline lineToPoint:NSMakePoint(swatchRect.origin.x - 0.5f, 
                            swatchRect.origin.y + swatchRect.size.height + 1.0f)];
                            
        [outline lineToPoint:NSMakePoint(swatchRect.origin.x + SWATCH_SIZE * 0.5f, 
                            swatchRect.origin.y + swatchRect.size.height + SWATCH_SIZE * 0.5f + 0.5f)];
                            
        [outline lineToPoint:NSMakePoint(swatchRect.origin.x  + SWATCH_SIZE  + 0.5f, 
                                swatchRect.origin.y + swatchRect.size.height + 1.0f)];
                                
        [outline lineToPoint:NSMakePoint(swatchRect.origin.x  + SWATCH_SIZE + 0.5f, 
                                swatchRect.origin.y - 0.5f)];
        [outline closePath];
                                
        [_swatchBorderColor set];
        [outline stroke];
        
        if(i == 0)
        {
            NSBezierPath* triangle = [NSBezierPath bezierPath];
                                
            [triangle moveToPoint:NSMakePoint(swatchRect.origin.x - 0.5f, 
                                swatchRect.origin.y + swatchRect.size.height)];
                                
            [triangle lineToPoint:NSMakePoint(swatchRect.origin.x + SWATCH_SIZE * 0.5f, 
                                swatchRect.origin.y + swatchRect.size.height + SWATCH_SIZE * 0.5f + 0.5f)];
                                
            [triangle lineToPoint:NSMakePoint(swatchRect.origin.x  + SWATCH_SIZE  + 0.5f, 
                                    swatchRect.origin.y + swatchRect.size.height)];
            [triangle closePath];
                                    
            [triangle fill];
            
            NSBezierPath* divider = [NSBezierPath bezierPath];
            [divider moveToPoint:NSMakePoint(swatchRect.origin.x + 0.5f, 
                                swatchRect.origin.y + swatchRect.size.height + 0.0f)];
            [divider lineToPoint:NSMakePoint(swatchRect.origin.x + SWATCH_SIZE  - 0.5f, 
                                swatchRect.origin.y + swatchRect.size.height + 0.0f)];
            [_inverseBackgroundBorderColor set];
            [divider stroke];
        }
        else
        {
        
        }
    }
    
    [_backgroundBorderColor set];
    
    borderRect = NSMakeRect( gradientRect.origin.x + 0.5f, gradientRect.origin.y +0.5f, 
                        gradientRect.size.width - 1.0f, gradientRect.size.height - 1.0f);
    backgroundPath = [NSBezierPath bezierPathWithRect:borderRect];
    [backgroundPath setLineJoinStyle:NSMiterLineJoinStyle];
    [backgroundPath setLineWidth:1.0f];
    [backgroundPath stroke];
    
    [_swatchRects release];
    _swatchRects = [swatchRects copy];
}

- (void)setColorPanelToColor:(NSColor*)color
{
    NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
    _ignoreColorPanelActions = YES;
    [colorPanel setColor:color];
    _ignoreColorPanelActions = NO;
}

- (void)addColor:(NSColor*)color ifWithinBoundsAtPoint:(NSPoint)localPoint
{
    NSRect addRect = _gradientRect;
    addRect.origin.y = _bottomOffset - 2.0f;
    addRect.size.height = (SWATCH_SIZE * 1.5f) + 2.0f;
    if(NSPointInRect(localPoint, addRect))
    {
        float newSwatchPosition = localPoint.x;
        float newSwatchFraction = ((newSwatchPosition - _gradientRect.origin.x)) / _gradientRect.size.width;
        if(newSwatchFraction > 0.0f && newSwatchFraction < 1.0f)
        {
            if(!color)
            {
                color = [_fngradient NSColorForFraction:newSwatchFraction];
            }
            FNGradient* newGradient = [_fngradient gradientByAddingColor:color forFraction:newSwatchFraction];
            [_fngradient release];
            _fngradient = [newGradient retain];
            [self updateDeleteButton];
            _swatchClicked = YES;
            [_target performSelector:_action withObject:self];
            [self setNeedsDisplay:YES];
        }
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
 
    if ([[pboard types] containsObject:NSColorPboardType] ) 
    {
        if (sourceDragMask & NSDragOperationGeneric) 
        {
            return NSDragOperationGeneric;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
 
    if ( [[pboard types] containsObject:NSColorPboardType] ) 
    {
        NSPoint location = [sender draggingLocation];
        NSPoint localPoint = [self convertPoint:location fromView:nil];
        BOOL found = NO;
        NSColor *newColor = [NSColor colorFromPasteboard:pboard];
        
        if(_swatchRects && [_swatchRects count] > 0)
        {
            unsigned int i = 0;
            unsigned int foundIndex = 0;
            for(i = 0; i < [_swatchRects count]; i++)
            {
                NSRect rect = [[_swatchRects objectAtIndex:i] rectValue];
                if(NSPointInRect(localPoint, rect))
                {
                    found = YES;
                    foundIndex = i;
                    break;
                }
            }
            
            if(found)
            {
                FNGradient* newGradient = [_fngradient gradientBySettingColor:newColor atIndex:foundIndex];
                [_fngradient release];
                _fngradient = [newGradient retain];
                [_target performSelector:_action withObject:self];
                [self setNeedsDisplay:YES];
            }
        }
        
        if(!found)
        {
            [self addColor:newColor ifWithinBoundsAtPoint:localPoint];
        }
    }
    return YES;
}

- (void)mouseDown:(NSEvent*)event
{
    if(![self isEnabled])
    {
        return;
    }
    _dragging = NO;
    BOOL found = NO;
    NSPoint windowLocation = [event locationInWindow];
    NSPoint localPoint = [self convertPoint:windowLocation fromView:nil];
    
    if(_swatchRects && [_swatchRects count] > 0)
    {
        unsigned int i = 0;
        unsigned int foundIndex = 0;
        NSRect foundRect;
        for(i = 0; i < [_swatchRects count]; i++)
        {
            NSRect rect = [[_swatchRects objectAtIndex:i] rectValue];
            if(NSPointInRect(localPoint, rect))
            {
                found = YES;
                foundIndex = i;
                foundRect = rect;
                break;
            }
        }
        
        if(found)
        {
            _mouseDownXOffsetFromSwatchCenter = localPoint.x - foundRect.origin.x - foundRect.size.width * 0.5f;
            
            FNGradient* newGradient;
            if([event modifierFlags] & NSAlternateKeyMask)
            {
                float newSwatchFraction = (localPoint.x - _gradientRect.origin.x) / _gradientRect.size.width;
                NSColor* color = [_fngradient NSColorForIndex:foundIndex];
                newGradient = [_fngradient gradientByAddingColor:color forFraction:newSwatchFraction];
            }
            else
            {
                newGradient = [_fngradient gradientByPrioritizingIndex:foundIndex];
            }
            
            [_fngradient release];
            _fngradient = [newGradient retain];
            [self takeOwnershipOfColorPanel];
            [self updateDeleteButton];
            _swatchClicked = YES;
            [self setNeedsDisplay:YES];
        }
    }
    
    if(!found)
    {
        [self addColor:nil ifWithinBoundsAtPoint:localPoint];
    }
}

- (void)takeOwnershipOfColorPanel
{
    NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setContinuous:YES];
    [colorPanel setTarget:self];
    [colorPanel setAction:@selector(colorPanelChanged:)];
    [colorPanel setShowsAlpha:YES];
    
    NSDictionary* colorDict = [[_fngradient colors] objectAtIndex:0];
    [self setColorPanelToColor:[colorDict objectForKey:@"color"]];
}

- (void)mouseUp:(NSEvent*)event
{
    if(!_dragging)
    {
        if(_swatchClicked)
        {
            [self takeOwnershipOfColorPanel];
            [[NSColorPanel sharedColorPanel] orderFront:self];
        }
    }
    else
    {
        _dragging = NO;
        [_target performSelector:_action withObject:self];
        [self setNeedsDisplay:YES];
    }
    _swatchClicked = NO;
}

- (void)mouseDragged:(NSEvent*)event
{    
    if(![self isEnabled])
    {
        return;
    }
    _dragging = YES;
    if(_swatchClicked)
    {
        NSPoint windowLocation = [event locationInWindow];
        NSPoint localPoint = [self convertPoint:windowLocation fromView:nil];
        float newSwatchPosition = localPoint.x - _mouseDownXOffsetFromSwatchCenter;
        float newSwatchFraction = (newSwatchPosition - _gradientRect.origin.x) / _gradientRect.size.width;
        newSwatchFraction = newSwatchFraction < 0.0f ? 0.0f : (newSwatchFraction > 1.0f ? 1.0f : newSwatchFraction);
        
        FNGradient* newGradient = [_fngradient gradientBySettingFraction:newSwatchFraction atIndex:0];
        
        [_fngradient release];
        _fngradient = [newGradient retain];
        [self updateDeleteButton];
        
    }
    [_target performSelector:_action withObject:self];
    [self setNeedsDisplay:YES];
}

- (void)colorPanelChanged:(id)sender
{
    if(!_ignoreColorPanelActions)
    {
        NSColor* color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        
        FNGradient* newGradient = [_fngradient gradientBySettingColor:color atIndex:0];
        [_fngradient release];
        _fngradient = [newGradient retain];
        [self updateDeleteButton];
        
        [_target performSelector:_action withObject:self];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)setEnabled:(BOOL)enabled
{
    NSArray* subViews = [self subviews];
    unsigned int i;
    for(i = 0; i < [subViews count]; i++)
    {
        NSView* subview = [subViews objectAtIndex:i];
        if([subview isKindOfClass:[NSControl class]])
        {
            [(NSControl*)subview setEnabled:enabled];
        }
    }
    
    [super setEnabled:enabled];
}

- (void)deleteButtonClicked:(id)sender
{
    FNGradient* newGradient = [_fngradient gradientByDeletingColorAtIndex:0];
    [_fngradient release];
    _fngradient = [newGradient retain];
    [self updateDeleteButton];
    
    NSDictionary* colorDict = [[_fngradient colors] objectAtIndex:0];
    [self setColorPanelToColor:[colorDict objectForKey:@"color"]];
    
    if([[_fngradient colors] count] <= 1)
    {
        [_deleteButton setEnabled:NO];
    }
    
    [_target performSelector:_action withObject:self];
    [self setNeedsDisplay:YES];
}

- (BOOL)dragging
{
    return _dragging;
}

- (void)dealloc
{
    [_fngradient release];
    [_backgroundBorderColor release];
    [_swatchBorderColor release];
    [_inverseBackgroundBorderColor release];
    [_gridFilter release];
    [_swatchRects release];
    [_percentageTextLabel release];
    [_deleteButton release];
    [_addSwatchTrackingArea release];
    [super dealloc];
}

@end
