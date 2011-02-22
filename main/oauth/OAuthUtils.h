
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import "Base64Transcoder.h"

/**
 * @author Jon Crosby
 * @author jano@jano.com.es
 */
@interface OAuthUtils : NSObject {
    
}

+(NSString*) normalizeUrl:(NSString*)url;

+(NSString *) urlEncode:(NSString*)string;

+(NSString*) sha1:(NSString*)input;

+(NSString*) nonce;

+(NSString*) signBaseString:(NSString*) baseString 
         withConsumerSecret:(NSString*) conSecret 
             andTokenSecret:(NSString*) tokSecret;


@end
