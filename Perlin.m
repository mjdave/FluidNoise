#import "Perlin.h"
#import "fn_random.h"

#define B SAMPLE_SIZE
#define BM (SAMPLE_SIZE-1)

#define N 0x1000
#define NP 12   /* 2^N */
#define NM 0xfff

#define s_curve(t) ( t * t * (3.0f - 2.0f * t) )
#define lerp(t, a, b) ( a + t * (b - a) )

#define setupt(i,b0,b1,r0,r1, level)\
        t = vec[i] + N;\
        b0 = (((int)t) & BM) % level;\
        b1 = ((b0+1) & BM) % level;\
        r0 = t - (int)t;\
        r1 = r0 - 1.0f;

#define setup(i,b0,b1,r0,r1)\
        t = vec[i] + N;\
        b0 = (((int)t) & BM);\
        b1 = ((b0+1) & BM);\
        r0 = t - (int)t;\
        r1 = r0 - 1.0f;
        
#define normalize2(v) \
    double s; \
    s = (double)sqrt(v[0] * v[0] + v[1] * v[1]); \
    s = 1.0f/s; \
    v[0] = v[0] * s; \
    v[1] = v[1] * s;
    
#define normalize3(v) \
    double d;\
    d = (double)sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);\
    d = 1.0f/d;\
    v[0] = v[0] * d;\
    v[1] = v[1] * d;\
    v[2] = v[2] * d;
    
    
#define PI 3.14159265

static inline double noise2(double* vec, PerlinStruct* structPtr, int xlevel, int ylevel) 
{
    int bx0, bx1, by0, by1, b00, b10, b01, b11;
    double rx0, rx1, ry0, ry1, *q, sx, sy, a, b, t, u, v;
    int i, j;
    
    if(structPtr->tiling)
    {
        setupt(0,bx0,bx1,rx0,rx1,xlevel);
        setupt(1,by0,by1,ry0,ry1,ylevel);
    }
    else
    {
        setup(0,bx0,bx1,rx0,rx1);
        setup(1,by0,by1,ry0,ry1);
    }

    i = structPtr->p[bx0];
    j = structPtr->p[bx1];

    b00 = structPtr->p[i + by0];
    b10 = structPtr->p[j + by0];
    b01 = structPtr->p[i + by1];
    b11 = structPtr->p[j + by1];

    sx = s_curve(rx0);
    sy = s_curve(ry0);

    #define at2(rx,ry) ( rx * q[0] + ry * q[1] )

    q = structPtr->g2[b00];
    u = at2(rx0,ry0);
    q = structPtr->g2[b10];
    v = at2(rx1,ry0);
    a = lerp(sx, u, v);

    q = structPtr->g2[b01];
    u = at2(rx0,ry1);
    q = structPtr->g2[b11];
    v = at2(rx1,ry1);
    b = lerp(sx, u, v);
    return lerp(sy, a, b);
}

static inline double noise3(double* vec, PerlinStruct* structPtr, int xlevel, int ylevel, int zlevel)
{
    int bx0, bx1, by0, by1, bz0, bz1, b00, b10, b01, b11;
    double rx0, rx1, ry0, ry1, rz0, rz1, *q, sy, sz, a, b, c, d, t, u, v;
    int i, j;

    //setup(0, bx0,bx1, rx0,rx1);
   // setup(1, by0,by1, ry0,ry1);
   // setup(2, bz0,bz1, rz0,rz1);
    
    if(structPtr->tiling)
    {
        setupt(0,bx0,bx1,rx0,rx1,xlevel);
        setupt(1,by0,by1,ry0,ry1,ylevel);
    }
    else
    {
        setup(0,bx0,bx1,rx0,rx1);
        setup(1,by0,by1,ry0,ry1);
    }
    
    if(structPtr->loop)
    {
        setupt(2,bz0,bz1,rz0,rz1,zlevel);
    }
    else
    {
        setup(2,bz0,bz1,rz0,rz1);
    }

    i = structPtr->p[ bx0 ];
    j = structPtr->p[ bx1 ];

    b00 = structPtr->p[ i + by0 ];
    b10 = structPtr->p[ j + by0 ];
    b01 = structPtr->p[ i + by1 ];
    b11 = structPtr->p[ j + by1 ];

    t  = s_curve(rx0);
    sy = s_curve(ry0);
    sz = s_curve(rz0);

    #define at3(rx,ry,rz) ( rx * q[0] + ry * q[1] + rz * q[2] )

    q = structPtr->g3[ b00 + bz0 ] ; u = at3(rx0,ry0,rz0);
    q = structPtr->g3[ b10 + bz0 ] ; v = at3(rx1,ry0,rz0);
    a = lerp(t, u, v);

    q = structPtr->g3[ b01 + bz0 ] ; u = at3(rx0,ry1,rz0);
    q = structPtr->g3[ b11 + bz0 ] ; v = at3(rx1,ry1,rz0);
    b = lerp(t, u, v);

    c = lerp(sy, a, b);

    q = structPtr->g3[ b00 + bz1 ] ; u = at3(rx0,ry0,rz1);
    q = structPtr->g3[ b10 + bz1 ] ; v = at3(rx1,ry0,rz1);
    a = lerp(t, u, v);

    q = structPtr->g3[ b01 + bz1 ] ; u = at3(rx0,ry1,rz1);
    q = structPtr->g3[ b11 + bz1 ] ; v = at3(rx1,ry1,rz1);
    b = lerp(t, u, v);

    d = lerp(sy, a, b);

    return lerp(sz, c, d);
}

