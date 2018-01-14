#import "FNThreadSafeQueue.h"

#define OSEmpty    0
#define OSNonEmpty 1

@implementation FNThreadSafeQueue

- (id)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }
    
    lock = [[NSConditionLock alloc] initWithCondition:OSEmpty];
    queue = [[NSMutableArray alloc] init];
    
    return self;
}

- (BOOL)empty
{
    return [lock condition] == OSEmpty;
}

- (void)enqueue:(id)object
{
    [lock lock];
    [queue addObject:object];
    [lock unlockWithCondition:OSNonEmpty];
}

- (id)dequeue
{
    [lock lockWhenCondition:OSNonEmpty];
    
    id result = [[queue objectAtIndex:0] retain];
    [queue removeObjectAtIndex:0];
    
    [lock unlockWithCondition:[queue count] > 0 ? OSNonEmpty : OSEmpty];
    
    return [result autorelease];
}

@end
