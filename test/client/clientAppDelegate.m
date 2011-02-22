
#import "clientAppDelegate.h"

@implementation clientAppDelegate

@synthesize window=_window, loginViewController, view;

/**
 * Handle any custom scheme previously registered.
 */
- (BOOL)application:(UIApplication *)application   // The application object
            openURL:(NSURL *)url                   // a URL
  sourceApplication:(NSString *)sourceApplication  // The bundle ID of the application that is requesting your app
         annotation:(id)annotation {               // A property-list object supplied by the source application 
    
    // parse url and save the result to NSUserDefaults
    [self parseUrl:url];
    
    // last step of OAuth authentication
    BOOL success = [[OAuthSingleton sharedInstance] requestTokenCredentials];

    if (success) {
        [loginViewController updateUI];
    }
    
    return YES;
}


/**
 * Parse URL and save the oauth_token, oauth_verifier in NSUserDefaults.
 */
- (void) parseUrl:(NSURL*) url {
    
    // url to parse should be oauthapp://oauthapp?oauth_token=xxx&oauth_verifier=xxx
    
    // strip callback_url
    NSString *prefix = [NSString stringWithFormat:@"%@?",APPLICATION_CALLBACK_URL];
    NSString *sUrl = [url absoluteString];
    NSRange range = [sUrl rangeOfString:prefix];
    if (range.location==NSNotFound){
        warn(@"URLs without the %@? prefix won't be processed.",sUrl);
        return;
    } 
    sUrl = [sUrl substringFromIndex:NSMaxRange(range)];
    
    // now sUrl should be oauth_token=xxx&oauth_verifier=xxx
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSString *parts in [sUrl componentsSeparatedByString:@"&"]) {
        NSArray *keyValues = [parts componentsSeparatedByString:@"="];
        [dic setObject:[keyValues objectAtIndex:1] forKey:[keyValues objectAtIndex:0]];
    }
    OAuthState *state = [OAuthState new];
    state.oauth_token = [dic objectForKey:koauth_token];
    state.oauth_verifier = [dic objectForKey:koauth_verifier];
    
    debug(@"    OAuth state: %@", [[OAuthSingleton sharedInstance] describeState]);
}



#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // some code may be needed here for iOS 3.2 (or not)
    // see http://stackoverflow.com/questions/3612460/lauching-app-with-url-via-uiapplicationdelegates-handleopenurl-working-under-i/3612734#3612734
    
	if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
		warn(@"NSZombieEnabled=YES (no memory will be deallocated)");
	}
    
    // Add the tab bar controller's view to the window and display.
    [self.window addSubview:view];
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)dealloc {
    [_window release];
    [super dealloc];
}

@end
