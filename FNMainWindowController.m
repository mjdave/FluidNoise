
#import "FNMainWindowController.h"


@implementation FNMainWindowController

- (BOOL)shouldCloseDocument
{
    return YES;
}


- (FNView*)view
{
    return _view;
}


@end
