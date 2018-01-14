

#import "FNTextFieldCell.h"


@implementation FNTextFieldCell

- (id)initTextCell:(NSString*)string
{
    self = [super initTextCell:string];
    if(!self)
    {
        return nil;
    }
    
   // NSLog(@"okiedokie");
    
    //[self setBackgroundStyle:NSBackgroundStyleRaised];
    [self setBezelStyle:NSTextFieldRoundedBezel];
    
    return self;
}

@end
