//
//  CCLibrary.h
//  Violet
//

#import <Cocoa/Cocoa.h>


@interface CCLibrary : NSObject 
{
	NSString *_path;
	BOOL _libraryIsOpen;
}

+ (NSString *)libraryExtension;
+ (NSString *)homeDirectory;
+ (NSString *)documentsDirectory;

- (NSString *)path;
- (BOOL)openLibraryAtPath:(NSString *)path createIfMissing:(BOOL)create;
- (NSString *)addFileToLibrary:(NSString *)path;

@end
