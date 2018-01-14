#import <Cocoa/Cocoa.h>

#define SAMPLE_SIZE 4096

typedef struct PerlinStruct {
    int p[SAMPLE_SIZE + SAMPLE_SIZE + 2];
    double g3[SAMPLE_SIZE + SAMPLE_SIZE + 2][3];
    double g2[SAMPLE_SIZE + SAMPLE_SIZE + 2][2];

    int octaves;
    int frequencyX;
    int frequencyY;
    int frequencyZ;
    double amplitude;
    double persistance;
    BOOL tiling;
    BOOL loop;
} PerlinStruct;

@interface Perlin : NSObject {

    BOOL _tileable;
    PerlinStruct* _structPtr;
}

- (id)initWithOctaves:(int)octaves 
             frequencyX:(int)frequencyX 
             frequencyY:(int)frequencyY 
             frequencyZ:(int)frequencyZ 
             amplitude:(double)amplitude 
                  seed:(int)seed 
              tileable:(BOOL)tileable
                  loop:(BOOL)loop
           persistance:(double)persistance;

- (double) getX:(double)x Y:(double)y;
- (double) getX:(double)x Y:(double)y Z:(double)z;

@end