
#import "OAuth.h"


// private
@interface OAuth()

@property (nonatomic, retain) OAuthState *oauthState;
@property (nonatomic, retain) NSOperationQueue *queue;

-(void) processTemporaryCredentials:(ASIHTTPRequest *)request;
-(void) processTokenCredentials:(ASIHTTPRequest *)request;


- (id) init;

-(void) handleHttpError:(ASIHTTPRequest *)request;
-(BOOL) isHttpSuccess:(int) status;

@end


@implementation OAuth

@synthesize temporaryCredentialsUrl, ownerAuthorizationUrl, tokenCredentialsUrl;
@synthesize consumerSecret, oauth_callback, oauth_consumer_key, realm;
@synthesize oauthState;
@synthesize queue;


#pragma mark -
#pragma mark init/dealloc


- (id) init {
    self = [super init];
    if (self != nil){
        
        self.oauthState = [OAuthState new];
        
        // server URLs
        self.temporaryCredentialsUrl = REQUEST_TEMPORARY_CREDENTIALS_URL;
        self.ownerAuthorizationUrl = REQUEST_OWNER_AUTHORIZATION_URL;
        self.tokenCredentialsUrl = REQUEST_TOKEN_CREDENTIALS_URL;
        // normalize URLs. See http://tools.ietf.org/html/rfc5849#section-3.4.1.2
        self.tokenCredentialsUrl = [OAuthUtils normalizeUrl:self.tokenCredentialsUrl];
        self.ownerAuthorizationUrl = [OAuthUtils normalizeUrl:self.ownerAuthorizationUrl];
        self.temporaryCredentialsUrl = [OAuthUtils normalizeUrl:self.temporaryCredentialsUrl];
        
        // client credentials
		self.oauth_consumer_key = CONSUMER_KEY;
		self.consumerSecret = CONSUMER_SECRET;
        
        self.oauth_callback = APPLICATION_CALLBACK_URL;
        
        // realm is *usually* fine empty. See http://tools.ietf.org/html/rfc2617#section-1.2
		self.realm = @"";
    }
    return self;
}


-(void) dealloc {
	[temporaryCredentialsUrl release], [ownerAuthorizationUrl release], [tokenCredentialsUrl release];
    [consumerSecret release], [oauth_callback release], [oauth_consumer_key release], [realm release];
	[oauthState release], [queue release];
	[super dealloc];
}


#pragma mark -
#pragma mark OAuth authentication steps


/** 
 * Step ONE of the OAuth flow: Request temporary credentials.
 *
 * This method is described here:
 *   - [http://tools.ietf.org/html/rfc5849#section-2.1 2.1. Temporary Credentials]
 *   - [http://tools.ietf.org/html/rfc5849#section-3.1 3.1. Making Requests]
 */
