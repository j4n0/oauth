
#import "OAuth.h"

/**
 * Subclass of OAuth that adds Singleton behavior.
 * This allows you to access the class as [OAuthSingleton sharedInstance].
 */
@interface OAuthSingleton : OAuth {
    
}

/** 
 * Return the unique instance of this class.
 */
+ (id) sharedInstance;


@end
