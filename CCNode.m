//
//  CCNode.m
//  Violet
//

#import "CCNode.h"

#import "AppDelegate.h"

@implementation CCNode

@dynamic name;
@dynamic sortIndex;
@dynamic parent;
@dynamic path;

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[[self objectID] URIRepresentation] forKey:@"objectId"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	NSURL *objectId = [decoder decodeObjectForKey:@"objectId"];
	NSManagedObject *object = nil;
	if(objectId)
	{
		object = [[AppDelegate defaultManagedObjectContext] objectWithID:[[[AppDelegate defaultManagedObjectContext] persistentStoreCoordinator] managedObjectIDForURIRepresentation:objectId]];
	}
	
	return [object retain];
}

- (BOOL)isLeaf
{
	return NO;
}

- (BOOL)isDeviceNode
{
	return NO;
}

- (BOOL)isGroupNode
{
	return NO;
}

- (BOOL)isItemNode
{
	return NO;
}

@end
