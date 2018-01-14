

#import "FNView.h"

#import "FNModel.h"
#import "Perlin.h"
#import "FNGradient.h"
#import "FNThreadSafeQueue.h"
//#import "Image.h"
#import <QuartzCore/QuartzCore.h>
//#import <QTKit/QTKit.h> // - commented out by majicdave before making open souce, this is the old deprectaed quicktime path that FNG used
//#import "FNMovie.h"

//#import "OpenEXRInterface.h" // - commented out by majicdave before making open souce, OpenEXR support could probably be added realtively easily, but I'm not sure the work involved to use the latest versions, and the very old versions of OpenEXR I was using are no longer working

#import "NormalMapGenerator.h"
#import "FNImageData.h"

#import <sys/sysctl.h>

#define DRAG_PREVIEW_MAX_SIZE 600.0f

#define PREVIEW_ANIMATION_FPS 30.0f

int getProcessorCount() 
{
    int count ;
    size_t size=sizeof(count) ;

    if(sysctlbyname("hw.ncpu",&count,&size,NULL,0))
    {
        return 1;
    }

    return count; 
}

int getCacheLineSize()
{
    int count ;
    size_t size=sizeof(count) ;

    if(!sysctlbyname("hw.cachelinesize",&count,&size,NULL,0))
    {
        return 64;
    }

    return count; 
}

#define MOD_I(v) [[model objectForKey:v] intValue]
#define MOD_F(v) [[model objectForKey:v] floatValue]
#define MOD_B(v) [[model objectForKey:v] boolValue]

@implementation FNView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
    {
        _imageWidth = 0;
        _imageHeight = 0;
        
        _processorCount = getProcessorCount();
        _cacheLineSize = getCacheLineSize();
        
        NSMutableArray* inputQueues = [NSMutableArray array];
        NSMutableArray* outputQueues = [NSMutableArray array];
        
        unsigned int i = 0;
        for(i = 0; i < _processorCount; i++)
        {
            FNThreadSafeQueue* inputQueue = [[[FNThreadSafeQueue alloc] init] autorelease];
            FNThreadSafeQueue* outputQueue = [[[FNThreadSafeQueue alloc] init] autorelease];
            
            [NSThread detachNewThreadSelector:@selector(runThreadWithQueues:) toTarget:self withObject:
                                        [NSDictionary dictionaryWithObjectsAndKeys:
                                            inputQueue, @"inputQueue",
                                            outputQueue, @"outputQueue",
                                            nil]];
            [inputQueues addObject:inputQueue];
            [outputQueues addObject:outputQueue];
        }
        
        _inputQueues = [inputQueues copy];
        _outputQueues = [outputQueues copy];
        
        _redrawQueue = [[FNThreadSafeQueue alloc] init];
        [NSThread detachNewThreadSelector:@selector(redrawThreadWithQueue:) toTarget:self withObject:
                                        _redrawQueue];
                                        
        _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(
                                    frame.origin.x + frame.size.width * 0.5f - 16.0f,
                                    frame.origin.y + frame.size.height * 0.5f - 16.0f,
                                    32.0f,
                                    32.0f)];
        [_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
        [_progressIndicator setHidden:YES];
        [_progressIndicator setUsesThreadedAnimation:YES];
        [self addSubview:_progressIndicator];
        
        _gridFilter = [[CIFilter filterWithName:@"CICheckerboardGenerator"] retain];
        [_gridFilter setDefaults];
        [_gridFilter setValue:[CIColor colorWithRed:0.4f green:0.4f blue:0.4f] forKey:@"inputColor0"];
        [_gridFilter setValue:[CIColor colorWithRed:0.6f green:0.6f blue:0.6f] forKey:@"inputColor1"];
        [_gridFilter setValue:[NSNumber numberWithFloat:8.0f] forKey:@"inputWidth"];
        [_gridFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f] forKey:@"inputCenter"];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
}

