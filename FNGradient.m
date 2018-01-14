
#import "FNGradient.h"
    
#define MJ_EPSILON 0.00001f
#define approx_equal(a, b) (fabsf((float)(a-b)) < MJ_EPSILON)

#define grad_dict(r,g,b,a,x) \
    [NSDictionary dictionaryWithObjectsAndKeys:\
                [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a],  @"color",\
                [NSNumber numberWithFloat:x],                           @"fraction",\
            nil]
            
#define grad_dict_col(col,x) \
    [NSDictionary dictionaryWithObjectsAndKeys:\
                col,  @"color",\
                [NSNumber numberWithFloat:x],                           @"fraction",\
            nil]


//static const float input_value_range   [2] = { 0, 1 };
//static const float output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };

@implementation FNGradient


- (void)createOptimizedColorsFromColors
{
    _numberOfOptimizedColors = 0;
    unsigned int i;
    if(_optimizedColors)
    {
        free(_optimizedColors);
    }
    
    NSMutableArray* colorsToAdd = [NSMutableArray array];
    
    for(i = 0; i < [_colors count]; i++)
    {
        NSDictionary* colorDict = [_colors objectAtIndex:i];
        float fraction = [[colorDict objectForKey:@"fraction"] floatValue];
        unsigned int j;
        unsigned int matchCount = 0;
        for(j = 0; j < [colorsToAdd count]; j++)
        {
            NSDictionary* prevColorDict = [colorsToAdd objectAtIndex:j];
            float prevFraction = [[prevColorDict objectForKey:@"fraction"] floatValue];
            if(approx_equal(prevFraction, fraction))
            {
                matchCount++;
            }
        }
        
        if(matchCount > 0 && (fraction < MJ_EPSILON || fraction > (1.0f - MJ_EPSILON)))
        {
            continue;
        }
        
        if(matchCount > 1)
        {
            continue;
        }
        
        [colorsToAdd addObject:colorDict];
    }
    _numberOfOptimizedColors = (unsigned int)[colorsToAdd count];
    
    _isOpaque = YES;
    
    _optimizedColors = malloc(sizeof(ColorFraction*) * _numberOfOptimizedColors);
    for(i = 0; i < _numberOfOptimizedColors; i++)
    {
        NSDictionary* colorDict = [colorsToAdd objectAtIndex:i];
        ColorFraction* colorFractionStruct = malloc(sizeof(ColorFraction));
        colorFractionStruct->color = colorFromNSColor([colorDict objectForKey:@"color"]);
        colorFractionStruct->fraction = [[colorDict objectForKey:@"fraction"] floatValue];
        _optimizedColors[i] = colorFractionStruct;
        if(colorFractionStruct->color.a < 0.99999f)
        {
            _isOpaque = NO;
        }
    }
}

- (id)initWithColorAndFractionArray:(NSArray*)colors
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    _colors = [colors copy];
    [self createOptimizedColorsFromColors];
    
    return self;
}

+ (FNGradient*)gradientWithColorAndFractionArray:(NSArray*)colors
{
    return [[[FNGradient alloc] initWithColorAndFractionArray:colors] autorelease];
}

- (FNGradient*)gradientByAddingColor:(NSColor*)color forFraction:(float)fraction
{
    NSMutableArray* newColors = [NSMutableArray arrayWithArray:_colors];
    NSDictionary* colorDict = grad_dict_col(color, fraction);
    [newColors insertObject:colorDict atIndex:0];
    return [FNGradient gradientWithColorAndFractionArray:newColors];
}

- (FNGradient*)gradientBySettingColor:(NSColor*)color atIndex:(unsigned int)index
{
    NSMutableArray* newColors = [NSMutableArray arrayWithArray:_colors];
    
    NSDictionary* oldColorDict = [_colors objectAtIndex:index];
    NSDictionary* newColorDict = grad_dict_col(color, [[oldColorDict objectForKey:@"fraction"] floatValue]);
    
    [newColors replaceObjectAtIndex:index withObject:newColorDict];
    
    return [FNGradient gradientWithColorAndFractionArray:newColors];
}

- (FNGradient*)gradientBySettingFraction:(float)fraction atIndex:(unsigned int)index
{
    NSMutableArray* newColors = [NSMutableArray arrayWithArray:_colors];
    NSDictionary* oldColorDict = [_colors objectAtIndex:index];
    NSDictionary* newColorDict = grad_dict_col([oldColorDict objectForKey:@"color"], fraction);
    
    [newColors replaceObjectAtIndex:index withObject:newColorDict];
    
    return [FNGradient gradientWithColorAndFractionArray:newColors];
}

- (FNGradient*)gradientByPrioritizingIndex:(unsigned int)index
{
    NSMutableArray* newColors = [NSMutableArray arrayWithArray:_colors];
    NSDictionary* colorDict = [_colors objectAtIndex:index];
    [newColors removeObjectAtIndex:index];
    [newColors insertObject:colorDict atIndex:0];
    
    return [FNGradient gradientWithColorAndFractionArray:newColors];
}

