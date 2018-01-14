

#import "FNController.h"


@implementation FNController

#pragma GCC diagnostic ignored "-Wundeclared-selector"

- (void)awakeFromNib
{
    NSMenu* submenu = [_templateDocumentMenuItem submenu];
    [submenu addItemWithTitle:@"Tiling Noise" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Water" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Water Reflections" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Fire" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Terrain" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Terrain Detailed" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"70s" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Clouds" action:@selector(templateSelected:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Frosted Glass" action:@selector(templateSelected:) keyEquivalent:@""];
}

@end