- (void)runThreadWithQueues:(NSDictionary*)queues
{
    FNThreadSafeQueue* inputQueue = [[queues objectForKey:@"inputQueue"] retain];
    FNThreadSafeQueue* outputQueue = [[queues objectForKey:@"outputQueue"] retain];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	while(1)
	{
        NSDictionary* object = [inputQueue dequeue];
        while(![inputQueue empty])
        {
            object = [inputQueue dequeue];
        }
        
        int rowStart = [[object objectForKey:@"rowStart"] intValue];
        int rowEnd = [[object objectForKey:@"rowEnd"] intValue];
        int width = [[object objectForKey:@"width"] intValue];
        int height = [[object objectForKey:@"height"] intValue];
        BOOL turbulent = [[object objectForKey:@"turbulent"] boolValue];
        BOOL tile = [[object objectForKey:@"tile"] boolValue];
        float amplitude = [[object objectForKey:@"amplitude"] floatValue];
        float zFraction = [[object objectForKey:@"zFraction"] floatValue];
        unsigned output = [[object objectForKey:@"output"] intValue];
        float normalMapHeightScale = [[object objectForKey:@"normalMapHeightScale"] floatValue];
        float environmentMapHeightScale = [[object objectForKey:@"environmentMapHeightScale"] floatValue];
        float distortionImageHeightScale = [[object objectForKey:@"distortionImageHeightScale"] floatValue];
        
        Perlin* perlin = [object objectForKey:@"perlin"];
        FNGradient* gradient = [object objectForKey:@"gradient"];
        
        int bufferRowStart = rowStart - 1;
        int bufferRowEnd = rowEnd + 1;
        
        int y;
        for(y = bufferRowStart; y < bufferRowEnd; y++)
        {
            int x;
            for(x = -1; x < width + 1; x++)
            {
                float xValue = (((float)x + 0.34f) / width);
                float yValue = (((float)y + 0.25f) / height);
                float value = [perlin getX:xValue Y:yValue Z:zFraction];
                if(turbulent)
                {
                    value = fabs(value);
                }
                else
                {
                    value += amplitude;
                    value *= 0.5f;
                }
                
                if(value < 0.0f)
                {
                    value = 0.0f;
                }
                    
                if(value > 1.0f)
                {
                    value = 1.0f;
                }
                
                _buffer[((y + 1) * (width + 2) + (x + 1))] = value;
            }
        }
        
        if(output == OUTPUT_TYPE_GRADIENT)
        {
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    int bufferIndex = ((y + 1) * (width + 2) + x + 1);
                    int pixelIndex = (y * width + x);
                    
                    Color gradientColor = [gradient colorForFraction:_buffer[bufferIndex]];
                    
                    int previewBufferIndex = pixelIndex * 4;
                    
                    _previewBuffer[previewBufferIndex + 0] = (unsigned char)(gradientColor.r * 255.0f * gradientColor.a);
                    _previewBuffer[previewBufferIndex + 1] = (unsigned char)(gradientColor.g * 255.0f * gradientColor.a);
                    _previewBuffer[previewBufferIndex + 2] = (unsigned char)(gradientColor.b * 255.0f * gradientColor.a);
                    _previewBuffer[previewBufferIndex + 3] = (unsigned char)(gradientColor.a * 255.0f);
                }
            }
        }
        else if(output == OUTPUT_TYPE_NORMAL_MAP)
        {
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    //int bufferIndex = ((y + 1) * (width + 2) + x + 1);
                    int pixelIndex = (y * width + x);
                    
                    Color normalColor = generateNormal(_buffer, x + 1, y + 1, width + 2, height + 2, normalMapHeightScale);
                    
                    //Color gradientColor = [gradient colorForFraction:_buffer[bufferIndex]];
                    
                    int previewBufferIndex = pixelIndex * 4;
                    
                    _previewBuffer[previewBufferIndex + 0] = (unsigned char)(normalColor.r * 255.0f);
                    _previewBuffer[previewBufferIndex + 1] = (unsigned char)(normalColor.g * 255.0f);
                    _previewBuffer[previewBufferIndex + 2] = (unsigned char)(normalColor.b * 255.0f);
                    _previewBuffer[previewBufferIndex + 3] = (unsigned char)(normalColor.a * 255.0f);
                }
            }
        }
        else if(output == OUTPUT_TYPE_ENVIRONMENT_MAP)
        {
            unsigned environmentMapWidth, environmentMapHeight, bitsPerPixel, bytesPerRow, channels;
            unsigned char* imageData;
            
            if(_environmentMapBitmapImageRep)
            {
                environmentMapWidth = (int)[_environmentMapBitmapImageRep pixelsWide];
                environmentMapHeight = (int)[_environmentMapBitmapImageRep pixelsHigh];
                imageData = [_environmentMapBitmapImageRep bitmapData];
                bitsPerPixel = (int)[_environmentMapBitmapImageRep bitsPerPixel];
                bytesPerRow = (int)[_environmentMapBitmapImageRep bytesPerRow];
                channels = bitsPerPixel / 8;//[_environmentMapBitmapImageRep samplesPerPixel];
            }
            
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    int pixelIndex = (y * width + x);
                    int previewBufferIndex = pixelIndex * 4;
                    Color normalColor = generateNormal(_buffer, x + 1, y + 1, width + 2, height + 2, environmentMapHeightScale);
                    
                    if(_environmentMapBitmapImageRep)
                    {
                        float xLookup = (normalColor.r) * environmentMapWidth;
                        float yLookup = (normalColor.g) * environmentMapHeight;
                        
                        xLookup = xLookup < environmentMapWidth ? (xLookup > 0.0f ? xLookup : 0.0f) : environmentMapWidth;
                        yLookup = yLookup < environmentMapHeight ? (yLookup > 0.0f ? yLookup : 0.0f) : environmentMapHeight;
                        
                        unsigned xLookupA = xLookup < environmentMapWidth ? xLookup : 0;
                        unsigned xLookupB = xLookup + 1 < environmentMapWidth ? xLookup + 1 : xLookup;
                        unsigned yLookupA = yLookup < environmentMapHeight ? yLookup : 1;
                        unsigned yLookupB = yLookup + 1 < environmentMapHeight ? yLookup + 1 : yLookup;
                        
                       // unsigned xLookup = ((float)x / width) * environmentMapWidth;
                       // unsigned yLookup = ((float)y / height) * environmentMapHeight;
                       
                       // bilinear interpolation
                       
                        float u_ratio = xLookup - xLookupA;
                        float v_ratio = yLookup - yLookupA;
                        float u_opposite = 1 - u_ratio;
                        float v_opposite = 1 - v_ratio;
                        
                        unsigned envMapLookupAA = yLookupA * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupAB = yLookupB * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupBB = yLookupB * bytesPerRow + xLookupB * channels;
                        unsigned envMapLookupBA = yLookupA * bytesPerRow + xLookupB * channels;
                        
                        float aar = (float)imageData[envMapLookupAA] / 255.0f;
                        float aag = (float)imageData[envMapLookupAA + 1] / 255.0f;
                        float aab = (float)imageData[envMapLookupAA + 2] / 255.0f;
                        float aaa = channels < 4 ? 1.0f : (float)imageData[envMapLookupAA + 3] / 255.0f;
                        
                        float abr = (float)imageData[envMapLookupAB] / 255.0f;
                        float abg = (float)imageData[envMapLookupAB + 1] / 255.0f;
                        float abb = (float)imageData[envMapLookupAB + 2] / 255.0f;
                        float aba = channels < 4 ? 1.0f : (float)imageData[envMapLookupAB + 3] / 255.0f;
                        
                        float bbr = (float)imageData[envMapLookupBB] / 255.0f;
                        float bbg = (float)imageData[envMapLookupBB + 1] / 255.0f;
                        float bbb = (float)imageData[envMapLookupBB + 2] / 255.0f;
                        float bba = channels < 4 ? 1.0f : (float)imageData[envMapLookupBB + 3] / 255.0f;
                        
                        float bar = (float)imageData[envMapLookupBA] / 255.0f;
                        float bag = (float)imageData[envMapLookupBA + 1] / 255.0f;
                        float bab = (float)imageData[envMapLookupBA + 2] / 255.0f;
                        float baa = channels < 4 ? 1.0f : (float)imageData[envMapLookupBA + 3] / 255.0f;
                        
                        _previewBuffer[previewBufferIndex + 0] =    (unsigned char)(((aar * u_opposite + bar * u_ratio) * v_opposite + 
                                                                     (abr * u_opposite + bbr * u_ratio) * v_ratio) * 255.0f);
                        _previewBuffer[previewBufferIndex + 1] =    (unsigned char)(((aag * u_opposite + bag * u_ratio) * v_opposite + 
                                                                     (abg * u_opposite + bbg * u_ratio) * v_ratio) * 255.0f);
                        _previewBuffer[previewBufferIndex + 2] =    (unsigned char)(((aab * u_opposite + bab * u_ratio) * v_opposite + 
                                                                     (abb * u_opposite + bbb * u_ratio) * v_ratio) * 255.0f);
                        _previewBuffer[previewBufferIndex + 3] =    (unsigned char)(((aaa * u_opposite + baa * u_ratio) * v_opposite + 
                                                                     (aba * u_opposite + bba * u_ratio) * v_ratio) * 255.0f);
                    }
                    else
                    {
                        _previewBuffer[previewBufferIndex + 0] = (unsigned char)(normalColor.r * 255.0f);
                        _previewBuffer[previewBufferIndex + 1] = (unsigned char)(normalColor.g * 255.0f);
                        _previewBuffer[previewBufferIndex + 2] = (unsigned char)(normalColor.b * 255.0f);
                        _previewBuffer[previewBufferIndex + 3] = (unsigned char)(normalColor.a * 255.0f);
                    }
                }
            }
        }
        else if(output == OUTPUT_TYPE_IMAGE_DISTORTION)
        {
            FNImageData* distortionImageData = [_distortionImageData retain];
            int imageWidth, imageHeight, channels, bytesPerRow;
            unsigned char* imageData;
            
            if(_distortionImageData)
            {
                imageWidth = [distortionImageData width];
                imageHeight = [distortionImageData height];
                imageData = [distortionImageData data];
                //bitsPerPixel = 4;//[_distortionImageBitmapImageRep bitsPerPixel];
                bytesPerRow = 4 * imageWidth;//[_distortionImageBitmapImageRep bytesPerRow];
                channels = 4;//bitsPerPixel / 8;//[_environmentMapBitmapImageRep samplesPerPixel];
            }
            
            unsigned rL = 1;
            unsigned gL = 2;
            unsigned bL = 3;
            unsigned aL = 0;
            
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    int pixelIndex = (y * width + x);
                    int previewBufferIndex = pixelIndex * 4;
                    Color normalColor = generateNormal(_buffer, x + 1, y + 1, width + 2, height + 2, 1.0f);
                    
                    if(distortionImageData)
                    {
                        float xLookup = ((float)x / width) * imageWidth + ((normalColor.r - 0.5) * distortionImageHeightScale * imageWidth);
                        float yLookup = ((float)y / height) * imageHeight + ((normalColor.g - 0.5) * distortionImageHeightScale * imageHeight);
                        
                        if(tile)
                        {
                            xLookup = xLookup <= imageWidth ? (xLookup >= 0.0f ? xLookup : fabsf(fmodf(xLookup + imageWidth, imageWidth))) : fabsf(fmodf(xLookup, imageWidth));
                            yLookup = yLookup <= imageHeight ? (yLookup >= 0.0f ? yLookup : fabsf(fmodf(yLookup + imageHeight, imageHeight))) : fabsf(fmodf(yLookup, imageHeight));
                        }
                        else
                        {
                            xLookup = xLookup <= imageWidth ? (xLookup >= 0.0f ? xLookup : 0.0f) : imageWidth - 1;
                            yLookup = yLookup <= imageHeight ? (yLookup >= 0.0f ? yLookup : 0.0f) : imageHeight - 1;
                        }
                        //NSLog(@"x:%f y:%f", xLookup, yLookup);
                        
                        int xLookupA = xLookup < imageWidth ? xLookup : 0;
                        int xLookupB = xLookupA + 1 < imageWidth ? xLookupA + 1 : xLookupA + 1 - imageWidth;
                        int yLookupA = yLookup < imageHeight ? yLookup : 0;
                        int yLookupB = yLookupA + 1 < imageHeight ? yLookupA + 1 : yLookupA + 1 - imageHeight;
                       
                       // bilinear interpolation
                       
                        float u_ratio = xLookup - xLookupA;
                        float v_ratio = yLookup - yLookupA;
                        float u_opposite = 1 - u_ratio;
                        float v_opposite = 1 - v_ratio;
                        
                        unsigned envMapLookupAA = yLookupA * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupAB = yLookupB * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupBB = yLookupB * bytesPerRow + xLookupB * channels;
                        unsigned envMapLookupBA = yLookupA * bytesPerRow + xLookupB * channels;
                        
                        
                        float aar = (float)imageData[envMapLookupAA + rL] / 255.0f;
                        float aag = (float)imageData[envMapLookupAA + gL] / 255.0f;
                        float aab = (float)imageData[envMapLookupAA + bL] / 255.0f;
                        float aaa = channels < 4 ? 1.0f : (float)imageData[envMapLookupAA + aL] / 255.0f;
                        
                        float abr = (float)imageData[envMapLookupAB + rL] / 255.0f;
                        float abg = (float)imageData[envMapLookupAB + gL] / 255.0f;
                        float abb = (float)imageData[envMapLookupAB + bL] / 255.0f;
                        float aba = channels < 4 ? 1.0f : (float)imageData[envMapLookupAB + aL] / 255.0f;
                        
                        float bbr = (float)imageData[envMapLookupBB + rL] / 255.0f;
                        float bbg = (float)imageData[envMapLookupBB + gL] / 255.0f;
                        float bbb = (float)imageData[envMapLookupBB + bL] / 255.0f;
                        float bba = channels < 4 ? 1.0f : (float)imageData[envMapLookupBB + aL] / 255.0f;
                        
                        float bar = (float)imageData[envMapLookupBA + rL] / 255.0f;
                        float bag = (float)imageData[envMapLookupBA + gL] / 255.0f;
                        float bab = (float)imageData[envMapLookupBA + bL] / 255.0f;
                        float baa = channels < 4 ? 1.0f : (float)imageData[envMapLookupBA + aL] / 255.0f;
                        
                        _previewBuffer[previewBufferIndex + 0] =    (unsigned char)(((aar * u_opposite + bar * u_ratio) * v_opposite + 
                                                                     (abr * u_opposite + bbr * u_ratio) * v_ratio) * 255.0f);
                        _previewBuffer[previewBufferIndex + 1] =    (unsigned char)(((aag * u_opposite + bag * u_ratio) * v_opposite + 
                                                                     (abg * u_opposite + bbg * u_ratio) * v_ratio) * 255.0f);
                        _previewBuffer[previewBufferIndex + 2] =    (unsigned char)(((aab * u_opposite + bab * u_ratio) * v_opposite + 
                                                                     (abb * u_opposite + bbb * u_ratio) * v_ratio) * 255.0f);
                        _previewBuffer[previewBufferIndex + 3] =    (unsigned char)(((aaa * u_opposite + baa * u_ratio) * v_opposite + 
                                                                     (aba * u_opposite + bba * u_ratio) * v_ratio) * 255.0f);
                    }
                    else
                    {
                        _previewBuffer[previewBufferIndex + 0] = (unsigned char)(normalColor.r * 255.0f);
                        _previewBuffer[previewBufferIndex + 1] = (unsigned char)(normalColor.g * 255.0f);
                        _previewBuffer[previewBufferIndex + 2] = (unsigned char)(normalColor.b * 255.0f);
                        _previewBuffer[previewBufferIndex + 3] = (unsigned char)(normalColor.a * 255.0f);
                    }
                }
            }
            
            [distortionImageData release];
        }
        else
        {
            NSLog(@"unsupported output type");
        }
        
        id result = [object objectForKey:@"index"];
        
        [outputQueue enqueue:result];
		
		[pool release];
        pool = [[NSAutoreleasePool alloc] init];
	}
}


