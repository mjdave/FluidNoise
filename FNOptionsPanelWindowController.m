

#import "FNOptionsPanelWindowController.h"

#import "MyDocument.h"
#import "FNModel.h"
#import "FNGradientWell.h"

@implementation FNOptionsPanelWindowController

- (id)initWithWindowNibName:(NSString*)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if(!self)
    {
        return nil;
    }
    
    [self setShouldCascadeWindows:NO];
    
    _sliderFinishedEditingNotificationQueue = [[NSNotificationQueue alloc] initWithNotificationCenter:[NSNotificationCenter defaultCenter]];
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(sliderFinishedNotification:) name:@"SliderNotification" 
        object:nil];
        
    srand((unsigned int)time(NULL));
            
    return self;
}

- (void)setModel:(FNModel*)model
{
    _model = model;
}

- (void)updateColorPanel
{
    [_gradientWell takeOwnershipOfColorPanel];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self document] undoManager];
}

- (void)setTextLabel:(FNTextLabel*)label toPowerValue:(id)value
{
    int intValue = [value intValue];
    if(intValue >= 0)
    {
        [label setIntValue:1 << intValue];
    }
    else
    {
        [label setStringValue:[NSString stringWithFormat:@"1/%d", 1 << -intValue]];
    }
}

- (void)setControlsToModelValues
{
    [_widthTextField setObjectValue:[_model objectForKey:@"width"]];
    [_heightTextField setObjectValue:[_model objectForKey:@"height"]];
    
    [_octavesSlider setObjectValue:[_model objectForKey:@"octaves"]];
    [_octavesTextLabel setObjectValue:[_model objectForKey:@"octaves"]];
    
    
    int frequencyX = [[_model objectForKey:@"frequencyX"] intValue];
    [_xFrequencySlider setIntValue:frequencyX];
    [self setTextLabel:_xFrequencyTextField toPowerValue:[_model objectForKey:@"frequencyX"]];
    
    int frequencyY = [[_model objectForKey:@"frequencyY"] intValue];
    [_yFrequencySlider setIntValue:frequencyY];
    [self setTextLabel:_yFrequencyTextField toPowerValue:[_model objectForKey:@"frequencyY"]];
    
    [_persistanceSlider setObjectValue:[_model objectForKey:@"persistance"]];
    [_persistanceTextField setObjectValue:[_model objectForKey:@"persistance"]];
    
    [_amplitudeSlider setObjectValue:[_model objectForKey:@"amplitude"]];
    [_amplitudeTextField setObjectValue:[_model objectForKey:@"amplitude"]];
    
    [_seedTextField setObjectValue:[_model objectForKey:@"seed"]];
    
    [_outputRadioButtons selectCellAtRow:[[_model objectForKey:@"output"]intValue] column:0];
    [_outputTabView selectTabViewItemAtIndex:[[_model objectForKey:@"output"]intValue]];
    
    [_gradientWell setGradient:[_model objectForKey:@"gradient"]];
    [_gradientWell setTarget:self];
    [_gradientWell setAction:@selector(valueChanged:)];
    
    [_nmHeightScaleSlider setObjectValue:[_model objectForKey:@"normalMapHeightScale"]];
    [_nmHeightScaleTextField setObjectValue:[_model objectForKey:@"normalMapHeightScale"]];
    
    // environment map
    [_emHeightScaleSlider setObjectValue:[_model objectForKey:@"environmentMapHeightScale"]];
    [_emHeightScaleTextField setObjectValue:[_model objectForKey:@"environmentMapHeightScale"]];
    
    NSString* emFileName = [_model objectForKey:@"environmentMapFileName"];
    if(![emFileName isEqualToString:@"default"])
    {
        emFileName = [emFileName lastPathComponent];
    }
    [[_emFileNameTextField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [_emFileNameTextField setStringValue:emFileName];
    
    //distortion image
    [_imdHeightScaleSlider setObjectValue:[_model objectForKey:@"distortionImageHeightScale"]];
    [_imdHeightScaleTextField setObjectValue:[_model objectForKey:@"distortionImageHeightScale"]];
    
    NSString* imdFileName = [_model objectForKey:@"distortionImageFileName"];
    if(![imdFileName isEqualToString:@"default"])
    {
        imdFileName = [imdFileName lastPathComponent];
    }
    [[_imdFileNameTextField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [_imdFileNameTextField setStringValue:imdFileName];
    
    [_tileCheckBox setObjectValue:[_model objectForKey:@"tile"]];
    [_loopCheckBox setObjectValue:[_model objectForKey:@"loop"]];
    
    [_animationDurationTextField setObjectValue:[_model objectForKey:@"animationDuration"]];
    
    int frequencyZ = [[_model objectForKey:@"frequencyZ"] intValue];
    [_zFrequencySlider setIntValue:frequencyZ];
    [self setTextLabel:_zFrequencyTextField toPowerValue:[_model objectForKey:@"frequencyZ"]];
}

- (void)setValueWithUndo:(id)info updateViewRegardlessOfModelChange:(BOOL)updateViewRegardlessOfModelChange
{
    id value = [info objectForKey:@"value"];
    id key = [info objectForKey:@"key"];
    id actionName = [info objectForKey:@"action_name"];
    id oldValue = [info objectForKey:@"old_value"];
    
    NSUndoManager* undoManager = [[self document] undoManager];
    if([_model setObject:value forKey:key] || updateViewRegardlessOfModelChange)
    {
        NSDictionary* revertInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                        oldValue, @"value",
                                        value, @"old_value",
                                        key, @"key",
                                        actionName, @"action_name",
                                    nil];
        [undoManager setActionName:actionName];
        [undoManager registerUndoWithTarget:self selector:@selector(setValueWithUndo:) object:revertInfo];
        [self setControlsToModelValues];
        [(MyDocument*)[self document] updateView];
    }
}

- (void)setValueWithUndo:(id)info
{
    [self setValueWithUndo:info updateViewRegardlessOfModelChange:NO];
}

- (void)sliderFinishedNotification:(NSNotification*)notification
{
    NSDictionary* revertInfo = [notification object];
    
    id owner = [revertInfo objectForKey:@"owner"];
    if(owner != self)
    {
        return;
    }
    
    id newValue = [[revertInfo objectForKey:@"sender"] objectValue];
    id oldValue = [revertInfo objectForKey:@"old_value"];
    
    if(![newValue isEqual:oldValue])
    {
        NSDictionary* newInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                            newValue, @"value",
                                            oldValue, @"old_value",
                                            [revertInfo objectForKey:@"key"], @"key",
                                            [revertInfo objectForKey:@"action_name"], @"action_name",
                                        nil];
        [self setValueWithUndo:newInfo updateViewRegardlessOfModelChange:YES];
    }
}

- (void)setSliderDelayedValueWithUndo:(id)info
{
    [_sliderFinishedEditingNotificationQueue 
                enqueueNotification:[NSNotification notificationWithName:@"SliderNotification" object:info]
                postingStyle:NSPostWhenIdle
                coalesceMask:(NSNotificationCoalescingOnName)
                forModes:nil];
                
    id value = [[info objectForKey:@"sender"] objectValue];
    id key = [info objectForKey:@"key"];
    BOOL modelValueChanged = [_model setObject:value forKey:key];
    if(modelValueChanged)
    {
        [self setControlsToModelValues];
        [(MyDocument*)[self document] updateView];
    }
}

- (void)setCustomObjectDelayedValueWithUndo:(NSDictionary*)info
{
    BOOL createdOldValueThisEvent = NO;
    if(!_customObjectOldValue)
    {
        _customObjectOldValue = [[info objectForKey:@"old_value"] retain];
        createdOldValueThisEvent = YES;
    }
    
    id sender = [info objectForKey:@"sender"];
    
    if([sender dragging])
    {
        id value = [sender objectValue];
        id key = [info objectForKey:@"key"];
        BOOL modelValueChanged = [_model setObject:value forKey:key];
        if(modelValueChanged)
        {
            [self setControlsToModelValues];
            [(MyDocument*)[self document] updateView];
        }
    }
    else
    {
        id newValue = [[[sender objectValue] copy] autorelease];
        id oldValue = _customObjectOldValue;
        
        if(createdOldValueThisEvent || ![newValue isEqual:oldValue])
        {
            NSDictionary* newInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                newValue, @"value",
                                                oldValue, @"old_value",
                                                [info objectForKey:@"key"], @"key",
                                                [info objectForKey:@"action_name"], @"action_name",
                                            nil];
            [self setValueWithUndo:newInfo updateViewRegardlessOfModelChange:YES];
        }
        
        [_customObjectOldValue release];
        _customObjectOldValue = NULL;
    }
}

- (IBAction)chooseEMFile:(id)sender
{
    if(!_model)
    {
        return;
    }
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    NSArray* types = [NSImage imageFileTypes];
    int result = (int)[panel runModalForTypes:types];
    if(result == NSOKButton)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                [panel filename], @"value",
                                [[[_model objectForKey:@"environmentMapFileName"] retain] autorelease], @"old_value",
                                @"environmentMapFileName", @"key",
                                @"Change Environment Image", @"action_name",
            nil];
        [self setValueWithUndo:info];
    }
}

