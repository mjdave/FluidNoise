

#import <Cocoa/Cocoa.h>


@interface FNImageData : NSObject {
    unsigned _width;
    unsigned _height;
    
    void* _data;
}

- (id)initWithPath:(NSString*)path;
- (unsigned char*)data;
- (unsigned)width;
- (unsigned)height;

@end
