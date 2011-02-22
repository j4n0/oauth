
This is an OAuth 1.0 client for the iPhone.

The target 'client' is an universal client that lets you log in and out.
To test it against 11870.com you need to create a free account, register 
this application, and set the resulting keys in the file Credentials.h.


USAGE

     OAuth *oauth = [OAuth new];
     [oauth requestTemporaryCredentials]; // (1)
     [oauth requestOwnerAuthorization];   // (2)
     [oauth requestTokenCredentials];     // (3)

 At this point you are authenticated and you can repeatedly access protected resources like this:

     ASIHTTPRequest *request = [oauth accessProtectedResourceWithUrl:@"http://api.11870.com/api/v2/users"];
     NSLog(@"%@",request.responseString);


 That's all you have to do, but is worth mentioning that what happens between (2) and (3):

     The "request owner authorization" step opens an external browser pointed to the website 
     login page, for the user to authenticate himself and authorize the application.

     If everything goes well, the browser redirects the user back to the application using a 
     protocol we previously registered in the Info.plist file of our app.

     The delegate picks up the URL and executes the last step. Then it's up to you to access 
     protected resources on the user behalf.

 You don't need to worry about preserving the state of the OAuth flow between calls, that's 
 automatically handled using NSUserDefaults. If you prefer to treat OAuth as a singleton, 
 call [OAuthSingleton sharedInstance] instead using [OAuth new].



PROJECT LIBRARIES

 CFNetwork.framework .............. ASIHTTPRequest
 CoreGraphics.framework ........... ASIHTTPRequest, GHUnitIOS
 Foundation.framework ............. iOS, GHUnitIOS
 GHUnitIOS.framework .............. Testing
 MobileCoreServices.framework ..... ASIHTTPRequest
 Security.framework ............... Cryptography stuff
 SystemConfiguration.framework .... ASIHTTPRequest
 UIKit.framework .................. iOS, GHUnitIOS
 libtidy.dylib .................... ASIHTTPRequest
 libz.1.2.3.dylib ................. ASIHTTPRequest
 libxml2.dylib .................... ASIHTTPRequest

 ASIHTTPRequest is a wrapper around the CFNetwork API to perform HTTP requests.
 See http://allseeing-i.com/ASIHTTPRequest/

 GHUnit is a test framework for Mac OS X 10.5+ and iPhone 3.x+.
 See https://github.com/gabriel/gh-unit

 If you use ASIHTTPRequest and GHUnit in your projects, remember to set 
     Other Linker Flags: -ObjC -all_load



THINGS YOU MIGHT WANT TO DO

 If you want to use different service providers:
     - Take out the hardcoded parameters in the init method and either make an init 
       that accepts parameters or set them after initializing the class. 
     - Change OAuthState to use a prefix for the NSUserDefault keys, or use Core Data.

 If you want to register a custom protocol for your app:
     - Go to the Info.plist file and add this:
           URL types               Array
               Item 0              Dictionary
                   URL identifier  String      com.your.unique.domain
                   URL Schemes     Array
                       Item 0      String      yourappname
     - Now your app will handle URIs with scheme yourappname, like "yourappname://whatever".

 If you don't like ASIHTTPRequest, it's easy to replace.

 If you want to use PIN authentication (why?) set the callback to 'OOB' and make a 
 version of requestTokenCredentials where you can pass the PIN.

 Note that using a browser inside the same application provides a better user experience,
 but it gives you the chance to snoop on the user, and defeats the purpose of OAuth.

 




