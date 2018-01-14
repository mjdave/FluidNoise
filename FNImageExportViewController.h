

#import <Cocoa/Cocoa.h>


@interface FNImageExportViewController : NSObject {
    IBOutlet NSView* _view;
    IBOutlet NSPopUpButton* _imageType;
    IBOutlet NSPopUpButton* _bitsPerPixel;
    
    NSSavePanel* _sp;
}

- (id)initWithSavePanel:(NSSavePanel*)sp;

- (NSView*)view;

- (NSString*)fileType;
- (NSNumber*)bpp;

- (NSNumber*)grayScale;

- (IBAction)fileTypeChanged:(id)sender;
- (IBAction)bppChanged:(id)sender;


@end
