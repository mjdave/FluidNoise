
#import <Cocoa/Cocoa.h>


int main(int argc, char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    [pool drain];

    return NSApplicationMain(argc, (const char **) argv);
}
