

#import <Cocoa/Cocoa.h>


@interface OpenEXRInterface : NSObject {

}

                
+ (BOOL)writeData:(float*)buffer
                width:(int)width
                height:(int)height
                fileName:(NSString*)fileName;
                
+ (BOOL)writeGrayScaleData:(float*)buffer
                width:(int)width
                height:(int)height
                fileName:(NSString*)fileName;
@end