- (void)updateProgressIndicatorPosition
{

    NSRect visableRect = [[self enclosingScrollView] documentVisibleRect];
    
    [_progressIndicator setFrameOrigin:NSMakePoint(
                                    floor(visableRect.origin.x + visableRect.size.width * 0.5f - 16.0f),
                                    floor(visableRect.origin.y + visableRect.size.height * 0.5f - 16.0f))];
}

- (void)updateSize
{
    NSSize newSuperSize = [[self enclosingScrollView] contentSize];
    NSSize newSize = [_image size];
    if(newSuperSize.width > [_image size].width)
    {
        newSize.width = newSuperSize.width;
    }
    if(newSuperSize.height > [_image size].height)
    {
        newSize.height = newSuperSize.height;
    }
    [self setFrameSize:newSize];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSuperSize
{
    if(!_image)
    {
        [super resizeWithOldSuperviewSize:oldSuperSize];
        return;
    }
    [self updateSize];
}


- (void)generatePreviewImageWithWidth:(int)width height:(int)height data:(NSData*)data
{
    [_safePreviewData autorelease];
    _safePreviewData = [data retain];
    unsigned char* dataBytes = (unsigned char*)[_safePreviewData bytes];
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc ] initWithBitmapDataPlanes:&dataBytes
        pixelsWide:width
        pixelsHigh:height
        bitsPerSample:8
        samplesPerPixel:4
        hasAlpha:YES
        isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace
        bytesPerRow:width * 4 * sizeof(unsigned char)
        bitsPerPixel:32];
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width,height)];
    
    [image addRepresentation:bitmap];
    [bitmap release];
    
    [_image release];
    _image = image;
    
    _imageWidth = width;
    _imageHeight = height;
    
    [self updateSize];
    [self setNeedsDisplay:YES];
}

- (void)mainThreadGeneratePreviewImageWithOptions:(NSDictionary*)options
{
    int width = [[options objectForKey:@"width"] intValue];
    int height = [[options objectForKey:@"height"] intValue];
    NSData* data = [options objectForKey:@"data"];
    [self generatePreviewImageWithWidth:width height:height data:data];
}

- (NSBitmapImageFileType)bitmapImageFileTypeForName:(NSString*)name
{
    if([name isEqualToString:@"PNG"])
    {
        return NSPNGFileType;
    }
    else if([name isEqualToString:@"JPEG"])
    {
        return NSJPEGFileType;
    }
    else if([name isEqualToString:@"TIFF"])
    {
        return NSTIFFFileType;
    }
    else if([name isEqualToString:@"JPEG2000"])
    {
        return NSJPEG2000FileType;
    }
    else if([name isEqualToString:@"GIF"])
    {
        return NSGIFFileType;
    }
    
    return NSPNGFileType;
}