-(BOOL) requestTemporaryCredentials {
    
    // reset the state of any previous OAuth flow
    [self.oauthState reset];
    
    // nonce and timestamp: http://tools.ietf.org/html/rfc5849#section-3.3
    NSString *encodedNonce = [OAuthUtils urlEncode:[OAuthUtils nonce]];
    NSString *timestamp = [NSString stringWithFormat:@"%d",time(NULL)];
    
    NSString *encodedConsumerKey = [OAuthUtils urlEncode:self.oauth_consumer_key];
    NSString *encodedCallbackUrl = [OAuthUtils urlEncode:self.oauth_callback];
    
    // parameters = join(sort(urlEncode( parameter=value )), '&');
    // http://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
    NSMutableString *parameterString;
    {
        // DON'T ALTER THE LINE ORDER in this block
        // this could be done with KVC and sorting but unlike that, this is readable
        parameterString = [NSMutableString string];
        [parameterString appendFormat:@"%@=%@",   koauth_callback,         encodedCallbackUrl];
        [parameterString appendFormat:@"&%@=%@",  koauth_consumer_key,     encodedConsumerKey];
        [parameterString appendFormat:@"&%@=%@",  koauth_nonce,            encodedNonce]; 
        [parameterString appendFormat:@"&%@=%@",  koauth_signature_method, koauth_signature_methodValue];
        [parameterString appendFormat:@"&%@=%@",  koauth_timestamp,        timestamp];
        [parameterString appendFormat:@"&%@=%@",  koauth_version,          koauth_versionValue];
    }
    
    // baseString = HTTP_METHOD '&' urlEncode(normalized_url) '&' urlEncode(parameters)
    // http://tools.ietf.org/html/rfc5849#section-3.4.1.1
    NSString *baseString;
    {
        // note: all URLs were already normalized in the init method
        NSString *encodedUrl = [OAuthUtils urlEncode:self.temporaryCredentialsUrl];
        NSString *encodedParameters = [OAuthUtils urlEncode:parameterString];
        baseString = [NSString stringWithFormat:@"GET&%@&%@", encodedUrl, encodedParameters];
    }
    
    // signature = base64 ( hmac-sha1(baseString, signatureKey) )
    NSString *signature = [OAuthUtils signBaseString:baseString
                            withConsumerSecret:self.consumerSecret 
                                andTokenSecret:@""]; // no secret token exists during this step
    
    // header: http://tools.ietf.org/html/rfc5849#section-3.5.1
    NSMutableString *header = [NSMutableString string];
    [header appendFormat:@"%@=\"\"", krealm];
    [header appendFormat:@", %@=\"%@\"",  koauth_callback,         encodedCallbackUrl];
    [header appendFormat:@", %@=\"%@\"",  koauth_consumer_key,     encodedConsumerKey];
    [header appendFormat:@", %@=\"%@\"",  koauth_nonce,            encodedNonce];
    [header appendFormat:@", %@=\"%@\"",  koauth_signature,        [OAuthUtils urlEncode:signature]];
    [header appendFormat:@", %@=\"%@\"",  koauth_signature_method, koauth_signature_methodValue];
    [header appendFormat:@", %@=\"%@\"",  koauth_timestamp,        timestamp];
    [header appendFormat:@", %@=\"%@\"",  koauth_version,          koauth_versionValue];
    
    
    //debug(@"\n\nREQUEST TEMPORARY CREDENTIALS\n  GET %@ \n  Authorization: \n    %@\n\n", self.temporaryCredentialsUrl, 
    //      [header stringByReplacingOccurrencesOfString:@", " withString:@", \n    "]);
    
    // make the request
    NSURL *url = [NSURL URLWithString:self.temporaryCredentialsUrl];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    request.requestMethod = @"GET";
	[request addRequestHeader:@"Authorization" value:header];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(processTemporaryCredentials:)];
	[request setDidFailSelector:@selector(handleHttpError:)];
	//[[self queue] addOperation:request];
    [request startSynchronous];

    debug(@"    OAuth state: %@", [self.oauthState describe]);    
    return [self isHttpSuccess:request.responseStatusCode];
}


/** 
 * Process response of step one (request temporary credentials). 
 */
-(void) processTemporaryCredentials:(ASIHTTPRequest *)request {
    
    // parse response: oauth_token=xxx &oauth_token_secret=xxx &oauth_callback_confirmed=true
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSString *parts in [[request responseString] componentsSeparatedByString:@"&"]) {
        NSArray *keyValues = [parts componentsSeparatedByString:@"="];
        [dic setObject:[keyValues objectAtIndex:1] forKey:[keyValues objectAtIndex:0]];
    }
    // save state
    self.oauthState.oauth_token = [dic objectForKey:koauth_token];
    self.oauthState.oauth_token_secret = [dic objectForKey:koauth_token_secret];
    //debug(@"oauthToken=%@ oauthTokenSecret=%@", self.oauthState.oauth_token, self.oauthState.oauth_token_secret);
}


/** 
 * Step TWO of the OAuth flow: request owner authorization.
 */
-(void) requestOwnerAuthorization {
    NSString *url = [NSString stringWithFormat:@"%@?oauth_token=%@", self.ownerAuthorizationUrl, self.oauthState.oauth_token];
    
    debug(@"    Launching browser for the owner authorization step");
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    
    // execution continues in method application:handleOpenURL: of the delegate class
}


/** 
 * Step THREE of the OAuth flow: Request an access token.
 * See http://tools.ietf.org/html/rfc5849#section-2.3
 *
 * @param token temporary credentials identifier (aka oauth_token)
 * @param verifier verification code (aka oauth_verifier)
 */
