

#import "FNModel.h"
#import "FNGradient.h"

#define NUM_I(v) [NSNumber numberWithInt:v]
#define NUM_F(v) [NSNumber numberWithFloat:v]
#define NUM_B(v) [NSNumber numberWithBool:v]

#define CURRENT_VERSION 200

@implementation FNModel

- (void)addVersionTwoPointZeroDefaults
{
    [self setObject:NUM_I(0) forKey:@"output"];
    [self setObject:NUM_F(32.0f) forKey:@"normalMapHeightScale"];
    [self setObject:NUM_F(32.0f) forKey:@"environmentMapHeightScale"];
    [self setObject:@"default" forKey:@"environmentMapFileName"];
    [self setObject:NUM_F(32.0f) forKey:@"distortionImageHeightScale"];
    [self setObject:@"default" forKey:@"distortionImageFileName"];
}

- (id)init
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    _dict = [[NSMutableDictionary alloc] init];
    
    [self setObject:NUM_I(500) forKey:@"width"];
    [self setObject:NUM_I(400) forKey:@"height"];
    [self setObject:NUM_I(4) forKey:@"octaves"];
    [self setObject:NUM_I(0) forKey:@"seed"];
    [self setObject:NUM_I(0) forKey:@"frequencyX"];
    [self setObject:NUM_I(0) forKey:@"frequencyY"];
    [self setObject:NUM_I(0) forKey:@"frequencyZ"];
    [self setObject:NUM_F(1.0f) forKey:@"persistance"];
    [self setObject:NUM_F(1.0f) forKey:@"amplitude"];
    [self setObject:NUM_F(1.0f) forKey:@"animationDuration"];
    [self setObject:NUM_B(NO) forKey:@"tile"];
    [self setObject:NUM_B(YES) forKey:@"loop"];
    [self setObject:[FNGradient defaultGradient] forKey:@"gradient"];
    
    [self setObject:NUM_I(CURRENT_VERSION) forKey:@"version"];
    
    [self addVersionTwoPointZeroDefaults];
    
    return self;
}



- (id)initWithData:(NSData*)data
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    _dict = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
    
    //2.0
    if(![_dict objectForKey:@"version"])
    {
        [self addVersionTwoPointZeroDefaults];
    }
    
    [self setObject:NUM_I(CURRENT_VERSION) forKey:@"version"];
    
    return self;
}

- (BOOL)setObject:(id)anObject forKey:(id)aKey
{
    id oldObject = [_dict objectForKey:aKey];
    if(oldObject && [oldObject isEqual:anObject])
    {
        return NO;
    }
    
    [_dict setObject:anObject forKey:aKey];
    
    return YES;
}

- (id)objectForKey:(id)aKey
{
    return [_dict objectForKey:aKey];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [NSKeyedArchiver archivedDataWithRootObject:_dict];
}

- (void)dealloc
{
    [_dict release];
    [super dealloc];
}

@end
