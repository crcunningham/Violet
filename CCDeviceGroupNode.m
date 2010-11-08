//
//  CCDeviceGroupNode.m
//  Violet
//

#import "CCDeviceGroupNode.h"

#import "AppDelegate.h"

@implementation CCDeviceGroupNode

+ (CCDeviceGroupNode *)deviceGroupNode
{
	return [NSEntityDescription insertNewObjectForEntityForName:@"DeviceGroupNode" inManagedObjectContext:[AppDelegate defaultManagedObjectContext]];
}

- (BOOL)isLeaf
{
	return NO;
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
