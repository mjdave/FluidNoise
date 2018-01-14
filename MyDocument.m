
#import "MyDocument.h"

#import "FNOptionsPanelWindowController.h"
#import "FNMainWindowController.h"
#import "FNImageExportViewController.h"
//#import "FNMovieExportViewController.h"

#import "FNModel.h"
#import "FNView.h"
#import "FNGradientWell.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        _model = [[FNModel alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Tiling Noise" ofType:@"fnse"]]];
    }
    return self;
}

- (IBAction)templateSelected:(id)sender
{
    NSString* templateName = [sender title];
   // MyDocument* newDoc = [[MyDocument alloc] initWithTemplateNamed:templateName];
    
    [[NSDocumentController sharedDocumentController] newDocument:self];
    
    MyDocument* newDoc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:templateName ofType:@"fnse"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    [newDoc readFromData:data ofType:@"fnse" error:nil];
}

- (void)makeWindowControllers
{
    _optionsPanelWindowController = [[FNOptionsPanelWindowController alloc] initWithWindowNibName:@"OptionsPanel"];
    
    NSArray* openDocuments = [[NSDocumentController sharedDocumentController] documents];
    unsigned int i;
    for(i = 0; i < [openDocuments count]; i++)
    {
        MyDocument* document = [openDocuments objectAtIndex:i];
        if(document != self && [document hasVisablePanel])
        {
            NSPoint origin = [document panelFrameOrigin];
            [[_optionsPanelWindowController window] setFrameOrigin:origin];
        }
    }
    
    _mainWindowController = [[FNMainWindowController alloc] initWithWindowNibName:@"MyDocument"];
    
    [self addWindowController:_mainWindowController];
    [self addWindowController:_optionsPanelWindowController];
    
    [_optionsPanelWindowController setModel:_model];
    [_optionsPanelWindowController setControlsToModelValues];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[_mainWindowController window]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidEndSheet:) name:NSWindowDidEndSheetNotification object:[_mainWindowController window]];
    [[_optionsPanelWindowController window] orderFront:self];
    [_optionsPanelWindowController setControlsToModelValues];
    
    [[_mainWindowController view] setDragDropFileName:[self displayName]];
    
    [self updateView];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSData* data = [_model dataOfType:typeName error:outError];
    return data;
}

- (void)setFileURL:(NSURL *)absoluteURL
{
    [super setFileURL:absoluteURL];
    [_optionsPanelWindowController synchronizeWindowTitleWithDocumentName];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    [_model release];
    
    _model = [[FNModel alloc] initWithData:data];
    
    [self updateView];
    [_optionsPanelWindowController setModel:_model];
    [_optionsPanelWindowController setControlsToModelValues];
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
    [super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    [[_mainWindowController view] setDragDropFileName:[self displayName]];
}

- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
    [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    [[_mainWindowController view] setDragDropFileName:[self displayName]];
}

/*- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{

}*/

- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Obtain a custom view that will be printed
    NSView *printView = [[_mainWindowController view] printableView];
 
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation
                printOperationWithView:printView
                printInfo:[self printInfo]];
    [op setShowPanels:showPanels];
    if (showPanels) {
        // Add accessory view, if needed
    }
 
    // Run operation, which shows the Print panel if showPanels was YES
    [self runModalPrintOperation:op
                delegate:nil
                didRunSelector:NULL
                contextInfo:NULL];
}

