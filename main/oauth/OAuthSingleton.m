
#import "OAuthSingleton.h"

@implementation OAuthSingleton


#pragma mark Singleton behaviour 
#pragma mark -

// set value to [OAuthSingleton sharedInstance] if you want an eager singleton
static id uniqueInstance = nil;


+ (id)sharedInstance {
	@synchronized(self) {
        if (uniqueInstance == nil) {
            [[self alloc] init]; // assignment not done here, see allocWithZone
        }
	}
    return uniqueInstance;
}


+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (uniqueInstance == nil) {
            uniqueInstance = [super allocWithZone:zone];
            return uniqueInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}


// a copy attempt will return the unique instance
- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)init {
	// synchronize any code that alters shared state
	@synchronized(self) {
		[super init];	
		// class initialization stuff if any
		return self;
	}
}


// don't increment the retain count
- (id)retain {
    return self;
}


// don't return zero
- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}


// don't decrement the retain count
- (void)release {
}


// don't add to an autorelease pool
- (id)autorelease {
    return self;
}

@end
