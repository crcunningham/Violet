//
//  AppDelegate.m
//  Violet
//

#import "AppDelegate.h"

#import "CCPathMonitor.h"
#import "CCGroupNode.h"
#import "CCDeviceGroupNode.h"
#import "CCItemNode.h"
#import "CCDeviceItemNode.h"
#import "CCLibrary.h"
#import "CCNetworkReachability.h"
#import "CCOutlineView.h"

#define DevicesDisabled

static NSString * const LibraryItemName			= @"Library";
static NSString * const DevicesItemName			= @"Devices";
static NSString * const CCPasteboardType	    = @"CCPasteboardType";
static NSString * const CCDefaultSeletionKey    = @"CCDefaultSeletionKey";
static NSString * const CCDefaultLibraryPathKey = @"CCDefaultLibraryPathKey";
static NSString * const CCKnownLibrariesKey		= @"CCKnownLibrariesKey";
static NSString * const CCHasLaunchedBefore		= @"CCHasLaunchedBefore";

static NSString * const CCDevicePath			= @"/Volumes";

static const CGFloat SplitViewDividerMin	= 175.0;
static const CGFloat SplitViewDividerMax	= 450.0;
static const NSInteger LibraryItemSortIndex = 10;
static const NSInteger DevicesItemSortIndex = NSIntegerMax;

@interface AppDelegate (Private)

- (void)_debugDeleteGroups;
- (void)_debugAddNodes;

- (void)searchQueryNoteHandler:(NSNotification *)note;
- (void)searchForKnownLibraries;
- (void)stopSearchForKnownLibraries;
- (void)runLibraryChooser;

- (void)runPreferencesChanger;

- (void)deleteDeviceNode:(CCNode *)node;
- (void)pathOfInterestChanged:(NSNotification *)note;

- (void)reachabilityChanged:(NSNotification* )note;

- (void)recalculateSortIndexes;
- (NSArray *)sortDescriptors;

- (void)ensureDeviceGroupExists;
- (void)ensureSpecialGroups;
- (void)cleanStaleDeviceNodes;

+ (NSArray *)acceptedDragTypes;
+ (NSArray *)acceptedFilenameExtensions;

@end

@implementation AppDelegate

@synthesize window;
@synthesize sourceList;
@synthesize sourceListNameColumn;
@synthesize sourceListScrollView;
@synthesize libraryChooserWindow;
@synthesize libraryChooserTable;
@synthesize libraryChooserChooseButton;
@synthesize libraryChooserKnownPaths;
@synthesize searchInProgressIndicator;
@synthesize libraryChooserNameTableColumn;
@synthesize libraryChooserPathTableColumn;
@synthesize preferencesWindow;

#pragma mark Debug

- (void)_debugDeleteGroups
{
	NSManagedObjectContext * context = [self managedObjectContext];
		
	NSFetchRequest * fetch = [[[NSFetchRequest alloc] init] autorelease];
	[fetch setEntity:[NSEntityDescription entityForName:@"GroupNode" inManagedObjectContext:context]];
	NSArray * result = [context executeFetchRequest:fetch error:nil];
	
	for (id object in result)
	{
		[context deleteObject:object];
	}	
}

- (void)_debugAddNodes
{	
	CCItemNode *item = [CCItemNode itemNode];
	[item setName:@"Random Item 1"];
	[item setSortIndex:[NSNumber numberWithInteger:0]];
	[_libraryNode addChild:item];
	
	item = [CCItemNode itemNode];
	[item setName:@"Random Item 2"];
	[item setSortIndex:[NSNumber numberWithInteger:2000]];
	[_libraryNode addChild:item];
	
	item = [CCItemNode itemNode];
	[item setName:@"Random Iwwwwwwwwwwwwwwwwwwwwwtem 3"];
	[item setSortIndex:[NSNumber numberWithInteger:3000]];
	[_libraryNode addChild:item];
	
	CCGroupNode *g = [CCGroupNode groupNode];
	[g setName:@"A Group"];
	[_libraryNode addChild:g];
	[g setSortIndex:[NSNumber numberWithInteger:5000]];
	
	item = [CCItemNode itemNode];
	[item setName:@"Random Item 33"];
	[item setSortIndex:[NSNumber numberWithInteger:3000]];
	[g addChild:item];
	
	g = [CCGroupNode groupNode];
	[g setName:@"Another Group33333333333qweqweqw1223"];
	[_libraryNode addChild:g];
	[g setSortIndex:[NSNumber numberWithInteger:8000]];
	
	item = [CCItemNode itemNode];
	[item setName:@"Random Item s"];
	[item setSortIndex:[NSNumber numberWithInteger:3000]];
	[g addChild:item];
	
	g = [CCGroupNode groupNode];
	[g setName:@"Third Group"];
	[_libraryNode addChild:g];
	[g setSortIndex:[NSNumber numberWithInteger:8000]];
	
	item = [CCItemNode itemNode];
	[item setName:@"Random Item 4"];
	[item setSortIndex:[NSNumber numberWithInteger:3000]];
	[g addChild:item];
}

