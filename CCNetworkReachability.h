//
//  CCNetworkReachability.h
//  Violet
//

#import <Cocoa/Cocoa.h>

#import <SystemConfiguration/SystemConfiguration.h>

extern NSString * const CCNetworkReachabilityChangeNotification;


@interface CCNetworkReachability : NSObject
{
	SCNetworkReachabilityRef _reachability;
	BOOL _notifierIsStarted;
}

+ (CCNetworkReachability *)reachabilityForHost:(NSString *)url;
- (BOOL)startNotifier;
- (void)stopNotifier;
- (BOOL)connectionAvailable;

@end