- (void)fillFloatData:(float*)buffer withOptions:(NSDictionary*)object
{
    int width = [[object objectForKey:@"width"] intValue];
    int height = [[object objectForKey:@"height"] intValue];
    //BOOL turbulent = [[object objectForKey:@"turbulent"] boolValue];
    BOOL tile = [[object objectForKey:@"tile"] boolValue];
    //float amplitude = [[object objectForKey:@"amplitude"] floatValue];
    //float zFraction = [[object objectForKey:@"zFraction"] floatValue];
    unsigned output = [[object objectForKey:@"output"] intValue];
    float normalMapHeightScale = [[object objectForKey:@"normalMapHeightScale"] floatValue];
    float environmentMapHeightScale = [[object objectForKey:@"environmentMapHeightScale"] floatValue];
    float distortionImageHeightScale = [[object objectForKey:@"distortionImageHeightScale"] floatValue];
    
    //Perlin* perlin = [object objectForKey:@"perlin"];
    FNGradient* gradient = [object objectForKey:@"gradient"];
    
    
    int rowStart = 0;
    int rowEnd = height;
    
    //int bufferRowStart = rowStart - 1;
    //int bufferRowEnd = rowEnd + 1;
    
    int y;
        
        if(output == OUTPUT_TYPE_GRADIENT)
        {
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    int bufferIndex = ((y + 1) * (width + 2) + x + 1);
                    int pixelIndex = (y * width + x);
                    
                    Color gradientColor = [gradient colorForFraction:_buffer[bufferIndex]];
                    
                    int previewBufferIndex = pixelIndex * 4;
                    
                    buffer[previewBufferIndex + 0] = (gradientColor.r * gradientColor.a);
                    buffer[previewBufferIndex + 1] = (gradientColor.g * gradientColor.a);
                    buffer[previewBufferIndex + 2] = (gradientColor.b * gradientColor.a);
                    buffer[previewBufferIndex + 3] = (gradientColor.a);
                }
            }
        }
        else if(output == OUTPUT_TYPE_NORMAL_MAP)
        {
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    //int bufferIndex = ((y + 1) * (width + 2) + x + 1);
                    int pixelIndex = (y * width + x);
                    
                    Color normalColor = generateNormal(_buffer, x + 1, y + 1, width + 2, height + 2, normalMapHeightScale);
                    
                    //Color gradientColor = [gradient colorForFraction:_buffer[bufferIndex]];
                    
                    int previewBufferIndex = pixelIndex * 4;
                    
                    buffer[previewBufferIndex + 0] = (normalColor.r);
                    buffer[previewBufferIndex + 1] = (normalColor.g);
                    buffer[previewBufferIndex + 2] = (normalColor.b);
                    buffer[previewBufferIndex + 3] = (normalColor.a);
                }
            }
        }
        else if(output == OUTPUT_TYPE_ENVIRONMENT_MAP)
        {
            unsigned environmentMapWidth, environmentMapHeight, bitsPerPixel, bytesPerRow, channels;
            unsigned char* imageData;
            
            if(_environmentMapBitmapImageRep)
            {
                environmentMapWidth = (int)[_environmentMapBitmapImageRep pixelsWide];
                environmentMapHeight = (int)[_environmentMapBitmapImageRep pixelsHigh];
                imageData = [_environmentMapBitmapImageRep bitmapData];
                bitsPerPixel = (int)[_environmentMapBitmapImageRep bitsPerPixel];
                bytesPerRow = (int)[_environmentMapBitmapImageRep bytesPerRow];
                channels = bitsPerPixel / 8;//[_environmentMapBitmapImageRep samplesPerPixel];
            }
            
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    int pixelIndex = (y * width + x);
                    int previewBufferIndex = pixelIndex * 4;
                    Color normalColor = generateNormal(_buffer, x + 1, y + 1, width + 2, height + 2, environmentMapHeightScale);
                    
                    if(_environmentMapBitmapImageRep)
                    {
                        float xLookup = (normalColor.r) * environmentMapWidth;
                        float yLookup = (normalColor.g) * environmentMapHeight;
                        
                        xLookup = xLookup < environmentMapWidth ? (xLookup > 0.0f ? xLookup : 0.0f) : environmentMapWidth;
                        yLookup = yLookup < environmentMapHeight ? (yLookup > 0.0f ? yLookup : 0.0f) : environmentMapHeight;
                        
                        unsigned xLookupA = xLookup < environmentMapWidth ? xLookup : 0;
                        unsigned xLookupB = xLookup + 1 < environmentMapWidth ? xLookup + 1 : xLookup;
                        unsigned yLookupA = yLookup < environmentMapHeight ? yLookup : 1;
                        unsigned yLookupB = yLookup + 1 < environmentMapHeight ? yLookup + 1 : yLookup;
                        
                       // unsigned xLookup = ((float)x / width) * environmentMapWidth;
                       // unsigned yLookup = ((float)y / height) * environmentMapHeight;
                       
                       // bilinear interpolation
                       
                        float u_ratio = xLookup - xLookupA;
                        float v_ratio = yLookup - yLookupA;
                        float u_opposite = 1 - u_ratio;
                        float v_opposite = 1 - v_ratio;
                        
                        unsigned envMapLookupAA = yLookupA * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupAB = yLookupB * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupBB = yLookupB * bytesPerRow + xLookupB * channels;
                        unsigned envMapLookupBA = yLookupA * bytesPerRow + xLookupB * channels;
                        
                        float aar = (float)imageData[envMapLookupAA] / 255.0f;
                        float aag = (float)imageData[envMapLookupAA + 1] / 255.0f;
                        float aab = (float)imageData[envMapLookupAA + 2] / 255.0f;
                        float aaa = channels < 4 ? 1.0f : (float)imageData[envMapLookupAA + 3] / 255.0f;
                        
                        float abr = (float)imageData[envMapLookupAB] / 255.0f;
                        float abg = (float)imageData[envMapLookupAB + 1] / 255.0f;
                        float abb = (float)imageData[envMapLookupAB + 2] / 255.0f;
                        float aba = channels < 4 ? 1.0f : (float)imageData[envMapLookupAB + 3] / 255.0f;
                        
                        float bbr = (float)imageData[envMapLookupBB] / 255.0f;
                        float bbg = (float)imageData[envMapLookupBB + 1] / 255.0f;
                        float bbb = (float)imageData[envMapLookupBB + 2] / 255.0f;
                        float bba = channels < 4 ? 1.0f : (float)imageData[envMapLookupBB + 3] / 255.0f;
                        
                        float bar = (float)imageData[envMapLookupBA] / 255.0f;
                        float bag = (float)imageData[envMapLookupBA + 1] / 255.0f;
                        float bab = (float)imageData[envMapLookupBA + 2] / 255.0f;
                        float baa = channels < 4 ? 1.0f : (float)imageData[envMapLookupBA + 3] / 255.0f;
                        
                        buffer[previewBufferIndex + 0] =    (((aar * u_opposite + bar * u_ratio) * v_opposite + 
                                                                     (abr * u_opposite + bbr * u_ratio) * v_ratio));
                        buffer[previewBufferIndex + 1] =    (((aag * u_opposite + bag * u_ratio) * v_opposite + 
                                                                     (abg * u_opposite + bbg * u_ratio) * v_ratio));
                        buffer[previewBufferIndex + 2] =    (((aab * u_opposite + bab * u_ratio) * v_opposite + 
                                                                     (abb * u_opposite + bbb * u_ratio) * v_ratio));
                        buffer[previewBufferIndex + 3] =    (((aaa * u_opposite + baa * u_ratio) * v_opposite + 
                                                                     (aba * u_opposite + bba * u_ratio) * v_ratio));
                    }
                    else
                    {
                        buffer[previewBufferIndex + 0] = (normalColor.r);
                        buffer[previewBufferIndex + 1] = (normalColor.g);
                        buffer[previewBufferIndex + 2] = (normalColor.b);
                        buffer[previewBufferIndex + 3] = (normalColor.a);
                    }
                }
            }
        }
        else if(output == OUTPUT_TYPE_IMAGE_DISTORTION)
        {
            FNImageData* distortionImageData = [_distortionImageData retain];
            int imageWidth, imageHeight, channels, bytesPerRow;
            unsigned char* imageData;
            
            if(_distortionImageData)
            {
                imageWidth = [distortionImageData width];
                imageHeight = [distortionImageData height];
                imageData = [distortionImageData data];
                //bitsPerPixel = 4;//[_distortionImageBitmapImageRep bitsPerPixel];
                bytesPerRow = 4 * imageWidth;//[_distortionImageBitmapImageRep bytesPerRow];
                channels = 4;//bitsPerPixel / 8;//[_environmentMapBitmapImageRep samplesPerPixel];
            }
            
            unsigned rL = 1;
            unsigned gL = 2;
            unsigned bL = 3;
            unsigned aL = 0;
            
            for(y = rowStart; y < rowEnd; y++)
            {
                int x;
                for(x = 0; x < width; x++)
                {
                    int pixelIndex = (y * width + x);
                    int previewBufferIndex = pixelIndex * 4;
                    Color normalColor = generateNormal(_buffer, x + 1, y + 1, width + 2, height + 2, 1.0f);
                    
                    if(distortionImageData)
                    {
                        float xLookup = ((float)x / width) * imageWidth + ((normalColor.r - 0.5) * distortionImageHeightScale * imageWidth);
                        float yLookup = ((float)y / height) * imageHeight + ((normalColor.g - 0.5) * distortionImageHeightScale * imageHeight);
                        
                        //xLookup = xLookup <= imageWidth ? (xLookup >= 0.0f ? xLookup : fabsf(fmodf(xLookup, imageWidth))) : fabsf(fmodf(xLookup, imageWidth));
                        //yLookup = yLookup <= imageHeight ? (yLookup >= 0.0f ? yLookup : fabsf(fmodf(yLookup, imageHeight))) : fabsf(fmodf(yLookup, imageHeight));
                        //NSLog(@"x:%f y:%f", xLookup, yLookup);
                        
                        if(tile)
                        {
                            xLookup = xLookup <= imageWidth ? (xLookup >= 0.0f ? xLookup : fabsf(fmodf(xLookup + imageWidth, imageWidth))) : fabsf(fmodf(xLookup, imageWidth));
                            yLookup = yLookup <= imageHeight ? (yLookup >= 0.0f ? yLookup : fabsf(fmodf(yLookup + imageHeight, imageHeight))) : fabsf(fmodf(yLookup, imageHeight));
                        }
                        else
                        {
                            xLookup = xLookup <= imageWidth ? (xLookup >= 0.0f ? xLookup : 0.0f) : imageWidth - 1;
                            yLookup = yLookup <= imageHeight ? (yLookup >= 0.0f ? yLookup : 0.0f) : imageHeight - 1;
                        }
                        
                        int xLookupA = xLookup < imageWidth ? xLookup : 0;
                        int xLookupB = xLookupA + 1 < imageWidth ? xLookupA + 1 : xLookupA + 1 - imageWidth;
                        int yLookupA = yLookup < imageHeight ? yLookup : 1;
                        int yLookupB = yLookupA + 1 < imageHeight ? yLookupA + 1 : yLookupA + 1 - imageHeight;
                       
                       // bilinear interpolation
                       
                        float u_ratio = xLookup - xLookupA;
                        float v_ratio = yLookup - yLookupA;
                        float u_opposite = 1 - u_ratio;
                        float v_opposite = 1 - v_ratio;
                        
                        unsigned envMapLookupAA = yLookupA * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupAB = yLookupB * bytesPerRow + xLookupA * channels;
                        unsigned envMapLookupBB = yLookupB * bytesPerRow + xLookupB * channels;
                        unsigned envMapLookupBA = yLookupA * bytesPerRow + xLookupB * channels;
                        
                        float aar = (float)imageData[envMapLookupAA + rL] / 255.0f;
                        float aag = (float)imageData[envMapLookupAA + gL] / 255.0f;
                        float aab = (float)imageData[envMapLookupAA + bL] / 255.0f;
                        float aaa = channels < 4 ? 1.0f : (float)imageData[envMapLookupAA + aL] / 255.0f;
                        
                        float abr = (float)imageData[envMapLookupAB + rL] / 255.0f;
                        float abg = (float)imageData[envMapLookupAB + gL] / 255.0f;
                        float abb = (float)imageData[envMapLookupAB + bL] / 255.0f;
                        float aba = channels < 4 ? 1.0f : (float)imageData[envMapLookupAB + aL] / 255.0f;
                        
                        float bbr = (float)imageData[envMapLookupBB + rL] / 255.0f;
                        float bbg = (float)imageData[envMapLookupBB + gL] / 255.0f;
                        float bbb = (float)imageData[envMapLookupBB + bL] / 255.0f;
                        float bba = channels < 4 ? 1.0f : (float)imageData[envMapLookupBB + aL] / 255.0f;
                        
                        float bar = (float)imageData[envMapLookupBA + rL] / 255.0f;
                        float bag = (float)imageData[envMapLookupBA + gL] / 255.0f;
                        float bab = (float)imageData[envMapLookupBA + bL] / 255.0f;
                        float baa = channels < 4 ? 1.0f : (float)imageData[envMapLookupBA + aL] / 255.0f;
                        
                        buffer[previewBufferIndex + 0] =    (((aar * u_opposite + bar * u_ratio) * v_opposite + 
                                                                     (abr * u_opposite + bbr * u_ratio) * v_ratio));
                        buffer[previewBufferIndex + 1] =    (((aag * u_opposite + bag * u_ratio) * v_opposite + 
                                                                     (abg * u_opposite + bbg * u_ratio) * v_ratio));
                        buffer[previewBufferIndex + 2] =    (((aab * u_opposite + bab * u_ratio) * v_opposite + 
                                                                     (abb * u_opposite + bbb * u_ratio) * v_ratio));
                        buffer[previewBufferIndex + 3] =    (((aaa * u_opposite + baa * u_ratio) * v_opposite + 
                                                                     (aba * u_opposite + bba * u_ratio) * v_ratio));
                    }
                    else
                    {
                        buffer[previewBufferIndex + 0] = (normalColor.r);
                        buffer[previewBufferIndex + 1] = (normalColor.g);
                        buffer[previewBufferIndex + 2] = (normalColor.b);
                        buffer[previewBufferIndex + 3] = (normalColor.a);
                    }
                }
            }
            
            [distortionImageData release];
        }
        else
        {
            NSLog(@"unsupported output type");
        }
}

