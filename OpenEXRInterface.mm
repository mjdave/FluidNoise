

#import "OpenEXRInterface.h"

#include <ImfRgbaFile.h>
//#include <ImfStringAttribute.h>
//#include <ImfMatrixAttribute.h>
//#include <ImfArray.h>
#include <ImfChannelList.h>
#include <ImfOutputFile.h>

@implementation OpenEXRInterface

+ (BOOL)writeData:(float*)buffer
                width:(int)width
                height:(int)height
                fileName:(NSString*)fileName
{
    try
    {
        Imf::Header header(width, height);
        
        header.channels().insert("R", Imf::Channel(Imf::FLOAT)); 
        header.channels().insert("G", Imf::Channel(Imf::FLOAT));
        header.channels().insert("B", Imf::Channel(Imf::FLOAT));
        header.channels().insert("A", Imf::Channel(Imf::FLOAT));
    
        Imf::OutputFile file([fileName UTF8String], header);
        
        Imf::FrameBuffer frameBuffer;
        
        frameBuffer.insert("R",
                Imf::Slice(Imf::FLOAT,
                         (char *)buffer,            // base 
                         sizeof (*buffer) * 4,       // xStride 
                         sizeof (*buffer) * width * 4)); // yStride
        frameBuffer.insert("G",
                Imf::Slice(Imf::FLOAT,
                         (char *)(buffer + 1),            // base 
                         sizeof(*buffer) * 4,       // xStride 
                         sizeof(*buffer) * width * 4)); // yStride
        frameBuffer.insert("B",
                Imf::Slice(Imf::FLOAT,
                         (char *)(buffer + 2),            // base 
                         sizeof(*buffer) * 4,       // xStride 
                         sizeof(*buffer) * width * 4)); // yStride
        frameBuffer.insert("A",
                Imf::Slice(Imf::FLOAT,
                         (char *)(buffer + 3),            // base 
                         sizeof(*buffer) * 4,       // xStride 
                         sizeof(*buffer) * width * 4)); // yStride
                         
        file.setFrameBuffer(frameBuffer);  
        file.writePixels(height);
       // free(halfBuffer);
        return YES;
    }
    catch(const std::exception &exc)
    {
        std::cerr << exc.what() << std::endl;
        //free(halfBuffer);
        return NO;
    }
}


+ (BOOL)writeGrayScaleData:(float*)buffer
                width:(int)width
                height:(int)height
                fileName:(NSString*)fileName
{
    try
    {
        Imf::Header header(width, height);
        
        header.channels().insert("Y", Imf::Channel(Imf::FLOAT));
    
        Imf::OutputFile file([fileName UTF8String], header);
        
        Imf::FrameBuffer frameBuffer;
        
        frameBuffer.insert("Y",
                Imf::Slice(Imf::FLOAT,
                         (char *)buffer,            // base 
                         sizeof (*buffer),       // xStride 
                         sizeof (*buffer) * (width + 2))); // yStride
                         
        file.setFrameBuffer(frameBuffer);  
        file.writePixels(height);
       // free(halfBuffer);
        return YES;
    }
    catch(const std::exception &exc)
    {
        std::cerr << exc.what() << std::endl;
        //free(halfBuffer);
        return NO;
    }
}

@end
