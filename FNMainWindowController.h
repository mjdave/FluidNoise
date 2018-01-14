

#import <Cocoa/Cocoa.h>

@class FNView;

@interface FNMainWindowController : NSWindowController {

    IBOutlet FNView* _view;
}

- (FNView*)view;

@end