- (void)displayExportProgressSheet
{
    BOOL OK = [NSBundle loadNibNamed:@"ExportingProgress" owner:self];
    if(!OK)
    {
        NSLog(@"failed to load nib ExportingProgress");
    }
    [_progressPanelIndicator setUsesThreadedAnimation:YES];
    [_progressPanelIndicator startAnimation:self];
    [NSApp beginSheet:_progressPanel modalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(progressSheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
}

- (void)progressSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{

}

- (void)windowDidEndSheet:(NSNotification *)notification
{
    if(_isExporting)
    {
        [self displayExportProgressSheet];
    }
}

- (void)exportToImage:(id)sender
{
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    _exportSavePanel = savePanel;
    [savePanel setPrompt:@"Export"];
    [savePanel setNameFieldLabel:@"Export As:"];
    
    [_imageExportController release];
    _imageExportController = [[FNImageExportViewController alloc] initWithSavePanel:savePanel];
    [savePanel setAccessoryView:[_imageExportController view]];
    
    [savePanel beginSheetForDirectory:[[self fileURL] path]
                file:[self displayName] 
                modalForWindow:[_mainWindowController window]
                modalDelegate:self
                didEndSelector:@selector(imageExportPanelDidEnd: returnCode: contextInfo:)
                contextInfo:nil];
}

- (void)exportToAnimation:(id)sender
{
    // - commented out by majicdave before making open souce, this is the old deprectaed quicktime path that FNG used
    /*NSSavePanel* savePanel = [NSSavePanel savePanel];
    _exportSavePanel = savePanel;
    [savePanel setPrompt:@"Export"];
    [savePanel setNameFieldLabel:@"Export As:"];
    
    [_movieExportController release];
    _movieExportController = [[FNMovieExportViewController alloc] initWithSavePanel:savePanel 
            currentSettings:[[NSUserDefaults standardUserDefaults] objectForKey:@"movie_export_settings"]];
    [savePanel setAccessoryView:[_movieExportController view]];
    
    [savePanel beginSheetForDirectory:[[self fileURL] path]
                file:[self displayName] 
                modalForWindow:[_mainWindowController window]
                modalDelegate:self
                didEndSelector:@selector(movieExportPanelDidEnd: returnCode: contextInfo:)
                contextInfo:nil];*/
    
}

- (void)imageExportPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
    if(returnCode == NSOKButton)
    {
        _isExporting = YES;
        [_optionsPanelWindowController disableControls];
        [[_mainWindowController view] exportImageToURL:[sheet URL]
                    ofType:[_imageExportController fileType]
                    bpp:[_imageExportController bpp]
                    grayScale:[_imageExportController grayScale]
                    model:_model
                    delegate:self
                    didEndSelector:@selector(imageExportDidEnd:)];
    }
}

/*- (void)movieExportPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
    if(returnCode == NSOKButton)
    {
        float fps = [_movieExportController fps];
        NSData* exportSettings = [_movieExportController exportSettings];
        NSDictionary* component = [_movieExportController component];
        
       // NSLog(@"exporting with fps:%f, settings:%@, component:%@", fps, exportSettings, component);
        
        [[NSUserDefaults standardUserDefaults] setObject:[_movieExportController currentSettings] forKey:@"movie_export_settings"];
        
        _isExporting = YES;
        [_optionsPanelWindowController disableControls];
        [[_mainWindowController view] exportAnimationToURL:[sheet URL]
                    withExportSettings:exportSettings
                    fps:fps
                    component:component
                    model:_model
                    delegate:self
                    didEndSelector:@selector(movieExportDidEnd:)];
    }
}*/

- (void)imageExportDidEnd:(id)sender
{
    if(!_isExporting)
    {
        return;
    }
    _isExporting = NO;
    [_optionsPanelWindowController enableControls];
    [_progressPanelIndicator stopAnimation:self];
    [NSApp endSheet:_progressPanel];
    [_progressPanel orderOut:self];
}

- (void)movieExportDidEnd:(id)sender
{
    if(!_isExporting)
    {
        return;
    }
    
    
    _isExporting = NO;
    
    
    _isAnimating = NO;
    [_optionsPanelWindowController updateAnimationButtonTitle];
    [[_mainWindowController view] redrawWithModel:_model];
    
    [_optionsPanelWindowController enableControls];
    [_progressPanelIndicator stopAnimation:self];
    [NSApp endSheet:_progressPanel];
    [_progressPanel orderOut:self];
    
}

- (IBAction)cancelExport:(id)sender
{
    [self imageExportDidEnd:self];
    [self updateView];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    BOOL found = NO;
    NSArray* openDocuments = [[NSDocumentController sharedDocumentController] documents];
    unsigned int i;
    for(i = 0; i < [openDocuments count]; i++)
    {
        MyDocument* document = [openDocuments objectAtIndex:i];
        if(document != self && [document hasVisablePanel])
        {
            NSPoint origin = [document panelFrameOrigin];
            [self setPanelFrameOrigin:origin];
            [self showPanel];
            [document hidePanel];
            found = YES;
        }
    }
    
    if(!found)
    {
        [self showPanel];
    }
    
    [[_mainWindowController window] makeKeyAndOrderFront:self];
}

- (BOOL)hasVisablePanel
{
    return [[_optionsPanelWindowController window] isVisible];
}

- (NSPoint)panelFrameOrigin
{
    return [[_optionsPanelWindowController window] frame].origin;
}

- (void)setPanelFrameOrigin:(NSPoint)origin
{
    [[_optionsPanelWindowController window] setFrameOrigin:origin];
}

- (void)hidePanel
{
    [[_optionsPanelWindowController window] orderOut:self];
}

- (void)showPanel
{
    [[_optionsPanelWindowController window] orderFront:self];
    [_optionsPanelWindowController updateColorPanel];
}

- (void)updateView
{
    if(_isAnimating)
    {
        [[_mainWindowController view] generatePreviewAnimationWithModel:_model];
    }
    else
    {
        [[_mainWindowController view] redrawWithModel:_model];
    }
}

- (void)togglePreviewAnimation
{
    if(_isAnimating)
    {
        _isAnimating = NO;
        [[_mainWindowController view] redrawWithModel:_model];
    }
    else
    {
        _isAnimating = YES;
        [[_mainWindowController view] generatePreviewAnimationWithModel:_model];
    }
}

- (BOOL)isAnimating
{
    return _isAnimating;
}


- (void)dealloc
{
    [_model release];
    [_optionsPanelWindowController release];
    [_mainWindowController release];
    [_imageExportController release];
    [super dealloc];
}

@end
