
// NSLog replacement. 
// Include this file in the .pch and use it like this: debug(@"%@",x); warn(@"%@",x);
// Based on http://www.karlkraft.com/index.php/2009/03/23/114/

#define WARNFLAG
#define DEBUGFLAG

#ifdef DEBUGFLAG
    #define debug(args...) _Log(@"", 50, __FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#else
    #define debug(x...)
#endif

#ifdef WARNFLAG
    #define warn(args...) _Log(@"WARNING ", 50, __FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#else
    #define warn(x...)
#endif

void _Log(NSString *prefix, int padding, const char *file, int lineNumber, const char *funcName, NSString *format,...);