#pragma mark -

#pragma mark Library Chooser


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	if([object isEqual:_query])
	{
		NSMutableArray *array = [NSMutableArray array];
		
		for(NSMetadataItem *item in [_query results])
		{
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:[item valueForAttribute:(NSString *)kMDItemDisplayName], @"name",
							  [item valueForAttribute:(NSString *)kMDItemPath], @"path", nil]];
		}
		
		[self setLibraryChooserKnownPaths:array];
		
		[[NSUserDefaults standardUserDefaults] setObject:array forKey:CCKnownLibrariesKey];
		
		[libraryChooserTable reloadData];
	}
}

- (void)searchQueryNoteHandler:(NSNotification *)note
{
	id object = [note object];
	
	if([object isEqualTo:_query])
	{
		[self stopSearchForKnownLibraries];
	}
}

- (void)searchForKnownLibraries
{
	NSArray *defaults = [[NSUserDefaults standardUserDefaults] objectForKey:CCKnownLibrariesKey];
	
	if([defaults count] > 0)
	{
		NSMutableArray *valid = [NSMutableArray array];
		
		for(NSDictionary *library in defaults)
		{
			if([[NSFileManager defaultManager] fileExistsAtPath:[library objectForKey:@"path"]])
			{
				[valid addObject:library];
			}
		}
		
		[self setLibraryChooserKnownPaths:valid];
		[libraryChooserTable reloadData];
	}
	
	_query = [[NSMetadataQuery alloc] init];
	
	NSString *libaryFormat = [NSString stringWithFormat:@"*.%@", [CCLibrary libraryExtension]];
	id predicate = [NSPredicate predicateWithFormat:@"(kMDItemFSName like[c] %@)", libaryFormat];
	[_query setPredicate:predicate];
	[_query setSearchScopes:[NSArray arrayWithObject:NSHomeDirectory()]];
	[_query addObserver:self forKeyPath:@"results" options:0 context:nil];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(searchQueryNoteHandler:)
												 name:NSMetadataQueryDidFinishGatheringNotification
											   object:_query];
	
	[_query startQuery];
	
	[searchInProgressIndicator startAnimation:self];
	
}

- (void)stopSearchForKnownLibraries
{
	if([_query isStarted])
	{
		[_query stopQuery];
		[_query release];
		_query = nil;
	}
	
	[searchInProgressIndicator stopAnimation:self];
}

- (void)runLibraryChooser
{
	_chooserCompleted = NO;
	[self searchForKnownLibraries];
	
	NSModalSession session = [NSApp beginModalSessionForWindow:libraryChooserWindow];
	
	while(!_chooserCompleted) 
	{
		if ([NSApp runModalSession:session] != NSRunContinuesResponse)
		{
			
			if(!_chooserCompleted)
			{
				// Other dialogs can bump us out of our modal session before we want to leave
				// We just keep starting sessions until we're ready to leave
				[NSApp beginModalSessionForWindow:libraryChooserWindow];
			}
			else 
			{
				break;
			}
		}
		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
	}
	
	[NSApp endModalSession:session];
	[self setLibraryChooserWindow:nil];
	[self stopSearchForKnownLibraries];
}

#pragma mark -

#pragma mark Preferences

- (void)runPreferencesChanger
{
	_preferenceChangesCompleted = NO;
	
	[preferencesWindow center];

	NSModalSession session = [NSApp beginModalSessionForWindow:preferencesWindow];
	
	while(!_preferenceChangesCompleted) 
	{
		if ([NSApp runModalSession:session] != NSRunContinuesResponse)
		{
			
			if(!_preferenceChangesCompleted)
			{
				// Other dialogs can bump us out of our modal session before we want to leave
				// We just keep starting sessions until we're ready to leave
				[NSApp beginModalSessionForWindow:preferencesWindow];
			}
			else 
			{
				break;
			}
		}
	}
	
	[NSApp endModalSession:session];
}

#pragma mark -

#pragma mark Basics