- (void)mainThreadExportImageWithOptions:(NSDictionary*)options
{
    NSURL* fileURL = [options objectForKey:@"fileURL"];
    unsigned int bpp = [[options objectForKey:@"bpp"] intValue];
    BOOL grayScale = [[options objectForKey:@"grayScale"] boolValue];
    NSString* fileFormat = [options objectForKey:@"fileType"];
    NSData* data = [options objectForKey:@"data"];
    unsigned char* dataBytes = (unsigned char*)[data bytes];
    
    if(bpp == 8)
    {
        NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc ] initWithBitmapDataPlanes:&dataBytes
            pixelsWide:_imageWidth
            pixelsHigh:_imageHeight
            bitsPerSample:8
            samplesPerPixel:4
            hasAlpha:YES
            isPlanar:NO
            colorSpaceName:NSCalibratedRGBColorSpace
            bytesPerRow:_imageWidth * 4 * sizeof(unsigned char)
            bitsPerPixel:32];
            
        NSBitmapImageFileType type = [self bitmapImageFileTypeForName:fileFormat];
            
        NSData* data = [bitmap representationUsingType:type
                properties:[NSDictionary dictionary]];
                    
        [data writeToURL:fileURL atomically:YES];
    }
    else if([fileFormat isEqualToString:@"TIFF"])
    {
        if(grayScale)
        {
            CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
            
            CGContextRef contextRef = CGBitmapContextCreate (
               _buffer,
               _imageWidth,
               _imageHeight,
               32,
               (_imageWidth + 2) * 1 * sizeof(float),
               colorSpace,
               kCGBitmapFloatComponents | kCGBitmapByteOrder32Little
            );
            
            CGImageRef cgImage = CGBitmapContextCreateImage(contextRef);
                
            CGColorSpaceRelease(colorSpace);
                
            NSMutableData* imageData = [NSMutableData data];
            CGImageDestinationRef destCG =
            CGImageDestinationCreateWithData((CFMutableDataRef)imageData,
                kUTTypeTIFF, 1, NULL);

            CGImageDestinationAddImage(destCG, cgImage, NULL);
            CGImageDestinationFinalize(destCG);
                        
            [imageData writeToURL:fileURL atomically:YES];
            
            CGImageRelease(cgImage);
            CGContextRelease(contextRef);
            CFRelease(destCG);
        }
        else
        {
            CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
            
            float* colorBuffer = (float*)malloc((_imageHeight + 2) * (_imageWidth + 2) * 4 * sizeof(float));
            [self fillFloatData:colorBuffer withOptions:options];
            
            
            
            CGContextRef contextRef = CGBitmapContextCreate (
               colorBuffer,
               _imageWidth,
               _imageHeight,
               32,
               (_imageWidth) * 4 * sizeof(float),
               colorSpace,
               kCGBitmapFloatComponents | kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast
            );
            
            CGImageRef cgImage = CGBitmapContextCreateImage(contextRef);
                
            CGColorSpaceRelease(colorSpace);
                
            NSMutableData* imageData = [NSMutableData data];
            CGImageDestinationRef destCG =
            CGImageDestinationCreateWithData((CFMutableDataRef)imageData,
                kUTTypeTIFF, 1, NULL);

            CGImageDestinationAddImage(destCG, cgImage, NULL);
            CGImageDestinationFinalize(destCG);
                        
            [imageData writeToURL:fileURL atomically:YES];
            
            CGImageRelease(cgImage);
            CGContextRelease(contextRef);
            CFRelease(destCG);
            free(colorBuffer);
        }

    }
    else if([fileFormat isEqualToString:@"EXR"])
    {
            
        /*if(grayScale)
        {
            BOOL success = [OpenEXRInterface writeGrayScaleData:_buffer
                    width:_imageWidth
                    height:_imageHeight
                    fileName:[fileURL path]];
                    
            if(!success)
            {
                NSLog(@"failed to write exr image to:%@", [fileURL path]);
                NSRunAlertPanel(@"Failed to export EXR image", 
                    @"Please contact the developer of FluidNoise. More information will be contained in your console log.", 
                    @"OK", nil, nil);
            }
        }
        else
        {
            float* colorBuffer = (float*)malloc((_imageHeight + 2) * (_imageWidth + 2) * 4 * sizeof(float));
            [self fillFloatData:colorBuffer withOptions:options];
            
            BOOL success = [OpenEXRInterface writeData:colorBuffer
                    width:_imageWidth
                    height:_imageHeight
                    fileName:[fileURL path]];
                    
            if(!success)
            {
                NSLog(@"failed to write exr image to:%@", [fileURL path]);
                NSRunAlertPanel(@"Failed to export EXR image", 
                    @"Please contact the developer of FluidNoise. More information will be contained in your console log.", 
                    @"OK", nil, nil);
            }
        }*/
    }
    else
    {
        NSLog(@"%@", fileFormat);
    }
}

- (void)mainThreadGenerateAnimationPreviewImageWithOptions:(NSDictionary*)options
{
    NSMutableArray* imageArray = [options objectForKey:@"animationImages"];
    unsigned int frameIndex = [[options objectForKey:@"frameIndex"] intValue];
    
    _animationPreviewBuffers[frameIndex] = (unsigned char*)valloc(_previewRowBytes * _imageHeight);
    
    memcpy(_animationPreviewBuffers[frameIndex], _previewBuffer, _previewRowBytes * _imageHeight);
    
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc ] initWithBitmapDataPlanes:&(_animationPreviewBuffers[frameIndex])
        pixelsWide:_imageWidth
        pixelsHigh:_imageHeight
        bitsPerSample:8
        samplesPerPixel:4
        hasAlpha:YES
        isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace
        bytesPerRow:_imageWidth * 4 * sizeof(unsigned char)
        bitsPerPixel:32];
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(_imageWidth,_imageHeight)];
    
    [image addRepresentation:bitmap];
    [bitmap release];
    
    [imageArray addObject:image];
    [image release];
}

