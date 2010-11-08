//
//  CCPathMonitor.h
//  Violet
//

#import <Cocoa/Cocoa.h>

extern NSString * const CCPathOfInterestChangedNotification;

typedef enum
{
	Unknown,
} DeviceType;

@interface CCPathMonitor : NSObject
{
	NSString *_path;
	dispatch_source_t _source;
	BOOL _notifierIsStarted;
	NSArray *_contents;
}

- (id) initWithPath:(NSString *)path;
- (void)startNotifier;
- (void)stopNotifier;

- (DeviceType)deviceTypeForPath:(NSString *)path;

@end