- (void)awakeFromNib
{
	NSNumber *hasLaunchedBefore = [[NSUserDefaults standardUserDefaults] objectForKey:CCHasLaunchedBefore];
	
	if(!hasLaunchedBefore)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:CCHasLaunchedBefore];
	}
	
	_preferenceChangesCompleted = YES;
	_chooserCompleted			= YES;
	_isFirstLaunch				= ![hasLaunchedBefore boolValue];
	_createNewLibrary			= _isFirstLaunch;
	_libraryNode				= nil;
	libraryChooserKnownPaths	= nil;
	_monitor					= nil;
	_internetReach				= nil;
	_selectedLibraryPath		= [[NSUserDefaults standardUserDefaults] objectForKey:CCDefaultLibraryPathKey];
	_library					= [[CCLibrary alloc] init];
	
	// Double click on the chooser table to chose an library
	[libraryChooserTable setDoubleAction:@selector(choose:)];
	
	[sourceList registerForDraggedTypes:[AppDelegate acceptedDragTypes]];
}

- (void)dealloc 
{
	[_monitor release];
	[_internetReach release];
	
	[_library release];
	[_selectedLibraryPath release];
	
	[libraryChooserKnownPaths release];
	[_libraryNode release];
	
    [window release];
	[sourceList release];
	[sourceListNameColumn release];
	[sourceListScrollView release];
	[treeController release];
	[libraryChooserWindow release];
	
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}

#pragma mark -

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)note
{	
	CGEventRef event = CGEventCreate(NULL);
	CGEventFlags flags = CGEventGetFlags(event);
	CFRelease(event);
	
	if (flags & kCGEventFlagMaskAlternate)
	{		
		[self runLibraryChooser];
	}
	
	while(![[NSFileManager defaultManager] fileExistsAtPath:_selectedLibraryPath] && !_createNewLibrary)
	{
		[self runLibraryChooser];
	}
	
	[_library openLibraryAtPath:_selectedLibraryPath createIfMissing:_createNewLibrary];
	
	if(_isFirstLaunch)
	{
		[window center];
	}
	
	[window makeKeyAndOrderFront:self];
	
	treeController = [[NSTreeController alloc] initWithContent:nil];
	[treeController setManagedObjectContext:[self managedObjectContext]];
	[treeController setChildrenKeyPath:@"children"];
	[treeController setEntityName:@"Node"];
	[treeController setFetchPredicate:[NSPredicate predicateWithFormat:@"parent == nil"]];
	[treeController setAutomaticallyPreparesContent:YES];
	[treeController setAvoidsEmptySelection:NO];
	[treeController bind:@"managedObjectContext" toObject:self withKeyPath:@"managedObjectContext" options:nil];
	[treeController bind:@"sortDescriptors" toObject:self withKeyPath:@"sortDescriptors" options:nil];
	
	// Not sure how to get the tree controller to work without this 
	[treeController prepareContent];
	
	[sourceListNameColumn bind:@"value" toObject:treeController withKeyPath:@"arrangedObjects.name" options:nil];
	[sourceList reloadData];
	
//	[self _debugDeleteGroups];
	
	[self cleanStaleDeviceNodes];
	[self ensureSpecialGroups];
	
//	[self _debugAddNodes];
	
	NSArray *array    = [[NSUserDefaults standardUserDefaults] objectForKey:CCDefaultSeletionKey];
	NSIndexPath *path = nil;
	
	if([array count] > 0)
	{
		path = [NSIndexPath indexPathWithIndex:[[array objectAtIndex:0] integerValue]];
		
		for(NSUInteger i=1; i<[array count]; i++)
		{
			path = [path indexPathByAddingIndex:[[array objectAtIndex:i] integerValue]];
		}
	}
	else 
	{
		path = [NSIndexPath indexPathWithIndex:-1];
	}

	// Performing the selection right now doesn't seem to work
	[treeController performSelector:@selector(setSelectionIndexPaths:) withObject:[NSArray arrayWithObject:path] afterDelay:0.0];
	
	// Observer network changes 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:CCNetworkReachabilityChangeNotification object:nil];
    _internetReach = [[CCNetworkReachability reachabilityForHost:nil] retain];
	[_internetReach startNotifier];
	
#ifndef DevicesDisabled
	// Observe path changes where devices are mounted
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pathOfInterestChanged:) name:CCPathOfInterestChangedNotification object:nil];
	_monitor = [[CCPathMonitor alloc] initWithPath:CCDevicePath];
	[_monitor startNotifier];