static inline double perlin_noise_2D(double* vec, PerlinStruct* structPtr)
{
    double result = 0.0f;
    double amp = structPtr->amplitude;
    
    unsigned int feqPowX = 1 << structPtr->frequencyX;
    unsigned int feqPowY = 1 << structPtr->frequencyY;
    
    vec[0]*=feqPowX;
    vec[1]*=feqPowY;
    
    unsigned int i;
    for( i = 0; i<structPtr->octaves; i++ )
    {
        int modX = feqPowX << i;
        int modY = feqPowY << i;
        modX = modX < 1 ? 1 : modX;
        modY = modY < 1 ? 1 : modY;
        
        double value = noise2(vec, structPtr, modX, modY);
        
        result += value * amp;
        vec[0] *= 2.0f;
        vec[1] *= 2.0f;
        
        amp*=structPtr->persistance;
    }
    
    return result;
}

static inline double perlin_noise_3D(double* vec, PerlinStruct* structPtr)
{
    double result = 0.0f;
    double amp = structPtr->amplitude;
    
    unsigned int feqPowX = 1;
    unsigned int feqPowY = 1;
    unsigned int feqPowZ = 1;
    
    int dividerX = 0;
    int dividerY = 0;
    int dividerZ = 0;
    
    double fractionX = vec[0];
    double fractionY = vec[1];
    double fractionZ = vec[2];
    
    double multiplierX = 1.0f;
    double multiplierY = 1.0f;
    double multiplierZ = 1.0f;
    
    if(structPtr->frequencyX >= 0)
    {
        feqPowX = 1 << structPtr->frequencyX;
        vec[0]*=feqPowX;
        multiplierX*=feqPowX;
    }
    else
    {
        dividerX = -structPtr->frequencyX;
        vec[0]/= 1 << dividerX;
        multiplierX/=1 << dividerX;
    }
    
    if(structPtr->frequencyY >= 0)
    {
        feqPowY = 1 << structPtr->frequencyY;
        vec[1]*=feqPowY;
        multiplierY*=feqPowY;
    }
    else
    {
        dividerY = -structPtr->frequencyY;
        vec[1]/= 1 << dividerY;
        multiplierY/=1 << dividerY;
    }
    
    if(structPtr->frequencyZ >= 0)
    {
        feqPowZ = 1 << structPtr->frequencyZ;
        vec[2]*=feqPowZ;
        multiplierZ*=feqPowZ;
    }
    else
    {
        dividerZ = -structPtr->frequencyZ;
        vec[2]/= 1 << dividerZ;
        multiplierZ/=1 << dividerZ;
    }

    
    int i;
    for( i = 0; i<structPtr->octaves; i++ )
    {
        int modX = feqPowX << (i - dividerX);
        int modY = feqPowY << (i - dividerY);
        int modZ = feqPowZ << (i - dividerZ);
        modX = modX < 1 ? 1 : modX;
        modY = modY < 1 ? 1 : modY;
        modZ = modZ < 1 ? 1 : modZ;

        double value = noise3(vec, structPtr, modX, modY, modZ);
        
        if(structPtr->tiling && (dividerY > i || dividerX > i))
        {
            if(dividerX > i)
            {
                if(dividerY > i)
                {
                    if(structPtr->loop && dividerZ > i) // x y and z
                    {
                        double v2[3];
                    
                        v2[0] = vec[0];
                        v2[1] = vec[1] - multiplierY;
                        v2[2] = vec[2];
                        double b = noise3(v2, structPtr, modX, modY, modZ);
                    
                        v2[0] = vec[0] - multiplierX;
                        v2[1] = vec[1] - multiplierY;
                        v2[2] = vec[2];
                        double c = noise3(v2, structPtr, modX, modY, modZ);
                    
                        v2[0] = vec[0] - multiplierX;
                        v2[1] = vec[1];
                        v2[2] = vec[2];
                        double d = noise3(v2, structPtr, modX, modY, modZ);
                    
                        v2[0] = vec[0];
                        v2[1] = vec[1];
                        v2[2] = vec[2] - multiplierZ;
                        double e = noise3(v2, structPtr, modX, modY, modZ);
                    
                        v2[0] = vec[0];
                        v2[1] = vec[1] - multiplierY;
                        v2[2] = vec[2] - multiplierZ;
                        double f = noise3(v2, structPtr, modX, modY, modZ);
                        
                        v2[0] = vec[0] - multiplierX;
                        v2[1] = vec[1] - multiplierY;
                        v2[2] = vec[2] - multiplierZ;
                        double g = noise3(v2, structPtr, modX, modY, modZ);
                        
                        v2[0] = vec[0] - multiplierX;
                        v2[1] = vec[1];
                        v2[2] = vec[2] - multiplierZ;
                        double h = noise3(v2, structPtr, modX, modY, modZ);
                        
                        value = value * (1.0f - fractionX) *    (1.0f - fractionY) *    (1.0f - fractionZ) + 
                                b *     (1.0f - fractionX) *    fractionY *             (1.0f - fractionZ) +
                                c *     fractionX *             fractionY *             (1.0f - fractionZ) +
                                d *     fractionX *             (1.0f - fractionY) *    (1.0f - fractionZ) + 
                                e *     (1.0f - fractionX) *    (1.0f - fractionY) *    fractionZ +
                                f *     (1.0f - fractionX) *    fractionY *             fractionZ +
                                g *     fractionX *             fractionY *             fractionZ +
                                h *     fractionX *             (1.0f - fractionY) *    fractionZ;
                    }
                    else // x and y, no z
                    {
                        double v2[3];
                    
                        v2[0] = vec[0];
                        v2[1] = vec[1] - multiplierY;
                        v2[2] = vec[2];
                        double valueStartYA = noise3(v2, structPtr, modX, modY, modZ);
                    
                        v2[0] = vec[0] - multiplierX;
                        v2[1] = vec[1] - multiplierY;
                        v2[2] = vec[2];
                        double valueStartYB = noise3(v2, structPtr, modX, modY, modZ);
                    
                        v2[0] = vec[0] - multiplierX;
                        v2[1] = vec[1];
                        v2[2] = vec[2];
                        double valueStartXA = noise3(v2, structPtr, modX, modY, modZ);
                        
                        value = value * (1.0f - fractionX) * (1.0f - fractionY) + 
                                valueStartYA * (1.0f - fractionX) * fractionY +
                                valueStartYB * fractionX * fractionY + 
                                valueStartXA * fractionX * (1.0f - fractionY);
                    }
                }
                else if(structPtr->loop && dividerZ > i) // x and z, no y
                {
                    double vecstartZA[3];
                
                    vecstartZA[0] = vec[0];
                    vecstartZA[1] = vec[1];
                    vecstartZA[2] = vec[2] - multiplierZ;
                    
                    double valueStartZA = noise3(vecstartZA, structPtr, modX, modY, modZ);
                    
                    double vecstartZB[3];
                
                    vecstartZB[0] = vec[0] - multiplierX;
                    vecstartZB[1] = vec[1];
                    vecstartZB[2] = vec[2] - multiplierZ;
                    
                    double valueStartZB = noise3(vecstartZB, structPtr, modX, modY, modZ);
                    
                    double vecstartXA[3];
                
                    vecstartXA[0] = vec[0] - multiplierX;
                    vecstartXA[1] = vec[1];
                    vecstartXA[2] = vec[2];
                    
                    double valueStartXA = noise3(vecstartXA, structPtr, modX, modY, modZ);
                    
                    value = value * (1.0f - fractionX) * (1.0f - fractionZ) + 
                            valueStartZA * (1.0f - fractionX) * fractionZ +
                            valueStartZB * fractionX * fractionZ + 
                            valueStartXA * fractionX * (1.0f - fractionZ);
                }
                else // x only
                {
                    double vecstartX[3];
                
                    vecstartX[0] = vec[0] - multiplierX;
                    vecstartX[1] = vec[1];
                    vecstartX[2] = vec[2];
                    
                    double valueStartX = noise3(vecstartX, structPtr, modX, modY, modZ);
                    
                    value = value * (1.0f - fractionX) + valueStartX * fractionX;
                }
            }
            else // y
            {
                if(structPtr->loop && dividerZ > i) // y and z, no x
                {
                    double vecstartZA[3];
                
                    vecstartZA[0] = vec[0];
                    vecstartZA[1] = vec[1];
                    vecstartZA[2] = vec[2] - multiplierZ;
                    
                    double valueStartZA = noise3(vecstartZA, structPtr, modX, modY, modZ);
                    
                    double vecstartZB[3];
                
                    vecstartZB[0] = vec[0];
                    vecstartZB[1] = vec[1] - multiplierY;
                    vecstartZB[2] = vec[2] - multiplierZ;
                    
                    double valueStartZB = noise3(vecstartZB, structPtr, modX, modY, modZ);
                    
                    double vecstartYA[3];
                
                    vecstartYA[0] = vec[0];
                    vecstartYA[1] = vec[1] - multiplierY;
                    vecstartYA[2] = vec[2];
                    
                    double valueStartYA = noise3(vecstartYA, structPtr, modX, modY, modZ);
                    
                    value = value * (1.0f - fractionY) * (1.0f - fractionZ) + 
                            valueStartZA * (1.0f - fractionY) * fractionZ +
                            valueStartZB * fractionY * fractionZ + 
                            valueStartYA * fractionY * (1.0f - fractionZ);
                }
                else // y only
                {
                    double vecstartY[3];
                
                    vecstartY[0] = vec[0];
                    vecstartY[1] = vec[1] - multiplierY;
                    vecstartY[2] = vec[2];
                    
                    double valueStartY = noise3(vecstartY, structPtr, modX, modY, modZ);
                    
                    value = value * (1.0f - fractionY) + valueStartY * fractionY;
                }
            }
        }
        else if(structPtr->loop && dividerZ > i) // z only
        {
            double vecstartZ[3];
            
            vecstartZ[0] = vec[0];
            vecstartZ[1] = vec[1];
            vecstartZ[2] = vec[2] - multiplierZ;
            
            double valueStartZ = noise3(vecstartZ, structPtr, modX, modY, modZ);
            value = value * (1.0f - fractionZ) + valueStartZ * fractionZ;
        }
        
        result += value * amp;
        vec[0] *= 2.0f;
        vec[1] *= 2.0f;
        vec[2] *= 2.0f;
        multiplierX *= 2.0f;
        multiplierY *= 2.0f;
        multiplierZ *= 2.0f;
        
        amp*=structPtr->persistance;
    }
    
    return result;
}