- (void)mainThreadAddImageToMovieWithOptions:(NSDictionary*)options
{
    /*float fps = [[options objectForKey:@"fps"] floatValue];
   
    QTTime durationTime = QTMakeTime(1000, floor(fps * 1000.0f));
    
    NSDictionary* settingsDict = [NSDictionary dictionaryWithObjects:
		[NSArray arrayWithObjects:
			@"tiff",
            [NSNumber numberWithLong:1000000],
			nil]
											   forKeys:
		[NSArray arrayWithObjects:
			QTAddImageCodecType,
            QTTrackTimeScaleAttribute,
			nil]];
            
    
    unsigned char* buffer = (unsigned char*)valloc(_previewRowBytes * _imageHeight);
    
    memcpy(buffer, _previewBuffer, _previewRowBytes * _imageHeight);
    
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc ] initWithBitmapDataPlanes:&(buffer)
        pixelsWide:_imageWidth
        pixelsHigh:_imageHeight
        bitsPerSample:8
        samplesPerPixel:4
        hasAlpha:YES
        isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace
        bytesPerRow:_imageWidth * 4 * sizeof(unsigned char)
        bitsPerPixel:32];
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(_imageWidth,_imageHeight)];
    
    [image addRepresentation:bitmap];
    [bitmap release];
    
    [_quicktimeMovie addImage:image
            forDuration:durationTime
            withAttributes:settingsDict];
            
    free(buffer);
    [image release];*/
}

- (void)resetAnimationBuffers
{
    if(_animationPreviewFrameCount > 0)
    {
        unsigned int i = 0;
        for(i = 0; i < _animationPreviewFrameCount; i++)
        {
            free(_animationPreviewBuffers[i]);
        }
        [_animationPreviewImages release];
        _animationPreviewImages = NULL;
        free(_animationPreviewBuffers);
    }
}

- (void)exportMovieWithInfo:(NSDictionary*)info
{
    
    // - commented out by majicdave before making open souce, this is the old deprectaed quicktime path that FNG used
    /*
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], QTMovieExport,
		[[info objectForKey:@"component"] objectForKey:@"subtype"], QTMovieExportType,
		[[info objectForKey:@"component"] objectForKey:@"manufacturer"], QTMovieExportManufacturer,
		[info objectForKey:@"exportSettings"], QTMovieExportSettings,
		nil];

    if([[NSFileManager defaultManager] fileExistsAtPath:[[info objectForKey:@"fileURL"]relativePath]])
    {
        BOOL success = [[NSFileManager defaultManager] removeFileAtPath:[[info objectForKey:@"fileURL"]relativePath] handler:nil];
        if(!success)
        {
            NSLog(@"something went wrong while trying to delete the old document.");
        }
    }
    
    [_quicktimeMovie writeToFile:[[info objectForKey:@"fileURL"]relativePath] withAttributes:attributes];
    [[NSWorkspace sharedWorkspace] openFile:[[info objectForKey:@"fileURL"]relativePath]];*/
}

- (void)secondaryThreadRedrawWithInfo:(NSDictionary*)info
{
    FNModel* model = [info objectForKey:@"model"];
    BOOL animate = [[info objectForKey:@"animate"] boolValue];
    
    [_animationTimer invalidate];
    [_animationTimer release];
    _animationTimer = NULL;
    
    BOOL turbulent = MOD_B(@"turbulent");
    int width = MOD_I(@"width");
    int height = MOD_I(@"height");
    float amplitude = MOD_F(@"amplitude");
    
    int frequencyX = -MOD_I(@"frequencyX");
    int frequencyY = -MOD_I(@"frequencyY");
    int frequencyZ = MOD_I(@"frequencyZ");
    
    BOOL tile = MOD_B(@"tile");
    
    int output = MOD_I(@"output");
    
    float normalMapHeightScale = MOD_F(@"normalMapHeightScale");
    float environmentMapHeightScale = MOD_F(@"environmentMapHeightScale");
    float distortionImageHeightScale = MOD_F(@"distortionImageHeightScale");
    
    if(output == OUTPUT_TYPE_ENVIRONMENT_MAP)
    {
        NSString* envFileName = [model objectForKey:@"environmentMapFileName"];
        [_environmentMapBitmapImageRep release];
        _environmentMapBitmapImageRep = NULL;
        if([envFileName isEqualToString:@"default"])
        {
            _environmentMapBitmapImageRep = 
                                [[NSBitmapImageRep alloc] initWithData:
                                    [NSData dataWithContentsOfFile:
                                        [[NSBundle mainBundle] pathForResource:@"default_environment_map" ofType:@"jpg"]
                                    ]
                                ];
        }
        else
        {
            NSString* filePath = envFileName;
            if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
            {
                _environmentMapBitmapImageRep = 
                                [[NSBitmapImageRep alloc] initWithData:
                                    [NSData dataWithContentsOfFile:filePath]
                                ];
            }
            else
            {
                NSLog(@"file:%@ no longer exists.", filePath);
                _environmentMapBitmapImageRep = NULL;
            }
        }
    }
    else if(output == OUTPUT_TYPE_IMAGE_DISTORTION)
    {
        NSString* distFileName = [model objectForKey:@"distortionImageFileName"];
        [_distortionImageData autorelease];
        _distortionImageData = NULL;
        if([distFileName isEqualToString:@"default"])
        {
            _distortionImageData = [[FNImageData alloc] initWithPath:
                            [[NSBundle mainBundle] pathForResource:@"default_environment_map" ofType:@"jpg"]];
        }
        else
        {
            NSString* filePath = distFileName;
            if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
            {
                _distortionImageData = [[FNImageData alloc] initWithPath:filePath];
            }
            else
            {
                NSLog(@"file:%@ no longer exists.", filePath);
                _distortionImageData = NULL;
            }
        }
    }
    
    Perlin* perlin = [[Perlin alloc] initWithOctaves:MOD_I(@"octaves")
             frequencyX:frequencyX
             frequencyY:frequencyY
             frequencyZ:frequencyZ
             amplitude:amplitude
                  seed:MOD_I(@"seed")
              tileable:tile
                  loop:MOD_B(@"loop")
           persistance:MOD_F(@"persistance") ];
    
    if(![_redrawQueue empty])
    {
        [perlin release];
        return;
    }
    
    if(_imageWidth != width || _imageHeight != height)
    {
        if(_buffer)
        {
            free(_buffer);
        }
        
        _bufferRowBytes = (width + 2) * sizeof(float);
        int remainder = (_bufferRowBytes % _cacheLineSize);
        if(remainder != 0)
        {
            _bufferRowBytes += _cacheLineSize - remainder;
        }
        _buffer = (float*)valloc(_bufferRowBytes * (height + 2));
        
        
        _previewRowBytes = width * sizeof(unsigned char) * 4;
        remainder = (_previewRowBytes % _cacheLineSize);
        if(remainder != 0)
        {
            _previewRowBytes += _cacheLineSize - remainder;
        }
        if(_previewBuffer)
        {
            //NSLog(@"free");
            free(_previewBuffer);
        }
           // NSLog(@"create");
        _previewBuffer = (unsigned char*)valloc(_previewRowBytes * height);
    }
    
    FNGradient* gradient = [[[model objectForKey:@"gradient"] copy] autorelease];
    
    if(![_redrawQueue empty])
    {
        [perlin release];
        return;
    }
    
    unsigned int numberOfFrames = 1;
    NSMutableArray* animationImages = NULL;
    [_animationPreviewImages release];
    _animationPreviewImages = NULL;
    
    [self resetAnimationBuffers];
    if(animate)
    {
        float duration = [[model objectForKey:@"animationDuration"] floatValue];
        numberOfFrames = duration * PREVIEW_ANIMATION_FPS;
        NSNumber* fpsNumber = [info objectForKey:@"fps"];
        if(fpsNumber)
        {
            numberOfFrames = duration * [fpsNumber floatValue];
        }
        
        _animationPreviewBuffers = (unsigned char**)malloc(sizeof(unsigned char*) * numberOfFrames);
        
        animationImages = [NSMutableArray arrayWithCapacity:numberOfFrames];
    }
    _animationPreviewFrameCount = 0;
    
    unsigned int frameNumber = 0;
    for(frameNumber = 0; frameNumber < numberOfFrames; frameNumber++)
    {
        int thisIndex = _index++;
        
        unsigned int i;
        for(i = 0; i < _processorCount; i++)
        {
            FNThreadSafeQueue* inputQueue = [_inputQueues objectAtIndex:i];
            
            int rowStart = (i * height) / _processorCount;
            int rowEnd = ((i + 1) * height) / _processorCount;
            
            NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithInt:rowStart], @"rowStart",
                        [NSNumber numberWithInt:rowEnd], @"rowEnd",
                        [NSNumber numberWithInt:width], @"width",
                        [NSNumber numberWithInt:height], @"height",
                        [NSNumber numberWithBool:turbulent], @"turbulent",
                        [NSNumber numberWithBool:tile], @"tile",
                        [NSNumber numberWithFloat:amplitude], @"amplitude",
                        [NSNumber numberWithInt:thisIndex], @"index",
                        [NSNumber numberWithFloat:((float)frameNumber / numberOfFrames)], @"zFraction",
                        perlin, @"perlin",
                        gradient, @"gradient",
                        [NSNumber numberWithInt:output], @"output",
                        [NSNumber numberWithFloat:normalMapHeightScale], @"normalMapHeightScale",
                        [NSNumber numberWithFloat:environmentMapHeightScale], @"environmentMapHeightScale",
                        [NSNumber numberWithFloat:distortionImageHeightScale], @"distortionImageHeightScale",
                    nil];
            [inputQueue enqueue:dict];
        }
        
        if(![_redrawQueue empty])
        {
            [perlin release];
            return;
        }
        
        for(i = 0; i < _processorCount; i++)
        {
            int foundIndex = -1;
            FNThreadSafeQueue* outputQueue = [_outputQueues objectAtIndex:i];
            while(foundIndex != thisIndex)
            {
                id object = [outputQueue dequeue];
                foundIndex = [object intValue];
            }
        }
        
        NSData* safeData = [NSData dataWithBytes:_previewBuffer length:_previewRowBytes * height];

        
        
        NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithInt:width], @"width",
                        [NSNumber numberWithInt:height], @"height",
                        safeData, @"data",
                    nil];
                    
        if(![_redrawQueue empty])
        {
            [perlin release];
            return;
        }
        
        //[self mainThreadGeneratePreviewImageWithOptions:options];
        
                [self performSelectorOnMainThread:@selector(mainThreadGeneratePreviewImageWithOptions:)
                            withObject:options 
                            waitUntilDone:NO];
        
        
        /*if(![_redrawQueue empty])
        {
            [perlin release];
            return;
        }*/
                            
        if(animate)
        {
            NSURL* fileURL = [info objectForKey:@"fileURL"];
            if(fileURL) // exporting
            {
                // - commented out by majicdave before making open souce, this is the old deprectaed quicktime path that FNG used
                /*NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                        [info objectForKey:@"fps"], @"fps",
                        safeData, @"data",
                    nil];
                [self mainThreadAddImageToMovieWithOptions:options];*/
            }
            else
            {
                options = [NSDictionary dictionaryWithObjectsAndKeys:
                            animationImages, @"animationImages",
                            [NSNumber numberWithInt:_animationPreviewFrameCount], @"frameIndex",
                        nil];
                [self performSelectorOnMainThread:@selector(mainThreadGenerateAnimationPreviewImageWithOptions:)
                                    withObject:options 
                                    waitUntilDone:YES];
                _animationPreviewFrameCount++;
            }
        }
        else
        {
            NSURL* fileURL = [info objectForKey:@"fileURL"];
            if(fileURL)
            {
                NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                        safeData, @"data",
                        [info objectForKey:@"fileURL"], @"fileURL",
                        [info objectForKey:@"fileType"], @"fileType",
                        [info objectForKey:@"bpp"], @"bpp",
                        [info objectForKey:@"grayScale"], @"grayScale",
                        [NSNumber numberWithInt:width], @"width",
                        [NSNumber numberWithInt:height], @"height",
                        [NSNumber numberWithBool:turbulent], @"turbulent",
                        [NSNumber numberWithBool:tile], @"tile",
                        [NSNumber numberWithFloat:amplitude], @"amplitude",
                        [NSNumber numberWithInt:thisIndex], @"index",
                        [NSNumber numberWithFloat:((float)frameNumber / numberOfFrames)], @"zFraction",
                        perlin, @"perlin",
                        gradient, @"gradient",
                        [NSNumber numberWithInt:output], @"output",
                        [NSNumber numberWithFloat:normalMapHeightScale], @"normalMapHeightScale",
                        [NSNumber numberWithFloat:environmentMapHeightScale], @"environmentMapHeightScale",
                        [NSNumber numberWithFloat:distortionImageHeightScale], @"distortionImageHeightScale",
                    nil];
                [self performSelectorOnMainThread:@selector(mainThreadExportImageWithOptions:)
                                withObject:options 
                                waitUntilDone:YES];
                                
                [_exportDelegate performSelector:_exportAction withObject:self];
            }
            else
            {
            }
        }
    }
    
    _needsProgressIndicatorHidden = YES;
    _imageIsOpaque = [(FNGradient*)[model objectForKey:@"gradient"] isOpaque];
    
    if(animate)
    {
        _animationPreviewImages = [animationImages copy];
        if([info objectForKey:@"fileURL"])
        {
            NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                        [info objectForKey:@"fileURL"], @"fileURL",
                        [info objectForKey:@"fps"], @"fps",
                        [info objectForKey:@"exportSettings"], @"exportSettings",
                        [info objectForKey:@"component"], @"component",
                    nil];
            /*[self performSelectorOnMainThread:@selector(exportMovieWithInfo:)
                                    withObject:options 
                                    waitUntilDone:YES];*/
            [self exportMovieWithInfo:options];
                                    
            [_exportDelegate performSelector:_exportAction withObject:self];

        }
        else
        {
            [self performSelectorOnMainThread:@selector(createTimer:)
                                        withObject:nil 
                                        waitUntilDone:YES];
        }
    }
    
    [perlin release];
}