#endif // DevicesDisabled
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[_internetReach stopNotifier];
	
	NSMutableArray *index  = [NSMutableArray array];
	NSIndexPath *indexPath = [treeController selectionIndexPath];
	
	for(NSUInteger i=0; i<[indexPath length]; i++)
	{
		[index addObject:[NSNumber numberWithInteger:[indexPath indexAtPosition:i]]];
	}
	
	if([index count] > 0)
	{
		[[NSUserDefaults standardUserDefaults] setObject:index forKey:CCDefaultSeletionKey];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[_library path] forKey:CCDefaultLibraryPathKey];
}

/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }
	
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}

#pragma mark -

#pragma mark Device Changes

- (void)pathOfInterestChanged:(NSNotification *)note
{
	id object = [note object];
	
	if([object isKindOfClass:[NSString class]])
	{
		NSString *item = (NSString *)object;

		
		if([[NSFileManager defaultManager] fileExistsAtPath:item])
		{
			DeviceType type = [_monitor deviceTypeForPath:item];
			type = type;
		}
		else 
		{			
			// Need to add code to validate the device
			for(id object in [_devices children])
			{
				if(([object isKindOfClass:[CCDeviceItemNode class]] && [(CCDeviceItemNode *)object isDeviceNode])
				   ||([object isKindOfClass:[CCDeviceGroupNode class]] && [(CCDeviceGroupNode *)object isDeviceNode]))
				{
					NSString *path = [(CCDeviceItemNode *)object path];
					
					if(![[NSFileManager defaultManager] fileExistsAtPath:path])
					{
						[self deleteDeviceNode:object];
					}
				}
			}
			
		}
	}
	
	[[self managedObjectContext] processPendingChanges];

	if(_devices && [[_devices children] count] < 1)
	{
		[[self managedObjectContext] deleteObject:_devices];
		_devices = nil;
	}
	
	[self recalculateSortIndexes];
	[sourceList reloadData];
}
					
- (void)deleteDeviceNode:(CCNode *)node
{
	if(![node isDeviceNode])
	{
		return;
	}
	
	[[self managedObjectContext] deleteObject:node];
}
						 
#pragma mark -

#pragma mark Network Reachability

- (void)reachabilityChanged:(NSNotification* )note
{
	id object = [note object];
	
	if([object isKindOfClass:[CCNetworkReachability class]])
	{
		CCNetworkReachability *reach = (CCNetworkReachability *)object;
		
		if(reach == _internetReach)
		{
			if([reach connectionAvailable])
			{
				NSLog(@"Internet connection available");
			}
			else 
			{
				NSLog(@"Internet connection not available");
			}
		}
	}
}

#pragma mark -

#pragma mark Sorting
- (void)recalculateSortIndexes
{
	NSMutableArray *mutableArray = [NSMutableArray array];
	
	[_libraryNode setSortIndex:[NSNumber numberWithInteger:LibraryItemSortIndex]];
	
	for (CCNode *node in [[_libraryNode children] sortedArrayUsingDescriptors:[self sortDescriptors]]) 
	{
		[mutableArray addObject:node];
		
		if([node isKindOfClass:[CCGroupNode class]])
		{
			NSSet *children = [(CCGroupNode *)node children];
			
			if([children count] > 0)
			{
				NSArray *array = [children sortedArrayUsingDescriptors:[self sortDescriptors]];
				[mutableArray addObjectsFromArray:array];
			}
		}
	}
	
	[mutableArray sortUsingDescriptors:[self sortDescriptors]];
	
	for(NSUInteger i=0; i<[mutableArray count]; i++)
	{
		[[mutableArray objectAtIndex:i] setSortIndex:[NSNumber numberWithInteger:(i+1)*2]];
	}
	
	[treeController rearrangeObjects];
}


- (NSArray *)sortDescriptors;
{
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES] autorelease]];
}

#pragma mark -

#pragma mark Core Data Object Managment 

- (void)ensureDeviceGroupExists
{
	if(_devices)
	{
		return;
	}
	
	NSManagedObjectContext *context = [self managedObjectContext];
	NSFetchRequest * fetch = [[[NSFetchRequest alloc] init] autorelease];
	[fetch setEntity:[NSEntityDescription entityForName:@"GroupNode" inManagedObjectContext:context]];
	NSArray * result = [context executeFetchRequest:fetch error:nil];
	
	for (id item in result)
	{
		if([item isSpecialGroup])
		{
			if([[item name] isEqualToString:DevicesItemName])
			{
				_devices = [item retain];
			}
		}	
	}
	
	if(!_devices)
	{
		_devices = [CCDeviceGroupNode groupNode];
		[_devices setName:DevicesItemName];
		[_devices setIsExpanded:[NSNumber numberWithBool:YES]];
		[_devices setIsSpecialGroup:[NSNumber numberWithBool:YES]];
		[_devices setSortIndex:[NSNumber numberWithInteger:DevicesItemSortIndex]];
		[_devices setParent:nil];
	}
}

