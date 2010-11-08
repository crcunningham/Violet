//
//  CCDeviceItemNode.m
//  Violet
//

#import "CCDeviceItemNode.h"

#import "AppDelegate.h"

@implementation CCDeviceItemNode

+ (CCDeviceItemNode *)deviceItemNode
{
	return [NSEntityDescription insertNewObjectForEntityForName:@"DeviceItemNode" inManagedObjectContext:[AppDelegate defaultManagedObjectContext]];
}

- (BOOL)isLeaf
{
	return YES;
}

- (BOOL)isDeviceNode
{
	return YES;
}

- (BOOL)isGroupNode
{
	return YES;
}

- (BOOL)isItemNode
{
	return NO;
}

@end