- (IBAction)chooseIMDFile:(id)sender
{
    if(!_model)
    {
        return;
    }
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    NSArray* types = [NSImage imageFileTypes];
    int result = (int)[panel runModalForTypes:types];
    if(result == NSOKButton)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                [panel filename], @"value",
                                [[[_model objectForKey:@"distortionImageFileName"] retain] autorelease], @"old_value",
                                @"distortionImageFileName", @"key",
                                @"Change Distortion Image", @"action_name",
            nil];
        [self setValueWithUndo:info];
    }
}

- (IBAction)valueChanged:(id)sender
{
    if(!_model)
    {
        return;
    }
    
    if(sender == _widthTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                [sender objectValue], @"value",
                                [[[_model objectForKey:@"width"] retain] autorelease], @"old_value",
                                @"width", @"key",
                                @"Change Width", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _heightTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                [sender objectValue], @"value",
                                [[[_model objectForKey:@"height"] retain] autorelease], @"old_value",
                                @"height", @"key",
                                @"Change Height", @"action_name",
                            nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _octavesSlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"octaves"] retain] autorelease], @"old_value",
                                    @"octaves", @"key",
                                    @"Change Octaves", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _xFrequencySlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"frequencyX"] retain] autorelease], @"old_value",
                                    @"frequencyX", @"key",
                                    @"Change X Zoom", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
        
    }
    else if(sender == _xFrequencyTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"frequencyX"] retain] autorelease], @"old_value",
                    @"frequencyX", @"key",
                    @"Change X Zoom", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _yFrequencySlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"frequencyY"] retain] autorelease], @"old_value",
                                    @"frequencyY", @"key",
                                    @"Change Y Zoom", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _yFrequencyTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"frequencyY"] retain] autorelease], @"old_value",
                    @"frequencyY", @"key",
                    @"Change Y Zoom", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _persistanceSlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"persistance"] retain] autorelease], @"old_value",
                                    @"persistance", @"key",
                                    @"Change Persistance", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _persistanceTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"persistance"] retain] autorelease], @"old_value",
                    @"persistance", @"key",
                    @"Change Persistance", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _amplitudeSlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"amplitude"] retain] autorelease], @"old_value",
                                    @"amplitude", @"key",
                                    @"Change Amplitude", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _amplitudeTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"amplitude"] retain] autorelease], @"old_value",
                    @"amplitude", @"key",
                    @"Change Amplitude", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _seedTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"seed"] retain] autorelease], @"old_value",
                    @"seed", @"key",
                    @"Change Seed", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _randomSeedButton)
    {
        int value = rand() % 99999999;
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:value], @"value",
                    [[[_model objectForKey:@"seed"] retain] autorelease], @"old_value",
                    @"seed", @"key",
                    @"Change Seed", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _outputRadioButtons)
    {
         NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:(int)[sender selectedRow]], @"value",
                    [[[_model objectForKey:@"output"] retain] autorelease], @"old_value",
                    @"output", @"key",
                    @"Change Output", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _gradientWell)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    sender, @"sender",
                                    [[[_model objectForKey:@"gradient"] retain] autorelease], @"old_value",
                                    @"gradient", @"key",
                                    @"Change Gradient", @"action_name",
                              nil];
        [self setCustomObjectDelayedValueWithUndo:info];
    }
    else if(sender == _nmHeightScaleSlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"normalMapHeightScale"] retain] autorelease], @"old_value",
                                    @"normalMapHeightScale", @"key",
                                    @"Change Height Scale", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _nmHeightScaleTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"normalMapHeightScale"] retain] autorelease], @"old_value",
                    @"normalMapHeightScale", @"key",
                    @"Change Height Scale", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _emHeightScaleSlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"environmentMapHeightScale"] retain] autorelease], @"old_value",
                                    @"environmentMapHeightScale", @"key",
                                    @"Change Height Scale", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _emHeightScaleTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"environmentMapHeightScale"] retain] autorelease], @"old_value",
                    @"environmentMapHeightScale", @"key",
                    @"Change Height Scale", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _imdHeightScaleSlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"distortionImageHeightScale"] retain] autorelease], @"old_value",
                                    @"distortionImageHeightScale", @"key",
                                    @"Change Height Scale", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _imdHeightScaleTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"distortionImageHeightScale"] retain] autorelease], @"old_value",
                    @"distortionImageHeightScale", @"key",
                    @"Change Height Scale", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _tileCheckBox)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"tile"] retain] autorelease], @"old_value",
                    @"tile", @"key",
                    @"Set Seamless Tiling", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _loopCheckBox)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"loop"] retain] autorelease], @"old_value",
                    @"loop", @"key",
                    @"Set Looping Animation", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _animationDurationTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"animationDuration"] retain] autorelease], @"old_value",
                    @"animationDuration", @"key",
                    @"Change Animation Duration", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _zFrequencySlider)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self, @"owner",
                                    sender, @"sender",
                                    [[[_model objectForKey:@"frequencyZ"] retain] autorelease], @"old_value",
                                    @"frequencyZ", @"key",
                                    @"Change Animation Speed", @"action_name",
                              nil];
        [self setSliderDelayedValueWithUndo:info];
    }
    else if(sender == _zFrequencyTextField)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                    [sender objectValue], @"value",
                    [[[_model objectForKey:@"frequencyZ"] retain] autorelease], @"old_value",
                    @"frequencyZ", @"key",
                    @"Change Animation Speed", @"action_name",
                nil];
        [self setValueWithUndo:info];
    }
    else if(sender == _animatePreviewButton)
    {
        [(MyDocument*)[self document] togglePreviewAnimation];
        if([(MyDocument*)[self document] isAnimating])
        {
            [_animatePreviewButton setTitle:@"Stop Animation"];
        }
        else
        {
            [_animatePreviewButton setTitle:@"Preview Animation"];
        }
    }
    else
    {
        NSLog(@"Action sent from unknown sender:%@", sender);
    }
}

- (void)disableControls
{
    NSView* contentView = [[self window] contentView];
    NSArray* subViews = [contentView subviews];
    unsigned int i;
    for(i = 0; i < [subViews count]; i++)
    {
        NSView* subview = [subViews objectAtIndex:i];
        if([subview isKindOfClass:[NSControl class]])
        {
            [(NSControl*)subview setEnabled:NO];
        }
    }
    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)enableControls
{
    NSView* contentView = [[self window] contentView];
    NSArray* subViews = [contentView subviews];
    unsigned int i;
    for(i = 0; i < [subViews count]; i++)
    {
        NSView* subview = [subViews objectAtIndex:i];
        if([subview isKindOfClass:[NSControl class]])
        {
            [(NSControl*)subview setEnabled:YES];
        }
    }
}

- (void)updateAnimationButtonTitle
{
    if([(MyDocument*)[self document] isAnimating])
    {
        [_animatePreviewButton setTitle:@"Stop Animation"];
    }
    else
    {
        [_animatePreviewButton setTitle:@"Preview Animation"];
    }
}

- (void)dealloc
{
    [_sliderFinishedEditingNotificationQueue release];
    [super dealloc];
}

@end
