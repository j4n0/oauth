
#import "Credentials.h"
#import "ASIHTTPRequest.h"
#import "OAuthState.h"
#import "DebugLog.h"
#import "ASIHTTPRequest.h"
#import "OAuthUtils.h"

/**
 * OAuth 1.0 (RFC5849) client implementation.
 *
 * @author jano@jano.com.es
 */
@interface OAuth : NSObject {

    /** State of the OAuth authentication. */
    OAuthState *oauthState;
    
    
    // the following ivars are initialized in init from #defines in Credentials.h
    
    /** Endpoint for the requestTemporaryCredentials step. */
    NSString *temporaryCredentialsUrl;
    
    /** Endpoint for the request owner authorization step. */
    NSString *ownerAuthorizationUrl;
    
    /** Endpoint for the request token credentials step. */
    NSString *tokenCredentialsUrl;
    
    /** Consumer key. */
    NSString *oauth_consumer_key;
    
    /** Consumer secret key. */
    NSString *consumerSecret;
    
    /** Callback URI. Its scheme should be registered with this application. */
    NSString *oauth_callback;
    
    /** Realm header for OAuth authentication. */
    NSString *realm;

}

@property (nonatomic, retain) NSString *temporaryCredentialsUrl, *ownerAuthorizationUrl, *tokenCredentialsUrl;
@property (nonatomic, retain) NSString *consumerSecret, *oauth_callback, *oauth_consumer_key, *realm;


/**
 * First step of OAuth authentication.
 * @return TRUE if the server returns success.
 */
-(BOOL) requestTemporaryCredentials;

/**
 * Second step of OAuth authentication.
 */
-(void) requestOwnerAuthorization;

/** 
 * Third step of OAuth authentication.
 * @return TRUE if the server returns success. 
 */
-(BOOL) requestTokenCredentials;

/** 
 * Access a protected resource.
 * Requires [self isAuthenticated]==TRUE.
 */
-(ASIHTTPRequest*) accessProtectedResourceWithUrl:(NSString *)url;

/**
 * @return TRUE if the user is authenticated.
 */
-(BOOL) isAuthenticated;

/**
 * Reset authentication state.
 */
-(void) resetState;


/**
 * @return Human readable description of the OAuth authentication state.
 */
-(NSString*) describeState;



@end