- (void)ensureSpecialGroups
{	
	NSManagedObjectContext *context = [self managedObjectContext];
	NSFetchRequest * fetch = [[[NSFetchRequest alloc] init] autorelease];
	[fetch setEntity:[NSEntityDescription entityForName:@"GroupNode" inManagedObjectContext:context]];
	NSArray * result = [context executeFetchRequest:fetch error:nil];
	
	for (id item in result)
	{
		if([item isSpecialGroup])
		{
			if([[item name] isEqualToString:LibraryItemName])
			{
				_libraryNode = [item retain];
			} 
		}		
	}
	
	if(!_libraryNode)
	{
		_libraryNode = [CCGroupNode groupNode];
		[_libraryNode setName:LibraryItemName];
		[_libraryNode setIsExpanded:[NSNumber numberWithBool:YES]];
		[_libraryNode setIsSpecialGroup:[NSNumber numberWithBool:YES]];
		[_libraryNode setSortIndex:[NSNumber numberWithInteger:LibraryItemSortIndex]];
		[_libraryNode setParent:nil];
	}
}

- (void)cleanStaleDeviceNodes
{
	NSManagedObjectContext * context = [self managedObjectContext];
	
	NSFetchRequest * fetch = [[[NSFetchRequest alloc] init] autorelease];
	[fetch setEntity:[NSEntityDescription entityForName:@"Node" inManagedObjectContext:context]];
	NSArray * result = [context executeFetchRequest:fetch error:nil];
	
	for (id object in result)
	{
		if([object isKindOfClass:[CCNode class]] && [(CCNode *)object isDeviceNode])
		{
			NSLog(@"Deleting %@", object);
			[context deleteObject:object];
		}
	}
}

#pragma mark -

#pragma mark Preferences Changer IBActions

- (IBAction)showPreferences:(id)sender
{
	[self runPreferencesChanger];
}

- (IBAction)preferencesChangesDone:(id)sender
{
	_preferenceChangesCompleted = YES;
	
	[preferencesWindow close];
	[NSApp stopModal];
}

#pragma mark -

#pragma mark Library Chooser IBActions

- (IBAction)chooseOther:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	[panel setAllowsMultipleSelection:NO];
	[panel setAllowedFileTypes:[NSArray arrayWithObject:[CCLibrary libraryExtension]]];
	
	[panel beginSheetForDirectory:[CCLibrary documentsDirectory]
							 file:nil
				   modalForWindow:libraryChooserWindow
					modalDelegate:self
				   didEndSelector:@selector(libraryChooserOpenPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];
}

- (void)libraryChooserOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertDefaultReturn)
	{
		NSArray *urls = [panel URLs];
		
		if([urls count] != 1)
		{
			NSLog(@"[Error] this shouldn't happen");
		}
		else
		{
			_selectedLibraryPath = [[[urls objectAtIndex:0] path] retain];
			_chooserCompleted  = YES;
			[window makeKeyAndOrderFront:self];
			[libraryChooserWindow close];
			[NSApp stopModal];
		}
	}
}

- (IBAction)choose:(id)sender
{
	NSInteger row = [libraryChooserTable selectedRow];
	
	if(row >= 0 && row < [libraryChooserKnownPaths count])
	{
		_selectedLibraryPath = [[libraryChooserKnownPaths objectAtIndex:row] objectForKey:@"path"];
		
		_chooserCompleted = YES;
		[window makeKeyAndOrderFront:self];
		[libraryChooserWindow close];
		[NSApp stopModal];

	}
}

- (IBAction)createNew:(id)sender
{
	NSLog(@"Not yet implemented: <%@ %@>", [self class], NSStringFromSelector(_cmd));
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	[panel setAllowedFileTypes:[NSArray arrayWithObject:[CCLibrary libraryExtension]]];
	
	[panel beginSheetForDirectory:[CCLibrary documentsDirectory]
							 file:nil
				   modalForWindow:libraryChooserWindow
					modalDelegate:self
				   didEndSelector:@selector(libraryChooserSavePanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];

}

- (void)libraryChooserSavePanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertDefaultReturn)
	{
		NSArray *urls = [panel URLs];
		
		NSLog(@"urls: %@", urls);
		
		if([urls count] != 1)
		{
			NSLog(@"[Error] this shouldn't happen");
		}
		else
		{
			_createNewLibrary = YES;
			_chooserCompleted = YES;
			_selectedLibraryPath = [[[urls objectAtIndex:0] path] retain];			
			[window makeKeyAndOrderFront:self];
			[libraryChooserWindow close];
			[NSApp stopModal];
		}
	}
}

