
#import <Cocoa/Cocoa.h>
//#import <Quicktime/Quicktime.h> // - commented out by majicdave before making open souce, this is the old deprectaed quicktime path that FNG used

@class FNModel;
@class FNThreadSafeQueue;

//@class FNMovie;
@class FNImageData;

@interface FNView : NSView {
    float* _buffer;
    unsigned char* _previewBuffer;
    NSData* _safePreviewData;
    
    NSBitmapImageRep* _environmentMapBitmapImageRep;
    FNImageData* _distortionImageData;
    
    unsigned char** _animationPreviewBuffers;
    NSArray* _animationPreviewImages;
    unsigned int _animationPreviewFrameCount;
    NSTimer* _animationTimer;
    unsigned int _currentAnimationFrameIndexToDraw;
    
    NSImage* _image;
    
    BOOL _imageIsOpaque;
    
    int _imageWidth;
    int _imageHeight;
    
    int _bufferRowBytes;
    int _previewRowBytes;
    
    int _processorCount;
    int _cacheLineSize;
    
    NSArray* _inputQueues;
    NSArray* _outputQueues;
    
    FNThreadSafeQueue* _redrawQueue;
    
    int _index;
    
    NSPoint _imageOffset;
    
    NSProgressIndicator* _progressIndicator;
    BOOL _needsProgressIndicatorHidden;
    BOOL _needsProgressIndicatorShown;
    
    CIFilter* _gridFilter;
    
    NSString* _dragDropFileName;
    
    id _exportDelegate;
    SEL _exportAction;
    
    //FNMovie* _quicktimeMovie;
    NSMutableData* movieData;
    
    BOOL unSafeToOverwritePreviewBuffer;
}

- (void)redrawWithModel:(FNModel*)model;
- (void)generatePreviewAnimationWithModel:(FNModel*)model;
- (void)setDragDropFileName:(NSString*)dragDropFileName;

- (void)exportImageToURL:(NSURL*)url
                ofType:(NSString*)type
                bpp:(NSNumber*)bpp
                grayScale:(NSNumber*)grayScale
                model:(FNModel*)model
                delegate:(id)exportDelegate
                didEndSelector:(SEL)exportAction;
                
- (void)exportAnimationToURL:(NSURL*)url
                    withExportSettings:(NSData*)exportSettings
                    fps:(float)fps
                    component:(NSDictionary*)component
                    model:(FNModel*)model
                    delegate:(id)exportDelegate
                    didEndSelector:(SEL)exportAction;

- (NSView*)printableView;

@end
