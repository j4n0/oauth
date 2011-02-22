
#import "ASIHTTPRequest.h"
#import "OAuthSingleton.h"
#import "Credentials.h"
#import <UIKit/UIKit.h>

/** @author jano@jano.com.es */
@interface LoginViewController : UIViewController {
    
    /* login button */
    UIBarButtonItem *btnLogin;
    
    /* top bar title */
    UINavigationItem *titleLabel;
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem *btnLogin;
@property (nonatomic, retain) IBOutlet UINavigationItem *titleLabel;

/** 
 * @return TRUE if the user is logged 
 */
-(BOOL) isUserLogged;

/** 
 * Update the UI. 
 * In this case set the user name on the bar title when the user is logged.
 */
-(void) updateUI;

@end
