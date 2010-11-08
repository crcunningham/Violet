//
//  CCItemNode.m
//  Violet
//

#import "CCItemNode.h"

#import "AppDelegate.h"
#import "CCGroupNode.h"

@implementation CCItemNode

@dynamic parent;

+ (CCItemNode *)itemNode
{
	return [NSEntityDescription insertNewObjectForEntityForName:@"ItemNode" inManagedObjectContext:[AppDelegate defaultManagedObjectContext]];
}

- (BOOL)isLeaf
{
	return YES;
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
	return YES;
}

@end
