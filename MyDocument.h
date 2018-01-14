

#import <Cocoa/Cocoa.h>

@class FNModel;
@class FNView;
@class FNOptionsPanelWindowController;
@class FNMainWindowController;
@class FNImageExportViewController;
//@class FNMovieExportViewController;// - commented out by majicdave before making open souce, this is the old deprectaed quicktime path that FNG used

@interface MyDocument : NSDocument
{
    FNModel* _model;
    FNOptionsPanelWindowController* _optionsPanelWindowController;
    FNMainWindowController* _mainWindowController;
    
    FNImageExportViewController* _imageExportController;
    //FNMovieExportViewController* _movieExportController;// - commented out by majicdave before making open souce, this is the old deprectaed quicktime path that FNG used
    
    IBOutlet NSWindow* _progressPanel;
    IBOutlet NSProgressIndicator* _progressPanelIndicator;
    
    BOOL _isAnimating;
    
    BOOL _isExporting;
    id _exportSavePanel;
}

- (void)updateView;
- (void)togglePreviewAnimation;

- (BOOL)hasVisablePanel;
- (NSPoint)panelFrameOrigin;
- (void)setPanelFrameOrigin:(NSPoint)origin;
- (void)hidePanel;
- (void)showPanel;

- (BOOL)isAnimating;

- (IBAction)cancelExport:(id)sender;

- (IBAction)templateSelected:(id)sender;

@end
