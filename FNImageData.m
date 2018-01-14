

#import "FNImageData.h"

#define Assert(condition, fmt, ...)             \
    if (!(condition))                           \
        [NSException raise:@"Image Load Exception" \
                    format:fmt, ##__VA_ARGS__]
#define AssertNonNull(pointer, fmt, ...) \
    Assert((pointer) != NULL, fmt, ##__VA_ARGS__)


@implementation FNImageData

- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    CFURLRef textureUrl = (CFURLRef)[NSURL fileURLWithPath:path];

	CGImageSourceRef imageSource = CGImageSourceCreateWithURL(
	    textureUrl,
	    NULL);
	AssertNonNull(
	    imageSource,
	    @"Can't create image source for %@",
	    path);
	Assert(
	    CGImageSourceGetCount(imageSource) > 0,
	    @"No images found in %@",
	    path);

	CGImageRef image = CGImageSourceCreateImageAtIndex(
	    imageSource,
	    0,
	    NULL);
	AssertNonNull(
	    image,
	    @"Can't create image for %@",
	    path);

	_width = (int)CGImageGetWidth(image);
	_height = (int)CGImageGetHeight(image);

	_data = calloc(1, _width * _height * 4);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	AssertNonNull(
	    colorSpace,
	    @"Can't create RGB color space to load %@",
	    path);

	CGContextRef context = CGBitmapContextCreate(
	    _data,
	    _width,
	    _height,
	    8,
	    _width * 4,
	    colorSpace,
	    kCGImageAlphaPremultipliedFirst);
	AssertNonNull(
	    context,
	    @"Can't create bitmap context to draw %@",
	    path);

	CGContextDrawImage(
	    context,
	    CGRectMake(0, 0, _width, _height),
	    image);
        
    CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	CGImageRelease(image);
	CFRelease(imageSource);
    
    return self;
}

- (unsigned char*)data
{
    return (unsigned char*)_data;
}

- (unsigned)width
{
    return _width;
}

- (unsigned)height
{
    return _height;
}

- (void)dealloc
{
	free(_data);
    [super dealloc];
}
        
@end