- (void)createTimer:(id)stuff
{
     NSTimeInterval timeInterval = 1.0f / PREVIEW_ANIMATION_FPS;

    _animationTimer = [[NSTimer scheduledTimerWithTimeInterval:timeInterval
                        target:self
                        selector:@selector(drawAnimation)
                        userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSEventTrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSModalPanelRunLoopMode];
}

- (void)drawAnimation
{
    [self setNeedsDisplay:YES];
}

- (void)redrawThreadWithQueue:(FNThreadSafeQueue*)queue
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    while(1)
    {
        NSDictionary* info = [queue dequeue];
        while(![queue empty])
        {
            info = [queue dequeue];
        }
        
        [self secondaryThreadRedrawWithInfo:info];
        
		[pool release];
        pool = [[NSAutoreleasePool alloc] init];
	}
}

- (BOOL)progressBarRequiredForModelUpdate:(FNModel*)model
{
    int widthTimesHeight = MOD_I(@"width") * MOD_I(@"height");
    return widthTimesHeight > 2000 * 2000 / (MOD_I(@"octaves") + 8);
}

- (void)redrawWithModel:(FNModel*)model
{
    if([self progressBarRequiredForModelUpdate:model])
    {
       _needsProgressIndicatorShown = YES;
    }
    [self setNeedsDisplay:YES];
    
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
        model, @"model",
        [NSNumber numberWithBool:NO], @"animate",
        nil];
    
    [_redrawQueue enqueue:info];
}


- (void)generatePreviewAnimationWithModel:(FNModel*)model
{
    _needsProgressIndicatorShown = YES;
    [self setNeedsDisplay:YES];
    
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
        model, @"model",
        [NSNumber numberWithBool:YES], @"animate",
        nil];
        
    [_redrawQueue enqueue:info];
}

- (void)drawGridInRect:(NSRect)inRect fromRect:(NSRect)fromRect
{
    if(!_imageIsOpaque || ![_progressIndicator isHidden] || _needsProgressIndicatorShown)
    {
        CIImage* outputImage = [_gridFilter valueForKey:@"outputImage"];
        [outputImage drawInRect:inRect fromRect:fromRect operation:NSCompositeCopy fraction:1.0f];
    }
}