-(BOOL) requestTokenCredentials {
    
    NSString *encodedNonce = [OAuthUtils urlEncode:[OAuthUtils nonce]];
    NSString *timestamp = [NSString stringWithFormat:@"%d",time(NULL)];
    NSString *encodedConsumerKey = [OAuthUtils urlEncode:self.oauth_consumer_key];
    
    // parameters = join(sort(urlEncode( parameter=value )), '&');
    // http://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
    NSMutableString *parameterString;
    {
        // DON'T ALTER THE LINE ORDER in this block
        parameterString = [NSMutableString string];
        [parameterString appendFormat:@"%@=%@",   koauth_consumer_key,     encodedConsumerKey];
        [parameterString appendFormat:@"&%@=%@",  koauth_nonce,            encodedNonce]; 
        [parameterString appendFormat:@"&%@=%@",  koauth_signature_method, koauth_signature_methodValue];
        [parameterString appendFormat:@"&%@=%@",  koauth_timestamp,        timestamp];
        [parameterString appendFormat:@"&%@=%@",  koauth_token,            self.oauthState.oauth_token];
        [parameterString appendFormat:@"&%@=%@",  koauth_verifier,         self.oauthState.oauth_verifier];
        [parameterString appendFormat:@"&%@=%@",  koauth_version,          koauth_versionValue];
    }
    
    // baseString = HTTP_METHOD '&' urlEncode(normalized_url) '&' urlEncode(parameters)
    // http://tools.ietf.org/html/rfc5849#section-3.4.1.1
    NSString *baseString;
    {
        // note: all URLs were already normalized in the init method
        NSString *encodedUrl = [OAuthUtils urlEncode:self.tokenCredentialsUrl];
        NSString *encodedParameters = [OAuthUtils urlEncode:parameterString];
        baseString = [NSString stringWithFormat:@"GET&%@&%@", encodedUrl, encodedParameters];
    }
    
    //debug(@"base string: %@", [baseString stringByReplacingOccurrencesOfString:@"%26" withString:@"\n%26"]);
    
    // signature = base64 ( hmac-sha1(baseString, signatureKey) )
    NSString *signature = [OAuthUtils signBaseString:baseString
                            withConsumerSecret:self.consumerSecret 
                                andTokenSecret:self.oauthState.oauth_token_secret];
    
    NSMutableString *header = [NSMutableString string];
    [header appendFormat:@"%@=\"\"",      krealm];
    [header appendFormat:@", %@=\"%@\"",  koauth_consumer_key,     encodedConsumerKey];
    [header appendFormat:@", %@=\"%@\"",  koauth_nonce,            encodedNonce];
    [header appendFormat:@", %@=\"%@\"",  koauth_signature,        [OAuthUtils urlEncode:signature]];
    [header appendFormat:@", %@=\"%@\"",  koauth_signature_method, koauth_signature_methodValue];
    [header appendFormat:@", %@=\"%@\"",  koauth_timestamp,        timestamp];
    // this call adds token and verifier
    [header appendFormat:@", %@=\"%@\"",  koauth_token,            [OAuthUtils urlEncode:self.oauthState.oauth_token]];
    [header appendFormat:@", %@=\"%@\"",  koauth_verifier,         [OAuthUtils urlEncode:self.oauthState.oauth_verifier]];
    [header appendFormat:@", %@=\"%@\"",  koauth_version,          koauth_versionValue];
    //debug(@"Authorization:\n%@", [header stringByReplacingOccurrencesOfString:@", " withString:@", \n"]);
    
    // POST
    // make the request
    NSURL *url = [NSURL URLWithString:self.tokenCredentialsUrl];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    request.requestMethod = @"GET";
	[request addRequestHeader:@"Authorization" value:header];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(processTokenCredentials:)];
	[request setDidFailSelector:@selector(handleHttpError:)];
	//[[self queue] addOperation:request];
    [request startSynchronous];
    
    debug(@"    OAuth state: %@", [self.oauthState describe]);
    return [self isHttpSuccess:request.responseStatusCode];
}



/** Second part of step one (request an unauthorized token). */
-(void) processTokenCredentials:(ASIHTTPRequest *)request {
    
    // parse response: oauth_token=xxx &oauth_token_secret=xxx
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSString *parts in [[request responseString] componentsSeparatedByString:@"&"]) {
        NSArray *keyValues = [parts componentsSeparatedByString:@"="];
        [dic setObject:[keyValues objectAtIndex:1] forKey:[keyValues objectAtIndex:0]];
    }
    self.oauthState.oauth_token = [dic objectForKey:koauth_token];
    //debug(@"Setting self.oauthState.oauth_token = %@", self.oauthState.oauth_token);
    
    self.oauthState.oauth_token_secret = [dic objectForKey:koauth_token_secret];
    self.oauthState.authenticated = TRUE;
}



