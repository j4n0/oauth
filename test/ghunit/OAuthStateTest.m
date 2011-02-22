
#import <GHUnitIOS/GHUnit.h>
#import "OAuthState.h"

/** @author jano@jano.com.es */
@interface OAuthStateTest : GHTestCase {
}
@end

@implementation OAuthStateTest

- (void)testOauthState {
    
    // save values
    OAuthState *state = [OAuthState new];
    [state reset];
    
    // 1st step
    state.oauth_token = @"oauth_token";
    state.oauth_token_secret = @"oauth_token_secret";
    debug(@"%@", [state describe]);
    
    // 2nd step
    state.oauth_verifier = @"oauth_verifier";
    debug(@"%@", [state describe]);
    
    // 3rd step
    state.authenticated = TRUE;
    debug(@"%@", [state describe]);
    
    
    // create a new object and see the values are still the same
    [state release];
    state = [OAuthState new];
    GHAssertEqualStrings(state.oauth_token, @"oauth_token", nil);
    GHAssertEqualStrings(state.oauth_token_secret, @"oauth_token_secret", nil);
    GHAssertEqualStrings(state.oauth_verifier, @"oauth_verifier", nil);
    GHAssertTrue(state.authenticated, nil);
    
    // reset the values
    [state reset];
    GHAssertNil(state.oauth_token, nil);
    GHAssertNil(state.oauth_token_secret, nil);
    GHAssertNil(state.oauth_verifier, nil);
    GHAssertFalse(state.authenticated, nil);
    
}

@end
