
#include "DebugLog.h"


void _Log(NSString *prefix, int padding, const char *file, int lineNumber, const char *funcName, NSString *format,...) {
	
	// if output is only one \n, print only that and exit
	if ([format isEqualToString:@"\n"]){
		fprintf(stderr,"\n");
		return;
	}
	
    va_list ap;
    va_start (ap, format);
	
	// add trailing \n if not already there
    if (![format hasSuffix:@"\n"]) format = [format stringByAppendingString:@"\n"];
	
	NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@",format] arguments:ap];
	[msg autorelease];
    
    va_end (ap);
	
	fprintf(stderr,"%s%50s:%3d - %s",[prefix UTF8String], funcName, lineNumber, [msg UTF8String]);
}
