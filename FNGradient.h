

#import <Cocoa/Cocoa.h>

#import "Color.h"

typedef struct ColorFraction {
    Color color;
    float fraction;
} ColorFraction;

@interface FNGradient : NSObject {
    NSArray* _colors;
    ColorFraction** _optimizedColors;
    unsigned int _numberOfOptimizedColors;
    BOOL _isOpaque;
}

- (id)initWithColorAndFractionArray:(NSArray*)colors;

+ (FNGradient*)defaultGradient;
+ (FNGradient*)gradientWithColorAndFractionArray:(NSArray*)colors;

- (FNGradient*)gradientByAddingColor:(NSColor*)color forFraction:(float)fraction;
- (FNGradient*)gradientByPrioritizingIndex:(unsigned int)index;
- (FNGradient*)gradientByDeletingColorAtIndex:(unsigned int)index;

- (FNGradient*)gradientBySettingColor:(NSColor*)color atIndex:(unsigned int)index;
- (FNGradient*)gradientBySettingFraction:(float)fraction atIndex:(unsigned int)index;

- (void)fillRect:(NSRect)rect;

- (NSArray*)colors;
- (unsigned int)numberOfColors;
- (Color)colorForFraction:(float)fraction;
- (NSColor*)NSColorForFraction:(float)fraction;
- (NSColor*)NSColorForIndex:(unsigned int)index;
- (BOOL)isOpaque;

//- (unsigned int)addColor:(NSColor*)color forFraction:(float)fraction;
//- (void)setColor:(NSColor*)color atIndex:(unsigned int)index;
//- (unsigned int)setFraction:(float)fraction atIndex:(unsigned int)index;

@end
