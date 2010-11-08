//
//  CCPathMonitor.m
//  Violet
//

#import "CCPathMonitor.h"

NSString * const CCPathOfInterestChangedNotification = @"CCPathOfInterestChangedNotification";


@interface CCPathMonitor (Private)

- (void)updateContents;

@end


@implementation CCPathMonitor

- (id)initWithPath:(NSString *)path
{
	self = [super init];
	
	if (self != nil) 
	{
		_path = [path retain];
		_contents = nil;
		_source = nil;
		_notifierIsStarted = NO;
	}
	return self;
}

- (void)dealloc
{
	[self stopNotifier];

	[_contents release];
	[_path release];
	
	[super dealloc];
}

- (DeviceType)deviceTypeForPath:(NSString *)path
{
	DeviceType result = Unknown;
	BOOL isDirectory = NO;
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory)
	{
	}
	else
	{
		NSLog(@"[Error] File doesn't exist at path: %@", path);
	}

	
	return result;
}

- (void)delayedUpdateContents
{
	[self performSelector:@selector(updateContents) withObject:nil afterDelay:2.0];
}

- (void)updateContents
{	
	NSError *error = nil;
	
	NSArray *newContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_path error:&error] retain];

	if(!newContents)
	{
		NSLog(@"[Error] getting directory contents at path: %@ -- %@", _path, error);
		return;
	}
	
	NSMutableArray *toNotifyAbout = [NSMutableArray arrayWithArray:newContents];
	
	// Removed
	for(NSString *path in _contents)
	{
		BOOL wasRemoved = YES;
		
		for(NSString *item in newContents)
		{
			if([item isEqualToString:path])
			{
				wasRemoved = NO;
				break;
			}
		}
		
		if(wasRemoved)
		{
			[toNotifyAbout addObject:path];
		}
	}
	 
	for(NSString *file in toNotifyAbout)
	{
		NSString *item = [_path stringByAppendingPathComponent:file];
		[[NSNotificationCenter defaultCenter] postNotificationName:CCPathOfInterestChangedNotification object:item];
	}
	
	[newContents retain];
	[_contents release];
	_contents = newContents;
}

- (void)startNotifier
{
	if(!_path)
	{
		NSLog(@"[Error] Can't start notifier with nil path");
		return;
	}
	
	if(_notifierIsStarted)
	{
		NSLog(@"[Warning] Notifier is already started");
		return;
	}
	

	int fd = open([_path UTF8String], O_EVTONLY);
	
	if (fd < 0)
	{
		NSLog(@"[Error] opening file descriptor at path: %@", _path);
		return;
	}
	
	_notifierIsStarted = YES;	
	
	// Do an initial query
	[self updateContents];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_LINK, queue);
	
	// Event handler
	dispatch_source_set_event_handler(_source, ^{
		[self performSelectorOnMainThread:@selector(delayedUpdateContents) withObject:nil waitUntilDone:NO];
	});
	
	// Cancel handler
	dispatch_source_set_cancel_handler(_source, ^{
		close(fd);
	});
	
	// Start processing events.
	dispatch_resume(_source);
	
}

- (void)stopNotifier
{
	if(_source)
	{
		dispatch_source_cancel(_source);
		dispatch_release(_source);
		_source = nil;
	}
	
	_notifierIsStarted = NO;
}

@end
