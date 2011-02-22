
#import "Credentials.h"

/**
 * Stores the state of the OAuth flow using NSUserDefaults.
 * 
 * @author jano@jano.com.es
 */
@interface OAuthState : NSObject {
    NSUserDefaults *defaults;
}
@property (nonatomic, assign) NSUserDefaults *defaults;

/** Reset the state. */
-(OAuthState*) reset;

/** Human readable description. */
-(NSString*)describe;


// oauth tokens set during the oauth flow

-(NSString*) oauth_token;
-(void) setOauth_token:(NSString*)oauth_token;

-(NSString*) oauth_token_secret;
-(void) setOauth_token_secret:(NSString*)oauth_token_secret;

-(NSString*) oauth_verifier;
-(void) setOauth_verifier:(NSString*)oauth_verifier;

-(BOOL) authenticated;
-(void) setAuthenticated:(BOOL)authenticated;


@end
