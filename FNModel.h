

#import <Cocoa/Cocoa.h>

enum {
    OUTPUT_TYPE_GRADIENT = 0,
    OUTPUT_TYPE_NORMAL_MAP,
    OUTPUT_TYPE_ENVIRONMENT_MAP,
    OUTPUT_TYPE_IMAGE_DISTORTION
};

@interface FNModel : NSObject {
    NSMutableDictionary* _dict;
}

- (id)init;
- (id)initWithData:(NSData*)data;

- (BOOL)setObject:(id)anObject forKey:(id)aKey;
- (id)objectForKey:(id)aKey;

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError;

@end