- (void)drawRect:(NSRect)rect
{
    [self updateProgressIndicatorPosition];
    
    if(!_image)
    {
        return;
    }
    NSSize contentSize = [[self enclosingScrollView] contentSize];
    
    int xOffset = 0;
    int yOffset = 0;
    if(contentSize.width > _imageWidth)
    {
        xOffset = contentSize.width * 0.5f - _imageWidth * 0.5f;
    }
    if(contentSize.height > _imageHeight)
    {
        yOffset = contentSize.height * 0.5f - _imageHeight * 0.5f;
    }
    
    [self drawGridInRect:NSMakeRect(xOffset, 
                                    yOffset, 
                                    _imageWidth, 
                                    _imageHeight)
                        fromRect:NSMakeRect(0.0f, 
                                    0.0f, 
                                    _imageWidth, 
                                    _imageHeight)];
    
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:NSMakeRect((float)xOffset - 0.5f, 
                                    (float)yOffset - 0.5f, 
                                    (float)_imageWidth + 1.0f, 
                                    (float)_imageHeight + 1.0f)];
    [path setLineJoinStyle:NSMiterLineJoinStyle];
    [path setLineWidth:1.0f];
    [[NSColor blackColor] set];
    [path stroke];
    
    _imageOffset = NSMakePoint(xOffset, yOffset);
    
    float fraction = 1.0f;
    if((_needsProgressIndicatorShown && !_needsProgressIndicatorHidden) || (![_progressIndicator isHidden] && !_needsProgressIndicatorHidden))
    {
        fraction = 0.2f;
    }
    
    NSImage* imageToDraw = _image;
    if(_animationPreviewImages && [_animationPreviewImages count] > 0 && _animationTimer)
    {
        _currentAnimationFrameIndexToDraw = (++_currentAnimationFrameIndexToDraw) % _animationPreviewFrameCount;
        imageToDraw = [_animationPreviewImages objectAtIndex:_currentAnimationFrameIndexToDraw];
    }
    
    [imageToDraw drawInRect:NSMakeRect(xOffset, 
                                    yOffset, 
                                    _imageWidth, 
                                    _imageHeight) 
                                fromRect:NSMakeRect(0.0f, 
                                    0.0f, 
                                    _imageWidth, 
                                    _imageHeight)
                                operation:NSCompositeSourceOver 
                                fraction:fraction];
    
    
    if(_needsProgressIndicatorHidden)
    {
        [_progressIndicator setHidden:YES];
        [_progressIndicator stopAnimation:self];
        _needsProgressIndicatorHidden = NO;
        _needsProgressIndicatorShown = NO;
    }
    else if(_needsProgressIndicatorShown)
    {
        [_progressIndicator setHidden:NO];
        [_progressIndicator startAnimation:self];
        _needsProgressIndicatorShown = NO;
    }
    
}

- (void)startDragDrop:(NSEvent*)event
{
    
    NSPasteboard* pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSFilesPromisePboardType]  owner:self];
    
    NSSize previewSize = NSMakeSize(DRAG_PREVIEW_MAX_SIZE,DRAG_PREVIEW_MAX_SIZE);
    if([_image size].width > [_image size].height)
    {
        previewSize.width = [_image size].width;
        previewSize.width = previewSize.width > DRAG_PREVIEW_MAX_SIZE ? DRAG_PREVIEW_MAX_SIZE : previewSize.width;
        previewSize.height = previewSize.width * ([_image size].height / [_image size].width);
    }
    else
    {
        previewSize.height = [_image size].height;
        previewSize.height = previewSize.height > DRAG_PREVIEW_MAX_SIZE ? DRAG_PREVIEW_MAX_SIZE : previewSize.height;
        previewSize.width = previewSize.height * ([_image size].width / [_image size].height);
    }
    
    NSImage* dragImage = [[NSImage alloc] initWithSize:previewSize];
    [dragImage lockFocus];
    [_image drawInRect:NSMakeRect(0.0f,0.0f,previewSize.width, previewSize.height)
            fromRect:NSMakeRect(0.0f,0.0f, [_image size].width, [_image size].height)
            operation:NSCompositeSourceOver 
            fraction:0.5f];
    [dragImage unlockFocus];
    
    NSPoint mousePosition = [self convertPoint:[event locationInWindow]
                        fromView:nil];
                        
    NSPoint mouseOffsetFromImageBLCorner = NSMakePoint((mousePosition.x - _imageOffset.x), (mousePosition.y - _imageOffset.y));
    
    NSSize offsetFraction = NSMakeSize(mouseOffsetFromImageBLCorner.x / [_image size].width, mouseOffsetFromImageBLCorner.y / [_image size].height);
   
    NSPoint dragOffset = NSMakePoint(_imageOffset.x + ([_image size].width - previewSize.width) * offsetFraction.width, 
                                     _imageOffset.y + ([_image size].height - previewSize.height) * offsetFraction.height);
    
    [self dragImage:dragImage
                at:dragOffset
                offset:NSMakeSize(0.0f,0.0f)
                event:event
                pasteboard:pboard 
                source:self
                slideBack:YES];
}

- (void)setDragDropFileName:(NSString*)dragDropFileName
{
    _dragDropFileName = [dragDropFileName retain];
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
    if([type compare:NSFilesPromisePboardType]==NSOrderedSame)
    {
        [sender setPropertyList:[NSArray arrayWithObject:@"png"] forType:NSFilesPromisePboardType];
    }
}

- (NSArray*)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
    //NSLog(@"%@", dropDestination);
    NSString* baseFileName = _dragDropFileName;
    if(!baseFileName)
    {
        baseFileName = @"FluidNoiseOutput";
    }
    
    NSString* fileName = [baseFileName stringByAppendingString:@".png"];
    
    NSString* dropDestinationString = [dropDestination relativePath];
    NSString* dropDestinationURLString = [dropDestination absoluteString];
    
    //NSLog(@"dropDestinationString:%@",dropDestinationString);
    
    NSString* absoluteFile = [dropDestinationString stringByAppendingFormat:@"/%@", fileName];
    int index = 2;
    while([[NSFileManager defaultManager] fileExistsAtPath:absoluteFile])
    {
        fileName = [baseFileName stringByAppendingFormat:@"-%d.png", index];
        absoluteFile = [dropDestinationString stringByAppendingFormat:@"/%@", fileName];
        index++;
    }
    
    NSData* pngData = [(NSBitmapImageRep*)[[_image representations] objectAtIndex:0] representationUsingType:NSPNGFileType
                properties:[NSDictionary dictionary]];
                
    NSString* escapedURLPath = [[dropDestinationURLString stringByAppendingString:fileName] 
                                    stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
   [pngData writeToURL:[NSURL URLWithString:escapedURLPath] atomically:YES];
    
    return [NSArray arrayWithObject:fileName];
}

- (void)mouseDragged:(NSEvent*)event
{
    NSPoint dragPosition = [self convertPoint:[event locationInWindow]
                        fromView:nil];
    NSRect imageRect;
    imageRect.size = [_image size];
    imageRect.origin = _imageOffset;
    
    if(NSPointInRect(dragPosition, imageRect))
    {
        [self startDragDrop:event];
    }
}


- (void)exportImageToURL:(NSURL*)url
                ofType:(NSString*)type
                bpp:(NSNumber*)bpp
                grayScale:(NSNumber*)grayScale
                model:(FNModel*)model
                delegate:(id)exportDelegate
                didEndSelector:(SEL)exportAction
{
    _exportDelegate = exportDelegate;
    _exportAction = exportAction;
    
    [self setNeedsDisplay:YES];
    
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
        model, @"model",
        [NSNumber numberWithBool:NO], @"animate",
        url, @"fileURL",
        type, @"fileType",
        bpp, @"bpp",
        grayScale, @"grayScale",
        nil];
    
    [_redrawQueue enqueue:info];
}

- (void)exportAnimationToURL:(NSURL*)url
                    withExportSettings:(NSData*)exportSettings
                    fps:(float)fps
                    component:(NSDictionary*)component
                    model:(FNModel*)model
                    delegate:(id)exportDelegate
                    didEndSelector:(SEL)exportAction
{
    
    _exportDelegate = exportDelegate;
    _exportAction = exportAction;
   // NSLog(@"exportAnimationToURL %@", _quicktimeMovie);
    //[_quicktimeMovie autorelease];
    [movieData autorelease];
     
    NSSize size;
    size.width = [[model objectForKey:@"width"] intValue];
    size.height = [[model objectForKey:@"height"] intValue];
    
    movieData = [[NSMutableData alloc]init];
    
    /*NSError* error;
    _quicktimeMovie = [[FNMovie alloc] initToWritableData:movieData error:&error];
    [_quicktimeMovie setIdling:NO];*/
    
    [self setNeedsDisplay:YES];
    
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
        model, @"model",
        url, @"fileURL",
        [NSNumber numberWithBool:YES], @"animate",
        exportSettings, @"exportSettings",
        [NSNumber numberWithFloat:fps], @"fps",
        component, @"component",
        nil];
    
    [_redrawQueue enqueue:info];
}

- (NSView*)printableView
{
    NSImageView* imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0,0,[_image size].width, [_image size].height)];
    [imageView setImage:_image];
    return [imageView autorelease];
}

- (void)dealloc
{
    [_redrawQueue release];
    [_progressIndicator release];
    [self resetAnimationBuffers];
    [_animationTimer invalidate];
    [_animationTimer release];
    [_gridFilter release];
    [_dragDropFileName release];
    //[_quicktimeMovie release];
    [_environmentMapBitmapImageRep release];
    [_distortionImageData release];
    [movieData release];
    [super dealloc];
}

@end