- (FNGradient*)gradientByDeletingColorAtIndex:(unsigned int)index
{
    NSMutableArray* newColors = [NSMutableArray arrayWithArray:_colors];
    [newColors removeObjectAtIndex:index];
    
    return [FNGradient gradientWithColorAndFractionArray:newColors];
}


+ (FNGradient*)rainbowGradient
{
    NSArray* colorArray = [NSArray arrayWithObjects:
            grad_dict(0.0f, 1.0f, 0.0f, 1.0f, 0.5f),
            grad_dict(1.0f, 0.0f, 1.0f, 1.0f, 0.0f),
            grad_dict(1.0f, 0.0f, 0.0f, 1.0f, 0.167f),
            grad_dict(1.0f, 1.0f, 0.0f, 1.0f, 0.333f),
            grad_dict(0.0f, 1.0f, 1.0f, 1.0f, 0.667f),
            grad_dict(0.0f, 0.0f, 1.0f, 1.0f, 0.833f),
            grad_dict(1.0f, 0.0f, 1.0f, 1.0f, 1.0f),
        nil];
    
    return [FNGradient gradientWithColorAndFractionArray:colorArray];
}

+ (FNGradient*)landscapeGradient
{
    NSArray* colorArray = [NSArray arrayWithObjects:
            grad_dict(0.057f,   0.12f,  0.26f, 1.0f, 0.0f),
            grad_dict(0.0f,     0.2f,   0.45f, 1.0f, 0.15f),
            grad_dict(0.37f,    0.8f,   0.78f, 1.0f, 0.451f),
            grad_dict(0.37f,    0.38f,  0.29f, 1.0f, 0.455f),
            grad_dict(0.6f,     0.6f,   0.41f, 1.0f, 0.467f),
            grad_dict(0.0f,     0.34f,  0.03f, 1.0f, 0.48f),
            grad_dict(0.21f,    0.41f,  0.18f, 1.0f, 0.605f),
            grad_dict(0.65f,    0.51f,  0.17f, 1.0f, 0.65f),
            grad_dict(1.0f,     1.0f,   1.0f,  1.0f, 0.71f),
        nil];
    
    return [FNGradient gradientWithColorAndFractionArray:colorArray];
}

+ (FNGradient*)blackWhiteRampGradient
{
    NSArray* colorArray = [NSArray arrayWithObjects:
            grad_dict(0.0f, 0.0f, 0.0f, 1.0f, 0.0f),
            grad_dict(1.0f, 1.0f, 1.0f, 1.0f, 1.0f),
        nil];
    
    return [FNGradient gradientWithColorAndFractionArray:colorArray];
}

+ (FNGradient*)defaultRampGradient
{
    NSArray* colorArray = [NSArray arrayWithObjects:
            grad_dict(0.0f, 0.0f, 0.0f, 1.0f, 0.0f),
            grad_dict(0.0f, 1.0f, 1.0f, 1.0f, 1.0f),
        nil];
    
    return [FNGradient gradientWithColorAndFractionArray:colorArray];
}

+ (FNGradient*)simpleLandscapeGradient
{
    NSArray* colorArray = [NSArray arrayWithObjects:
            grad_dict(0.364998, 0.698980, 0.683804, 1.0f, 0.513672),
            grad_dict(0.959028, 0.976994, 1.000000, 1.0f, 0.732422),
            grad_dict(0.000000, 0.163265, 0.005644, 1.0f, 0.556641),
            grad_dict(0.000000, 0.596807, 0.704082, 1.0f, 0.470703),
            grad_dict( 0.000000, 0.494898, 0.005197, 1.0f, 0.658203),
            grad_dict(0.000000, 0.000000, 0.000000, 1.0f, 0.000000),
        nil];
    return [FNGradient gradientWithColorAndFractionArray:colorArray];
}

+ (FNGradient*)reflectionGradient
{
    NSArray* colorArray = [NSArray arrayWithObjects:
            grad_dict(0.56f,0.41f,0.0f,1.0f, 0.52f),
            grad_dict(0.16f,0.54f,0.8f,1.0f, 0.0f),
            grad_dict(1.0f,1.0f,1.0f,1.0f, 0.5f),
            grad_dict(0.85f,0.62f,0.0f,1.0f, 0.64f),
            grad_dict(1.0f,1.0f,1.0f,1.0f, 1.0f),
        nil];
    
    return [FNGradient gradientWithColorAndFractionArray:colorArray];
}


+ (FNGradient*)defaultGradient
{
    return [FNGradient simpleLandscapeGradient];
}

