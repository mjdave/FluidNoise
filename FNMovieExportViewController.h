
#import <Cocoa/Cocoa.h>

@interface FNMovieExportViewController : NSObject {
    IBOutlet NSView* _view;
    IBOutlet NSPopUpButton* _codec;
    IBOutlet NSButton* _optionsButton;
    
    NSData* _exportSettings;
    float _fps;
    
    NSSavePanel* _sp;
    
    NSMutableDictionary* _currentSettings;
}

- (id)initWithSavePanel:(NSSavePanel*)sp
    currentSettings:(NSDictionary*)prefs;

- (IBAction)codecChanged:(id)sender;
- (IBAction)optionsClicked:(id)sender;

- (NSView*)view;

- (float)fps;
- (NSData*)exportSettings;
- (NSDictionary*)component;

- (NSDictionary*)currentSettings;

@end
