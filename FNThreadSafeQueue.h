#import <Cocoa/Cocoa.h>

@interface FNThreadSafeQueue : NSObject
{
    NSConditionLock *lock;
    NSMutableArray  *queue;
}

- (id)init;

- (BOOL)empty;

- (void)enqueue:(id)object;
- (id)dequeue;

@end
