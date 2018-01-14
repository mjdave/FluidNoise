

#import "FNHorizontalDivider.h"


@implementation FNHorizontalDivider

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if(!self)
    {
        return nil;
    }
    
    return self;
}

- (void)drawRect:(NSRect)frame
{
    float originY = [self frame].size.height * 0.5f;
    
    NSBezierPath* line = [NSBezierPath bezierPath];
    [line setLineJoinStyle:NSMiterLineJoinStyle];
    [line setLineWidth:1.0f];
    
    [line moveToPoint:NSMakePoint(frame.origin.x - 0.5f,
                        originY)];
                        
    [line lineToPoint:NSMakePoint(frame.origin.x + frame.size.width + 0.5f, 
                        originY)];
                        
    [[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:0.5f] set];
    [line stroke];
}

@end
