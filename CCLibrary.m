//
//  CCLibrary.m
//  Violet
//
//

#import "CCLibrary.h"

static NSString * const LibraryFolderName = @"Violet.violetlib";
static NSString * const LibraryExtension = @"violetlib";

@implementation CCLibrary

+ (NSString *)libraryExtension
{
	return LibraryExtension;
}

+ (NSString *)homeDirectory
{
	return NSHomeDirectory();
}

+ (NSString *)documentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
	NSString *result = nil;
	
	if ([paths count] < 1) 
	{
		NSLog(@"[Error] Documents folder missing");
		result = NSHomeDirectory();
	}
	else if([paths count] > 1)
	{
		NSLog(@"[Error] Multiple Documents folders returned: %@", paths);
		result = NSHomeDirectory();
	}
	else 
	{
		result = [paths objectAtIndex:0];
	}
	
	return result;
}

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		_path = nil;
		_libraryIsOpen = NO;
	}
	
	return self;
}

- (void) dealloc
{
	[_path release];
	
	[super dealloc];
}

- (NSString *)path
{
	NSString *result = nil;
	
	if (_libraryIsOpen)
	{
		result = _path;
	}
	
	return result;
}

- (BOOL)openLibraryAtPath:(NSString *)path createIfMissing:(BOOL)create
{
	BOOL result = NO;
	NSString *libraryFolder = nil;
	
	if(!path)
	{
		libraryFolder = [[CCLibrary documentsDirectory] stringByAppendingPathComponent:LibraryFolderName];
		BOOL isDirectory = NO;
		
		if([[NSFileManager defaultManager] fileExistsAtPath:libraryFolder isDirectory:&isDirectory])
		{
			if(isDirectory)
			{
				NSLog(@"[Info] Library folder exists at path: %@", libraryFolder);
				result = YES;
			}
			else 
			{
				NSLog(@"[Error] Default documents directory appear to be a file");
			}
		}
		else if(create) 
		{
			NSError *error = nil;
			
			BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:libraryFolder 
													 withIntermediateDirectories:YES
																	  attributes:nil
																		   error:&error];
			
			if(!created)
			{
				NSLog(@"[Error] Unable to create documents directory at path %@ -- %@", libraryFolder, error);
			}
			else 
			{
				NSLog(@"[Info] Created library folder at path: %@", libraryFolder);
				result = YES;
			}
		}
	}
	else
	{
		BOOL isDirectory = NO;

		if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
		{
			if(isDirectory)
			{
				libraryFolder = path;
				result = YES;
			}
		}
		else if(create)
		{
			NSError *error = nil;
			
			BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:path 
													 withIntermediateDirectories:YES
																	  attributes:nil
																		   error:&error];
			
			if(!created)
			{
				NSLog(@"[Error] Unable to create documents directory at path %@ -- %@", libraryFolder, error);
			}
			else 
			{
				NSLog(@"[Info] Created library folder at path: %@", libraryFolder);
				libraryFolder = path;
				result = YES;
			}
		}
	}
	
	if(result)
	{
		NSLog(@"[Info] Opening library at path: %@", libraryFolder);
		_path = [libraryFolder retain];
		_libraryIsOpen = YES;
	}
	
	return result;
}


- (NSString *)addFileToLibrary:(NSString *)path
{
	NSString *result = nil;

	if(_libraryIsOpen)
	{
		NSString *destination = [_path stringByAppendingPathComponent:[path lastPathComponent]];
		NSError *error = nil;
		
		BOOL copied = [[NSFileManager defaultManager] copyItemAtPath:path toPath:destination error:&error];
		
		if(!copied)
		{
			NSLog(@"[Error] Adding file from path '%@' to path '%@' failed: %@", path, destination, error);
			destination = nil;
		}

		result = destination;
	}

	return result;
}


@end