#pragma mark IBActions

- (IBAction)addItem:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	[panel setAllowsMultipleSelection:NO];
	[panel setAllowedFileTypes:[NSArray arrayWithObject:@"pdf"]];
	
	[panel beginSheetForDirectory:[CCLibrary homeDirectory]
							 file:nil
				   modalForWindow:window
					modalDelegate:self
				   didEndSelector:@selector(addItemOpenPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];
	
}

- (void)addItemOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertDefaultReturn)
	{
		NSArray *urls = [panel URLs];
		
		NSLog(@"urls: %@", urls);
		
		if([urls count] != 1)
		{
			NSLog(@"[Error] this shouldn't happen");
		}
		else
		{
			NSString *file = [[urls objectAtIndex:0] path];			

			NSString *addedPath = [_library addFileToLibrary:file];
			
			if(addedPath)
			{
				NSLog(@"Added item at path: %@", addedPath);
				
				CCItemNode *item = [CCItemNode itemNode];
				
				[item setName:[[addedPath lastPathComponent] stringByDeletingPathExtension]];
				[item setPath:addedPath];
				[_libraryNode addChild:item];
			}
		}
	}
}

- (IBAction)addGroup:(id)sender
{
	NSArray *selected = [treeController selectedObjects];
	
	CCGroupNode *parent = _libraryNode;
	
	if([selected count] == 1)
	{
		id object = [selected lastObject];
		
		if([object isKindOfClass:[CCGroupNode class]])
		{
			parent = (CCGroupNode *)object;
		}
		else if([object isKindOfClass:[CCItemNode class]])
		{
			CCNode *node = [(CCItemNode *)object parent];
			
			if([node isKindOfClass:[CCGroupNode class]])
			{
				parent = (CCGroupNode *)node;
			}
		}
	}
	
	CCGroupNode *group = [CCGroupNode groupNode];
	[group setName:@"New Group"];
	[parent addChild:group];
	[parent setIsExpanded:[NSNumber numberWithBool:YES]];
	
	
	[self recalculateSortIndexes];
}

- (IBAction)delete:(id)sender
{
	NSArray *selected = [treeController selectedObjects];
	
	if([selected count] > 0)
	{
		NSBeginAlertSheet(@"Do you really want to delete the selected item?", 
						  @"Delete", 
						  nil, 
						  @"Cancel",             
						  window, 
						  self,                   
						  @selector(deleteSheetEnded:returnCode:contextInfo:),
						  NULL,                   
						  selected,
						  @"There is no undo for this operation.");
	}
}

- (void)deleteSheetEnded:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertDefaultReturn)
	{
		if(contextInfo && [(id)contextInfo isKindOfClass:[NSArray class]])
		{
			NSArray *selected = (NSArray *)contextInfo;
			
			for(id object in selected)
			{
				if ([object isKindOfClass:[CCNode class]] && !([(CCNode *)object isGroupNode] && [[(CCGroupNode *)object isSpecialGroup] boolValue])) 
				{
					if([(CCNode *)object isDeviceNode])
					{
						NSLog(@"Deleting from devices is not implemented yet");
					}
					else 
					{
						[[self managedObjectContext] deleteObject:object];
					}
					
				}
			}
			
			[self recalculateSortIndexes];
		}
	}
}

- (IBAction)export:(id)sender
{
	NSLog(@"Not yet implemented: <%@ %@>", [self class], NSStringFromSelector(_cmd));
	
	NSLog(@"Should export node: %@", [sourceList clickedNode]);
}

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
	
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }
	
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

#pragma mark -

#pragma mark Drag and Drop

+ (NSArray *)acceptedDragTypes
{
	return [NSArray arrayWithObjects:CCPasteboardType, NSFilenamesPboardType, nil];
}

