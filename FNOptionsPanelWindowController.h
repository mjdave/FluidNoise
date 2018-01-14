
#import <Cocoa/Cocoa.h>

@class FNModel;
@class FNTextField;
@class FNTextLabel;
@class FNSlider;
@class FNButton;
@class FNGradientWell;
@class FNOptionsPanel;

@interface FNOptionsPanelWindowController : NSWindowController {

    FNModel* _model;
    
    IBOutlet FNTextField* _widthTextField;
    IBOutlet FNTextField* _heightTextField;
    
    IBOutlet FNSlider* _octavesSlider;
    IBOutlet FNTextLabel* _octavesTextLabel;
    
    IBOutlet FNSlider* _xFrequencySlider;
    IBOutlet FNTextLabel* _xFrequencyTextField;
    
    IBOutlet FNSlider* _yFrequencySlider;
    IBOutlet FNTextLabel* _yFrequencyTextField;
    
    IBOutlet FNSlider* _persistanceSlider;
    IBOutlet FNTextField* _persistanceTextField;
    
    IBOutlet FNSlider* _amplitudeSlider;
    IBOutlet FNTextField* _amplitudeTextField;
    
    IBOutlet FNTextField* _seedTextField;
    IBOutlet FNButton* _randomSeedButton;
    
    IBOutlet NSMatrix* _outputRadioButtons;
    IBOutlet NSTabView* _outputTabView;
    
    //gradient
    IBOutlet FNGradientWell* _gradientWell;
    
    //normal map
    IBOutlet FNSlider* _nmHeightScaleSlider;
    IBOutlet FNTextField* _nmHeightScaleTextField;
    
    //environment map
    IBOutlet FNSlider* _emHeightScaleSlider;
    IBOutlet FNTextField* _emHeightScaleTextField;
    IBOutlet FNTextLabel* _emFileNameTextField;
    
    //image distortion
    IBOutlet FNSlider* _imdHeightScaleSlider;
    IBOutlet FNTextField* _imdHeightScaleTextField;
    IBOutlet FNTextLabel* _imdFileNameTextField;
    
    IBOutlet FNButton* _tileCheckBox;
    IBOutlet FNButton* _loopCheckBox;
    
    IBOutlet FNTextField* _animationDurationTextField;
    IBOutlet FNSlider* _zFrequencySlider;
    IBOutlet FNTextLabel* _zFrequencyTextField;
    IBOutlet FNButton* _animatePreviewButton;
    
    NSNotificationQueue* _sliderFinishedEditingNotificationQueue;
    
    id _customObjectOldValue;
}

- (void)setModel:(FNModel*)model;
- (void)setControlsToModelValues;
- (IBAction)valueChanged:(id)sender;
- (IBAction)chooseEMFile:(id)sender;
- (IBAction)chooseIMDFile:(id)sender;
- (void)updateColorPanel;

- (void)disableControls;
- (void)enableControls;

- (void)updateAnimationButtonTitle;

@end