@implementation Perlin

- (id) initWithOctaves:(int)octaves 
             frequencyX:(int)frequencyX 
             frequencyY:(int)frequencyY 
             frequencyZ:(int)frequencyZ 
             amplitude:(double)amplitude 
                  seed:(int)seed 
              tileable:(BOOL)tileable
                  loop:(BOOL)loop
           persistance:(double)persistance
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    _structPtr = malloc(sizeof(PerlinStruct));
    _structPtr->octaves = octaves;
    _structPtr->frequencyX = frequencyX;
    _structPtr->frequencyY = frequencyY;
    _structPtr->frequencyZ = frequencyZ;
    _structPtr->amplitude = amplitude;
    _structPtr->tiling = tileable;
    _structPtr->loop = loop;
    _structPtr->persistance = persistance * 0.5f;
    fn_seed_rand(seed);
    
    int i, j, k;

    for (i = 0 ; i < B ; i++)
    {
        _structPtr->p[i] = i;
        for (j = 0 ; j < 2 ; j++)
            _structPtr->g2[i][j] = (double)((fn_rand() * (B + B)) - B) / B;
        normalize2(_structPtr->g2[i]);
        for (j = 0 ; j < 3 ; j++)
            _structPtr->g3[i][j] = (double)((fn_rand() * (B + B)) - B) / B;
        normalize3(_structPtr->g3[i]);
    }

    while (--i)
    {
        k = _structPtr->p[i];
        _structPtr->p[i] = _structPtr->p[j = fn_rand() * B];
        _structPtr->p[j] = k;
    }

    for (i = 0 ; i < B + 2 ; i++)
    {
        _structPtr->p[B + i] = _structPtr->p[i];
        for (j = 0 ; j < 2 ; j++)
            _structPtr->g2[B + i][j] = _structPtr->g2[i][j];
        for (j = 0 ; j < 3 ; j++)
            _structPtr->g3[B + i][j] = _structPtr->g3[i][j];
    }
    
    return self;
}

- (double) getX:(double)x Y:(double)y
{
    double vec[2];
    vec[0] = x;
    vec[1] = y;
    return perlin_noise_2D(vec, _structPtr);
}

- (double) getX:(double)x Y:(double)y Z:(double)z
{
    double vec[3];
    vec[0] = x;
    vec[1] = y;
    vec[2] = z;
    return perlin_noise_3D(vec, _structPtr);
}

- (void)dealloc
{
    free(_structPtr);
    [super dealloc];
}


@end