+ (NSArray *)acceptedFilenameExtensions
{
	return [NSArray arrayWithObjects:@"pdf", nil];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
	NSMutableArray *array = [NSMutableArray array];
	
	BOOL result = YES;
	
	for(id item in items)
	{
		id object = [item representedObject];
		
		if ([object isKindOfClass:[CCItemNode class]] || ([object isKindOfClass:[CCGroupNode class]] && ![[(CCGroupNode *)object isSpecialGroup] boolValue]) )
		{
			[array addObject:object];
		}
	}
	
	if([array count] > 0)
	{
		// Copy the row numbers to the pasteboard.
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
		[pasteboard declareTypes:[NSArray arrayWithObject:CCPasteboardType] owner:self];
		[pasteboard setData:data forType:CCPasteboardType];
	}
	else 
	{
		result = NO;
	}
	
	
    return result;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	id object = [item representedObject];
	NSDragOperation result = NSDragOperationNone;
	
	NSDragOperation type = [info draggingSourceOperationMask];
	
	if ((type & NSDragOperationPrivate) && [object isKindOfClass:[CCGroupNode class]]) 
	{
		result = NSDragOperationPrivate;
	}
	else if((type & NSDragOperationCopy) && [object isKindOfClass:[CCGroupNode class]])
	{
		NSPasteboard *pasteboard = [info draggingPasteboard];
		NSString *desiredType = [pasteboard availableTypeFromArray:[AppDelegate acceptedDragTypes]];
		
		if([desiredType isEqualToString:NSFilenamesPboardType])
		{
			NSArray *filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
			
			for(NSString *filename in filenames)
			{
				NSString *extension = [[filename pathExtension] lowercaseString];
				
				for(NSString *accepted in [AppDelegate acceptedFilenameExtensions])
				{
					if ([extension isEqualToString:accepted])
					{
						result = NSDragOperationCopy;
						break;
					}
				}
			}
		}
	}

    return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
	NSDragOperation type = [info draggingSourceOperationMask];
	BOOL result = NO;
	
	if(type & NSDragOperationPrivate)
	{
		NSData *data = [[info draggingPasteboard] dataForType:CCPasteboardType];
		
		NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		id object = [item representedObject];
		
		if([object isKindOfClass:[CCGroupNode class]])
		{
			for(id child in array)
			{
				if([child isKindOfClass:[CCItemNode class]] || [child isKindOfClass:[CCGroupNode class]])
				{
					if([object isAncestorOfNode:child])
					{
						return NO;
					}
					else
					{
						[(CCGroupNode *)object addChild:(CCNode*)child atIndex:index];
					}
				}
			}
		}
		
		[self recalculateSortIndexes];
		result = YES;
	}
	else if(type & NSDragOperationCopy)
	{
		
		NSPasteboard *pasteboard = [info draggingPasteboard];
		NSString *desiredType = [pasteboard availableTypeFromArray:[AppDelegate acceptedDragTypes]];
		NSMutableArray *filesToProcess = [NSMutableArray array];
		
		if([desiredType isEqualToString:NSFilenamesPboardType])
		{
			NSArray *filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
			
			for(NSString *filename in filenames)
			{
				NSString *extension = [[filename pathExtension] lowercaseString];
				
				for(NSString *accepted in [AppDelegate acceptedFilenameExtensions])
				{
					if ([extension isEqualToString:accepted])
					{
						[filesToProcess addObject:filename];
					}
				}
			}
		}
		
		NSLog(@"Should process files: %@", filesToProcess);

		result = YES;
	}
	
	return result;
}

#pragma mark -

#pragma mark NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
	BOOL result = YES;
	
	if (view == sourceListScrollView)
	{
		result = NO;
	}
	
	return result;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return SplitViewDividerMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	return SplitViewDividerMax;
}

#pragma mark -

#pragma mark NSTableViewDataSouce

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [libraryChooserKnownPaths count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	id result = nil;
	
	if(rowIndex >= 0 && rowIndex < [libraryChooserKnownPaths count])
	{
		if([aTableColumn isEqualTo:libraryChooserNameTableColumn])
		{
			result = [[libraryChooserKnownPaths objectAtIndex:rowIndex] objectForKey:@"name"];
		}
		else if([aTableColumn isEqualTo:libraryChooserPathTableColumn])
		{
			result = [[libraryChooserKnownPaths objectAtIndex:rowIndex] objectForKey:@"path"];
		}
	}
	
	return result;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	[cell setFont:[NSFont fontWithName:[[cell font] fontName] size:11.0]];
	[cell setTextColor:[NSColor blackColor]];

}


#pragma mark -

