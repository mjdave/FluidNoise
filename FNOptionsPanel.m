

#import "FNOptionsPanel.h"


@implementation FNOptionsPanel

- (void)awakeFromNib
{
    [self setBecomesKeyOnlyIfNeeded:YES];
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end
