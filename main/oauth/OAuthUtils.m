#import "OAuthUtils.h"


@implementation OAuthUtils


/** @author Jon Crosby */
+ (NSString *)signClearText:(NSString *)text withSecret:(NSString *)secret {
    
	NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
	
    uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA1, secretData.bytes, secretData.length);
    CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
    CCHmacFinal(&hmacContext, digest);
	
    //Base64 Encoding
    
    char base64Result[32];
    size_t theResultLength = 32;
    Base64EncodeData(digest, CC_SHA1_DIGEST_LENGTH, base64Result, &theResultLength);
    NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];
    
    NSString *base64EncodedResult = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    
    return [base64EncodedResult autorelease];
}


/**
 * Sign the base string using the consumer secret and token secret.
 *
 * @param conSecret Consumer secret.
 * @param tokSecret Token secret.
 */
+(NSString*) signBaseString:(NSString*) baseString 
         withConsumerSecret:(NSString*) conSecret 
             andTokenSecret:(NSString*) tokSecret 
{
    tokSecret = tokSecret==nil ? @"" : tokSecret;
    
    // signature = base64 ( hmac-sha1(baseString, signatureKey) )
    // http://tools.ietf.org/html/rfc5849#section-3.4.2
    
    // signatureKey = (consumerSecret & secretToken)
    NSString *signatureKey = [NSString stringWithFormat:@"%@&%@", conSecret, tokSecret];
    
    // OAHMAC-SHA1: http://tools.ietf.org/html/rfc2104
    NSString *signature = [OAuthUtils signClearText:baseString withSecret:signatureKey]; 
    
    return signature;
}


/**
 * Nonce is a random string unique for each request.
 * See http://tools.ietf.org/html/rfc5849#section-3.3
 */
+(NSString*) nonce {
    unsigned long long nonce = ((unsigned long long) arc4random());
    nonce = nonce << 32 | (unsigned long long) arc4random(); // make it 64 bits
    return [NSString stringWithFormat:@"%qu", nonce];
}


/**
 * Normalize URL according to http://tools.ietf.org/html/rfc5849#section-3.4.1.2
 * Taken from GDataOAuthAuthentication.
 * 
 * @return Normalized url
 */
+ (NSString *)normalizeUrl:(NSString *)sUrl {
    
    NSURL *url = [NSURL URLWithString:sUrl];
    
    NSString *host = [[url host] lowercaseString];
    NSString *scheme = [[url scheme] lowercaseString];
    int port = [[url port] intValue];
    
    // NSURL's path method unescapes the path, CFURLCopyPath doesn't
    CFStringRef cfPath = CFURLCopyPath((CFURLRef)url);
    NSString *path = [NSMakeCollectable(cfPath) autorelease];
    if ([path length]==0){
        path = @"/";
    }
    
    // use empty string when port is default or not present
    BOOL nilPort = port==0;
    nilPort |= [scheme isEqualToString:@"http"] && (port==80);
    nilPort |= [scheme isEqualToString:@"https"] && (port==443);
    NSString *portStr = nilPort ? @"" : [NSString stringWithFormat:@":%u", port];
    
    NSString *result = [NSString stringWithFormat:@"%@://%@%@%@",
                        scheme, host, portStr, path];
    return result;
}



/**
 * SHA1 hash function.
 * @author Jon Crosby
 */
+(NSString*) sha1:(NSString*)input {
	const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
	NSData *data = [NSData dataWithBytes:cstr length:input.length];
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(data.bytes, data.length, digest);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", digest[i]];
    }
	return output;
}


/**
 * URL encode everything except [a-zA-Z0-9.-_~]
 * See http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string/3426140#3426140
 * I would use Apple's stringByAddingPercentEscapesUsingEncoding but it seems to be bugged.
 */
+ (NSString *) urlEncode:(NSString*)string {
    if (string==nil) {
        NSLog(@"Attempt to urlEncode a nil string. Returning nil.");
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"nil string" userInfo:nil];
        return nil;
    }
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[string UTF8String];
    int sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' || 
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}


@end