#pragma mark NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{ 
	// Handled by CoreData
	return NO; 
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{ 
	// Handled by CoreData
	return 0; 
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
	// Handled by CoreData
	return nil; 
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn*)column byItem:(id)item 
{
	// Handled by CoreData
	return nil; 
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	id node = [item representedObject];
		
	if([node isKindOfClass:[CCItemNode class]] || ([node isKindOfClass:[CCGroupNode class]] && ![[(CCGroupNode *)node isSpecialGroup] boolValue]))
	{
		if([object isKindOfClass:[NSString class]])
		{
			[(CCNode *)node setName:object];
		}
	}
}

#pragma mark -

#pragma mark NSOutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSArray *selected = [treeController selectedObjects];
	
	BOOL shouldEnableEdit = YES;
	
	if([selected count] < 1)
	{
		shouldEnableEdit = NO;
	}
	
	for(id object in selected)
	{
		if([object isKindOfClass:[CCNode class]] && [(CCNode *)object isDeviceNode])
		{
			// Until we are able to edit metadata of the device nodes let's just disable edits
			shouldEnableEdit = NO;
		}
	}
	
	[sourceListNameColumn setEditable:shouldEnableEdit];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	id object = [item representedObject];
	
	BOOL result = YES;
	
	if([object isKindOfClass:[CCGroupNode class]] && [[(CCGroupNode *)object isSpecialGroup] boolValue])
	{
		result = NO;
	}
	
	return result;
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification;
{
	id item = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];

	if ([item isKindOfClass:[CCGroupNode class]])
	{
		[item setIsExpanded:[NSNumber numberWithBool:NO]];
	}		 
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification;
{
	id item = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	
	if ([item isKindOfClass:[CCGroupNode class]])
	{
		[item setIsExpanded:[NSNumber numberWithBool:YES]];
	}
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
	id object = [item representedObject];
	
	BOOL result = YES;
	
	if([object isKindOfClass:[CCGroupNode class]] && [[(CCGroupNode *)object isSpecialGroup] boolValue])
	{
		result = NO;
	}
	
	return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	id object = [item representedObject];
	
	BOOL result = YES;
	
	if([object isKindOfClass:[CCGroupNode class]] && [[(CCGroupNode *)object isSpecialGroup] boolValue])
	{
		result = NO;
	}
	
	return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	id object = [item representedObject];

	BOOL result = NO;
	
	if([object isKindOfClass:[CCGroupNode class]] && [[(CCGroupNode *)object isSpecialGroup] boolValue])
	{
		result = YES;
	}

	return result;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	id object = [item representedObject];
		
	if([object isKindOfClass:[CCNode class]])
	{
		if([object isKindOfClass:[CCGroupNode class]])
		{
			if([[(CCGroupNode *)object isSpecialGroup] boolValue])
			{			
				[cell setStringValue:[[cell stringValue] uppercaseString]];
				[cell setFont:[[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:[[cell font] fontName] size:12.0] toHaveTrait:NSBoldFontMask]];
				[cell setTextColor:[NSColor darkGrayColor]];
			}
			else 
			{
				[cell setFont:[NSFont fontWithName:[[cell font] fontName] size:11.0]];
				[cell setTextColor:[NSColor blackColor]];
			}
			
		}
		else if([object isKindOfClass:[CCItemNode class]])
		{
			[cell setTextColor:[NSColor blackColor]];
			[cell setFont:[NSFont fontWithName:[[cell font] fontName] size:11.0]];
		}
		
		if([(CCNode *)object isDeviceNode])
		{
			[cell setEditable:NO];
		}
		else 
		{
			[cell setEditable:YES];
		}
	}
}

#pragma mark -

#pragma mark Core Data

+ (NSManagedObjectContext *)defaultManagedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}

///**
//    Returns the support directory for the application, used to store the Core Data
//    store file.  This code uses a directory named "Violet" for
//    the content, either in the NSApplicationSupportDirectory location or (if the
//    former cannot be found), the system's temporary directory.
// */
//
//
//- (NSString *)applicationSupportDirectory {
//
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
//    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
//    return [basePath stringByAppendingPathComponent:@"Violet"];
//}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The directory for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator) return persistentStoreCoordinator;

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }

//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
	
	NSString *path = [_library path];
    
//    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
//		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
//            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
//            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
//            return nil;
//		}
//    }
    
    NSURL *url = [NSURL fileURLWithPath: [path stringByAppendingPathComponent: @"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType 
                                                configuration:nil 
                                                URL:url 
                                                options:nil 
                                                error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    

    return persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext) return managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];

    return managedObjectContext;
}

/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

#pragma mark -

@end
