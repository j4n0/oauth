
#import "LoginViewController.h"


@implementation LoginViewController

@synthesize btnLogin, titleLabel;


/** Toggle logged state.*/
-(IBAction) toggleLogin {
   
    if ([self isUserLogged]){
        debug(@"LOGGING OUT");
        [[OAuthSingleton sharedInstance] resetState];
        
    } else {
        debug(@"LOGGING IN");
        OAuth *oauth = [OAuthSingleton sharedInstance];
        if ([oauth requestTemporaryCredentials]) {
            // the following step launches an external browser
            [oauth requestOwnerAuthorization];
            
        } else {
            // TODO: this should be a hud warning
            warn(@"authentication failed");
        }
    }
    
    [self updateUI];
}


-(BOOL) isUserLogged {
    return [[OAuthSingleton sharedInstance] isAuthenticated];
}


////////////////////////////////////////////////////////////////////////////////////////////////////


-(void) viewDidLoad {
    // setup login button
    [self.btnLogin setTarget:self];
    [self.btnLogin setAction:@selector(toggleLogin)];
}


- (void)viewWillAppear:(BOOL)animated {
    [self updateUI];
    [super viewWillAppear:animated];
}


-(void) updateUI {
    BOOL isLogged = [self isUserLogged];
    self.btnLogin.title = isLogged ? @"Logout" : @"Login";
    if (isLogged){
        
        // use an authenticated request to read the user profile 
        NSString *userFeedUrl = @"http://api.11870.com/api/v2/users";
        ASIHTTPRequest *request = [[OAuthSingleton sharedInstance] accessProtectedResourceWithUrl:userFeedUrl];
        debug(@"%@",request.responseString);
        
        // Get the user name. This should be done with libxml2 or fremont on a real app.
        NSString *xml = request.responseString;
        NSRange rangeTag1 = [xml rangeOfString:@"<oos:name>"];
        NSRange rangeTag2 = [xml rangeOfString:@"</oos:name>"];
        NSString *substring = [xml substringWithRange:NSMakeRange(rangeTag1.location+rangeTag1.length, 
                                                                  rangeTag2.location-rangeTag1.location-rangeTag2.length+1)];        
        // set the user name on the title
        self.titleLabel.title = substring;
        
    } else {
        // clear the title
        self.titleLabel.title = @"";
    }
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    [btnLogin release];
    [super dealloc];
}


@end
