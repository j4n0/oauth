

#define     APPLICATION_CALLBACK_URL @"oauthapp://oauth"
// 11870 endpoints
#define REQUEST_TEMPORARY_CREDENTIALS_URL @"http://11870.com/services/manage-api/request-token"
#define   REQUEST_OWNER_AUTHORIZATION_URL @"http://11870.com/services/manage-api/authorize"
#define     REQUEST_TOKEN_CREDENTIALS_URL @"http://11870.com/services/manage-api/access-token"

# error Fill next two fields with the keys for your client. Register at http://11870.com/<YOURUSER>/apps/new
#define                      CONSUMER_KEY @""
#define                   CONSUMER_SECRET @""


// Constants. No need to edit past this point.

// key to save the authenticated state in NSUserDefaults
static NSString *const koauth_authenticated         = @"oauth_authenticated";

// Constants from the OAuth 1.0 specification
static NSString *const koauth_callback              = @"oauth_callback";
static NSString *const koauth_consumer_key          = @"oauth_consumer_key";
static NSString *const koauth_nonce                 = @"oauth_nonce";
static NSString *const krealm                       = @"OAuth realm";
static NSString *const koauth_signature             = @"oauth_signature";
static NSString *const koauth_signature_method      = @"oauth_signature_method";
static NSString *const koauth_signature_methodValue = @"HMAC-SHA1";
static NSString *const koauth_timestamp             = @"oauth_timestamp";
static NSString *const koauth_token                 = @"oauth_token";
static NSString *const koauth_token_secret          = @"oauth_token_secret";
static NSString *const koauth_verifier              = @"oauth_verifier";
static NSString *const koauth_version               = @"oauth_version";
static NSString *const koauth_versionValue          = @"1.0";
