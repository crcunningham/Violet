//
//  AppDelegate.h
//  Violet
//

#import <Cocoa/Cocoa.h>

@class CCGroupNode;
@class CCOutlineView;
@class CCNetworkReachability;
@class CCLibrary;
@class CCPathMonitor;

@interface AppDelegate : NSObject 
{
	CCGroupNode *_libraryNode;
	CCGroupNode *_devices;
	
    NSWindow *window;
	CCOutlineView *sourceList;
	NSTableColumn *sourceListNameColumn;
	NSScrollView *sourceListScrollView;
	NSTreeController *treeController;
    
	NSWindow *libraryChooserWindow;
	NSTableView *libraryChooserTable;
	NSButton *libraryChooserChooseButton;
	NSProgressIndicator *searchInProgressIndicator;
	NSTableColumn *libraryChooserNameTableColumn;
	NSTableColumn *libraryChooserPathTableColumn;
	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	CCNetworkReachability *_internetReach;
	
	CCPathMonitor *_monitor;
	
	CCLibrary *_library;
	NSString *_selectedLibraryPath;	
	BOOL _createNewLibrary;
	BOOL _chooserCompleted;
	NSArray *libraryChooserKnownPaths;
	NSMetadataQuery *_query;

	NSWindow *preferencesWindow;
	BOOL _preferenceChangesCompleted;
	
	BOOL _isFirstLaunch;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSOutlineView *sourceList;
@property (nonatomic, retain) IBOutlet NSTableColumn *sourceListNameColumn;
@property (nonatomic, retain) IBOutlet NSScrollView *sourceListScrollView;

@property (nonatomic, retain) IBOutlet NSWindow *libraryChooserWindow;
@property (nonatomic, retain) IBOutlet NSTableView *libraryChooserTable;
@property (nonatomic, retain) IBOutlet NSButton *libraryChooserChooseButton;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *searchInProgressIndicator;
@property (nonatomic, retain) IBOutlet NSTableColumn *libraryChooserNameTableColumn;
@property (nonatomic, retain) IBOutlet NSTableColumn *libraryChooserPathTableColumn;

@property (nonatomic, retain) IBOutlet NSWindow *preferencesWindow;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (retain) NSArray *libraryChooserKnownPaths;

+ (NSManagedObjectContext *)defaultManagedObjectContext;

- (IBAction)showPreferences:(id)sender;
- (IBAction)preferencesChangesDone:(id)sender;

- (IBAction)chooseOther:(id)sender;
- (IBAction)choose:(id)sender;
- (IBAction)createNew:(id)sender;

- (IBAction)addItem:(id)sender;
- (IBAction)addGroup:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)export:(id)sender;

- (IBAction)saveAction:sender;

@end
