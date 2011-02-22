
#import <UIKit/UIKit.h>
#import "LoginViewController.h"

/** @author jano@jano.com.es */
@interface clientAppDelegate : NSObject <UIApplicationDelegate> {
    LoginViewController *loginViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIView *view;

@property (nonatomic, retain) IBOutlet LoginViewController *loginViewController;

- (void) parseUrl:(NSURL*) url;


@end
