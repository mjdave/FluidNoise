
#import "FNTextField.h"
//#import "OSCheck.h"
#import "FNTextFieldCell.h"

@implementation FNTextField

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if(!self) 
    {
        return nil;
    }
    
    return self;
}

/*+ (Class)cellClass
{
    if(isLeopardOrAbove())
    {
        return [FNTextFieldCell class];
    }
    
    return [NSTextFieldCell class];
}*/

- (void)awakeFromNib
{
    if(![self isEditable])
    {
        [self setTextColor:[NSColor blackColor]];
    }
    /*else if(isLeopardOrAbove() && [self isEditable])
    {
        [self setBackgroundColor:[NSColor colorWithCalibratedRed:0.33f 
                            green:0.33f
                            blue:0.33f 
                            alpha:0.77f]];
                            
       // [self setTextColor:[NSColor blackColor]];
        [self setTextColor:[NSColor whiteColor]];
        //[[self cell] setBorderType:NSLineBorder];// hangs why ?
        [self setDrawsBackground:NO];
       
    }*/
    
}

/*- (void)drawRect:(NSRect)rect
{
    if([self isEditable])
    {
        if(isLeopardOrAbove())
        {
            NSRect rectToDraw = [self bounds];
            [[NSColor colorWithCalibratedRed:0.4f 
                                green:0.4f
                                blue:0.4f 
                                alpha:0.67f] set];
            NSBezierPath* fillPath = [NSBezierPath bezierPathWithRect:rectToDraw];
            [fillPath fill];
        

            
            NSBezierPath* linePath = [NSBezierPath bezierPath];
            [linePath moveToPoint:NSMakePoint(rectToDraw.origin.x + 1.0f, rectToDraw.origin.y + rectToDraw.size.height - 1.5f)];
            [linePath lineToPoint:NSMakePoint(rectToDraw.origin.x + rectToDraw.size.width -0.5f, rectToDraw.origin.y + rectToDraw.size.height - 1.5f)];
            [[NSColor colorWithCalibratedRed:0.4f 
                                green:0.4f
                                blue:0.4f 
                                alpha:0.67f] set];
            [linePath stroke];
            
            linePath = [NSBezierPath bezierPath];
            [linePath moveToPoint:NSMakePoint(rectToDraw.origin.x + rectToDraw.size.width -0.5f, rectToDraw.origin.y + 1.5f)];
            [linePath lineToPoint:NSMakePoint(rectToDraw.origin.x + 0.5f, rectToDraw.origin.y + 1.5f)];
           // [linePath lineToPoint:NSMakePoint(rectToDraw.origin.x + 0.5f, rectToDraw.origin.y + rectToDraw.size.height - 1.0f)];
            [[NSColor colorWithCalibratedRed:0.0f 
                                green:0.0f
                                blue:0.0f 
                                alpha:0.27f] set];
            [linePath stroke];
            
        }
    }
    [super drawRect:(NSRect)rect];
}*/

@end
