//
//  CCNetworkReachability.m
//  Violet
//


#import "CCNetworkReachability.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const CCNetworkReachabilityChangeNotification = @"CCNetworkReachabilityChanged";

@implementation CCNetworkReachability

static void callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
	if(info && [(id)info isKindOfClass:[CCNetworkReachability class]])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:CCNetworkReachabilityChangeNotification object:info];	
	}
}

+ (CCNetworkReachability *)reachabilityForHost:(NSString *)url
{
	SCNetworkReachabilityRef reach = nil;
	CCNetworkReachability *result  = nil;

	if(url)
	{
		reach = SCNetworkReachabilityCreateWithName(NULL, [url UTF8String]);
	}
	else 
	{
		struct sockaddr_in address;
		memset (&address, 0, sizeof(address));
		address.sin_len = sizeof(address);
		address.sin_family = AF_INET;
		
		reach = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&address);		
	}
	
	if(reach)
	{
		result = [[self alloc] init];
		
		if(result)
		{
			result->_reachability = reach;
		}
	}
	
	return [result autorelease];	
}
		
- (id) init
{
	self = [super init];
	if (self != nil) {
		_reachability = nil;
		_notifierIsStarted = NO;
	}
	return self;
}


- (void) dealloc
{
	[self stopNotifier];
	
	if(_reachability)
	{
		CFRelease(_reachability);
		_reachability = nil;
	}
	
	[super dealloc];
}


- (BOOL)startNotifier
{
	if(_notifierIsStarted)
	{
		return YES;
	}
	
	BOOL result = NO;
	SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
	
	if(SCNetworkReachabilitySetCallback(_reachability, callback, &context))
	{
		if(SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
		{
			result = YES;
			_notifierIsStarted = YES;
		}
	}
	
	return result;
}

- (void)stopNotifier
{
	if(!_notifierIsStarted)
	{
		return;
	}
	
	if(_reachability)
	{
		SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		_notifierIsStarted = NO;
	}
}

// XXX This may not be perfect yet
- (BOOL)connectionAvailable
{
	BOOL result = YES;
	SCNetworkReachabilityFlags flags;

	if (SCNetworkReachabilityGetFlags(_reachability, &flags))
	{
		
		NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c\n",
			  (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
			  (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
			  (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
			  (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
			  (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
			  (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
			  (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
			  (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-');
		

		if(!(flags & kSCNetworkReachabilityFlagsReachable))
		{
			// Not reachable
			result = NO;
		}
		else if(flags & kSCNetworkReachabilityFlagsConnectionRequired)
		{
			// A connection hasn't been estabilshed
			result = NO;
		}
	}

	return result;
}


@end
