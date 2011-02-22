
#import "OAuthState.h"


@implementation OAuthState

@synthesize defaults;


- (id) init {
    self = [super init];
    if (self != nil){
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}


-(OAuthState*) reset {
    [self.defaults removeObjectForKey:koauth_token];
    [self.defaults removeObjectForKey:koauth_token_secret];
    [self.defaults removeObjectForKey:koauth_verifier];
    [self.defaults removeObjectForKey:koauth_authenticated];
    return self;
}


-(NSString*) describe {
    NSString *msg = nil;
    
    if (self.authenticated){
        msg = [NSString stringWithString:@"3/3 Token Credentials. Good to go!"];
        
    } else if (self.oauth_token!=nil && self.oauth_verifier!=nil){
        msg = [NSString stringWithString:@"2/3 Owner authorization."];
        
    } else if (self.oauth_token!=nil && self.oauth_token_secret!=nil){
        msg = [NSString stringWithString:@"1/3 Temporary credentials."];
        
    } else {
        msg = [NSString stringWithString:@"0/3 Ready to start authentication."];
        
    }
    return msg;
}


-(NSString*) oauth_token {
   return [self.defaults objectForKey:koauth_token];
}
-(void) setOauth_token:(NSString*)oauth_token {
    [self.defaults setObject:oauth_token forKey:koauth_token];
}

-(NSString*) oauth_token_secret {
    return [self.defaults objectForKey:koauth_token_secret];
}
-(void) setOauth_token_secret:(NSString*)oauth_token_secret {
    [self.defaults setObject:oauth_token_secret forKey:koauth_token_secret];
}

-(NSString*) oauth_verifier {
    return [self.defaults objectForKey:koauth_verifier];
}
-(void) setOauth_verifier:(NSString*)oauth_verifier {
    [self.defaults setObject:oauth_verifier forKey:koauth_verifier];
}

-(BOOL) authenticated {
    BOOL authenticated = [self.defaults boolForKey:koauth_authenticated];
    // check that the state is consistent
    authenticated &= self.oauth_token!=nil && self.oauth_token_secret!=nil;
    return authenticated;
}
-(void) setAuthenticated:(BOOL)authenticated {
    [self.defaults setBool:authenticated forKey:koauth_authenticated];
}


@end