- (Color)colorForFraction:(float)fraction
{
    int numberOfColors = _numberOfOptimizedColors;
    if(numberOfColors < 2)
    {
        if(numberOfColors == 0)
        {
            return makeColor(fraction,fraction,fraction,fraction);
        }
        else
        {
            return _optimizedColors[0]->color;
        }
    }
    
    unsigned int lowerIndex = 0;
    float lowerFraction = fraction - 1.1f;
    unsigned int upperIndex = numberOfColors - 1;
    float upperFraction = fraction + 1.1f;
    
    float lowestFraction = 1.0f;
    float highestFraction = 0.0f;
    unsigned int lowestIndex = 0;
    unsigned int highestIndex = 0;
    
    unsigned int i = 0;
    for(i = 0; i < numberOfColors; i++)
    {
        float thisFraction = _optimizedColors[i]->fraction;
        if(thisFraction <= (fraction + MJ_EPSILON) && lowerFraction < (thisFraction - MJ_EPSILON))
        {
            lowerFraction = thisFraction;
            lowerIndex = i;
        }
        else if(thisFraction >= (fraction - MJ_EPSILON) && upperFraction > (thisFraction - MJ_EPSILON))
        {
            upperFraction = thisFraction;
            upperIndex = i;
        }
        
        if(thisFraction < (lowestFraction - MJ_EPSILON))
        {
            lowestFraction = thisFraction;
            lowestIndex = i;
        }
        if(thisFraction > (highestFraction + MJ_EPSILON))
        {
            highestFraction = thisFraction;
            highestIndex = i;
        }
    }
    
    if(fraction > highestFraction)
    {
        return _optimizedColors[highestIndex]->color;
    }
    
    if(fraction < lowestFraction)
    {
        return _optimizedColors[lowestIndex]->color;    
    }
    
    float lerpFraction = (fraction - lowerFraction) / (upperFraction - lowerFraction);
    Color lerpedColorVal = lerpedColor(_optimizedColors[lowerIndex]->color, _optimizedColors[upperIndex]->color, lerpFraction);
    return lerpedColorVal;
}

- (NSColor*)NSColorForFraction:(float)fraction
{
    Color color = [self colorForFraction:fraction];
    return NSColorFromColor(color);
}

- (NSColor*)NSColorForIndex:(unsigned int)index
{
    NSDictionary* colorDict = [_colors objectAtIndex:index];
    return [[[colorDict objectForKey:@"color"] copy] autorelease];
}

- (void)fillRect:(NSRect)rect
{
    size_t numLocations = [_colors count];
    CGFloat* locations = malloc(sizeof(CGFloat) * numLocations);
    CGFloat* components = malloc(sizeof(CGFloat) * numLocations * 4);
    
    unsigned int i = 0;
    for(i = 0; i < numLocations; i++)
    {
        NSDictionary* spot = [_colors objectAtIndex:i];
        locations[i] = [[spot objectForKey:@"fraction"] floatValue];
        if(i > 0 && approx_equal(locations[i], locations[i - 1]))
        {
            components[i * 4 + 0] = components[(i - 1) * 4 + 0];
            components[i * 4 + 1] = components[(i - 1) * 4 + 1];
            components[i * 4 + 2] = components[(i - 1) * 4 + 2];
            components[i * 4 + 3] = components[(i - 1) * 4 + 3];
        }
        else
        {
            NSColor* spotColor = [spot objectForKey:@"color"];
            components[i * 4 + 0] = [spotColor redComponent];
            components[i * 4 + 1] = [spotColor greenComponent];
            components[i * 4 + 2] = [spotColor blueComponent];
            components[i * 4 + 3] = [spotColor alphaComponent];
        }
    }
     
    CGColorSpaceRef myColorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGGradientRef myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
                              locations, numLocations);
    CGContextRef contextRef = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
                              
    CGPoint myStartPoint, myEndPoint;
    myStartPoint.x = rect.origin.x;
    myStartPoint.y = rect.size.height * 0.5 + rect.origin.y;
    
    myEndPoint.x = rect.size.width + rect.origin.x;
    myEndPoint.y = rect.size.height * 0.5 + rect.origin.y;
    
    CGContextSaveGState(contextRef);
    CGContextClipToRect (contextRef, *(CGRect *)&rect);
    CGContextDrawLinearGradient (contextRef, myGradient, myStartPoint, myEndPoint, 0);
    CGContextRestoreGState(contextRef);
    
    CGGradientRelease(myGradient);
    free(locations);
    free(components);

}

- (unsigned int)numberOfColors
{
    return (unsigned int)[_colors count];
}

- (NSArray*)colors
{
    return [[_colors copy] autorelease];
}

- (BOOL)isOpaque
{
    return _isOpaque;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        [coder encodeObject:_colors forKey:@"colors"];
    } else {
        [coder encodeObject:_colors];
    }
}
 
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if ( [coder allowsKeyedCoding] ) {
        _colors = [[coder decodeObjectForKey:@"colors"] copy];
    } else {
        _colors = [[coder decodeObject] copy];
    }
    [self createOptimizedColorsFromColors];
    return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
    FNGradient* gradient = [[FNGradient gradientWithColorAndFractionArray:_colors] retain];
    return gradient;
}

- (void)dealloc
{
    if(_optimizedColors)
    {
        unsigned int i;
        for(i = 0; i < _numberOfOptimizedColors; i++)
        {
            free(_optimizedColors[i]);
        }
        free(_optimizedColors);
    }
    [_colors release];
      
    [super dealloc];
}

@end
