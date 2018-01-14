
#import <Cocoa/Cocoa.h>

@class FNGradient;
@class FNTextLabel;
@class FNButton;
@class CIFilter;

@interface FNGradientWell : NSControl {
    FNGradient* _fngradient;
    
    id _target;
    SEL _action;
    
    BOOL _dragging;
    float _mouseDownXOffsetFromSwatchCenter;
    BOOL _swatchClicked;
    
    NSArray* _swatchRects;
    NSRect _gradientRect;
    
    NSColor* _backgroundBorderColor;
    NSColor* _inverseBackgroundBorderColor;
    NSColor* _swatchBorderColor;
    
    FNTextLabel* _percentageTextLabel;
    FNButton* _deleteButton;
    float _bottomOffset;
    
    BOOL _ignoreColorPanelActions; // thankyou NSColorPanel for making me add this hack by acting like Qt
    
    CIFilter* _gridFilter;
    
    NSTrackingArea* _addSwatchTrackingArea;
}

- (void)setGradient:(FNGradient*)gradient;
- (FNGradient*)gradient;

- (void)setTarget:(id)target;
- (void)setAction:(SEL)action;

- (id)objectValue;

- (BOOL)dragging;

- (void)takeOwnershipOfColorPanel;

@end
