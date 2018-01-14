#import <Cocoa/Cocoa.h>

#define lerpf(a,b,x) ((b) * (x) + (a) * (1.0f - (x)))

typedef struct Color
{
    float r;
    float g;
    float b;
    float a;
} Color;

static inline Color makeColor(float r, float g, float b, float a)
{
    Color color;
    color.r = r;
    color.g = g;
    color.b = b;
    color.a = a;
    return color;
}

static inline Color colorFromNSColor(NSColor* color)
{
    NSColor* rgbColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    return makeColor([rgbColor redComponent], [rgbColor greenComponent], [rgbColor blueComponent], [rgbColor alphaComponent]);
}

static inline NSColor* NSColorFromColor(Color color)
{
    NSColor* result = [NSColor colorWithCalibratedRed:color.r
                    green:color.g 
                    blue:color.b
                    alpha:color.a];
    return result;
}

static inline Color lerpedColor(Color a, Color b, float x)
{
    float f = x > 1.0f ? 1.0f : (x < 0.0f ? 0.0f : x);
    return makeColor(lerpf(a.r, b.r, f),
                     lerpf(a.g, b.g, f),
                     lerpf(a.b, b.b, f),
                     lerpf(a.a, b.a, f));
}