-(ASIHTTPRequest*) accessProtectedResourceWithUrl:(NSString *)url { 
                         //andParameters:(NSDictionary*) parameters {
    debug(@"    Authorized request %@", url);
    
    NSString *encodedNonce = [OAuthUtils urlEncode:[OAuthUtils nonce]];
    NSString *timestamp = [NSString stringWithFormat:@"%d",time(NULL)];
    NSString *encodedConsumerKey = [OAuthUtils urlEncode:self.oauth_consumer_key];
    
    // parameters = join(sort(urlEncode( parameter=value )), '&');
    // http://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
    NSMutableString *parameterString;
    {
        // DON'T ALTER THE LINE ORDER in this block
        parameterString = [NSMutableString string];
        [parameterString appendFormat:@"%@=%@",  koauth_consumer_key,     encodedConsumerKey];
        [parameterString appendFormat:@"&%@=%@", koauth_nonce,            encodedNonce]; 
        [parameterString appendFormat:@"&%@=%@", koauth_signature_method, koauth_signature_methodValue];
        [parameterString appendFormat:@"&%@=%@", koauth_timestamp,        timestamp];
        [parameterString appendFormat:@"&%@=%@", koauth_token,            self.oauthState.oauth_token];
        [parameterString appendFormat:@"&%@=%@", koauth_version,          koauth_versionValue];
    }
    
    // baseString = HTTP_METHOD '&' urlEncode(normalized_url) '&' urlEncode(parameters)
    // http://tools.ietf.org/html/rfc5849#section-3.4.1.1
    NSString *baseString;
    {
        // note: all URLs were already normalized in the init method
        NSString *encodedUrl = [OAuthUtils urlEncode:url];
        NSString *encodedParameters = [OAuthUtils urlEncode:parameterString];
        baseString = [NSString stringWithFormat:@"GET&%@&%@", encodedUrl, encodedParameters];
    }
    
    //debug(@"base string: %@", [baseString stringByReplacingOccurrencesOfString:@"%26" withString:@"\n%26"]);
    
    // signature = base64 ( hmac-sha1(baseString, signatureKey) )
    NSString *signature = [OAuthUtils signBaseString:baseString
                            withConsumerSecret:self.consumerSecret 
                                andTokenSecret:self.oauthState.oauth_token_secret];
    
    NSMutableString *header = [NSMutableString string];
    [header appendFormat:@"%@=\"\"", krealm];
    [header appendFormat:@", %@=\"%@\"", koauth_consumer_key,     encodedConsumerKey];
    [header appendFormat:@", %@=\"%@\"", koauth_nonce,            encodedNonce];
    [header appendFormat:@", %@=\"%@\"", koauth_signature,        [OAuthUtils urlEncode:signature]];
    [header appendFormat:@", %@=\"%@\"", koauth_signature_method, koauth_signature_methodValue];
    [header appendFormat:@", %@=\"%@\"", koauth_timestamp,        timestamp];
    [header appendFormat:@", %@=\"%@\"", koauth_version,          koauth_versionValue];
    // new parmeter
    [header appendFormat:@", %@=\"%@\"", koauth_token,            [OAuthUtils urlEncode:self.oauthState.oauth_token]];
    
    /*
    for (NSString* key in parameters) {
        NSString* obj = [parameters objectForKey:key];
        [header appendString:[NSString stringWithFormat:@", %@=\"%@\"", key, [self urlEncode:obj] ] ];
    }
    */
    
    // TODO: any other parameter that goes in the request
    // debug(@"Authorization:\n%@", [header stringByReplacingOccurrencesOfString:@", " withString:@", \n"]);
    
    // POST
    // make the request
    NSURL *theUrl = [NSURL URLWithString:url];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:theUrl];
    request.requestMethod = @"GET";
	[request addRequestHeader:@"Authorization" value:header];
	[request setDelegate:self];
	//[request setDidFinishSelector:@selector(processProtectedResource:)];
	[request setDidFailSelector:@selector(handleHttpError:)];
	//[[self queue] addOperation:request];
    [request startSynchronous]; 
    
    return [self isHttpSuccess:request.responseStatusCode] ? request : nil;
}


/** 
 * Return TRUE if the HTTP operation is in the 2xx range.
 *
 * According to http://tools.ietf.org/html/rfc5849#section-2.3
 * OAuth operations should return 200, but 11870 returns 201.
 */
-(BOOL) isHttpSuccess:(int) status {
    return status>199 && status <207;
}


#pragma mark -
#pragma mark utility methods


-(void) handleHttpError:(ASIHTTPRequest *)request {
    // this should be a 200
    // http://tools.ietf.org/html/rfc5849#section-2.3
    int status = request.responseStatusCode;
    BOOL success = [self isHttpSuccess:status];
    debug(@"11870 returned %d for the access token phase", status);
    if (!success) { // 11870 may return 201 (not sure), it should be 200
        // request failed
        NSString *error = [[request error] localizedDescription];
        debug(@"error=%@, status=%d, response=%@", error, status, request.responseString);
        // hmm reset state or retry?
        return;
    }
}


#pragma mark -
#pragma mark oauth state

/** @return TRUE if we are ready to access protected resources. */
-(BOOL) isAuthenticated {
    return self.oauthState.authenticated;
}

-(void) resetState {
    [self.oauthState reset];
    //debug(@"    State resetted to: %@", [oauthState describe]);
}

-(NSString*) describeState {
    return [self.oauthState describe];
}


@end
