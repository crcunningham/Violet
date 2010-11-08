//
//  CCGroupNode.m
//  Violet
//

#import "CCGroupNode.h"

#import "CCItemNode.h"
#import "AppDelegate.h"

@implementation CCGroupNode

@dynamic isExpanded;
@dynamic isSpecialGroup;
@dynamic children;


+ (CCGroupNode*)groupNode
{	
	return [NSEntityDescription insertNewObjectForEntityForName:@"GroupNode" inManagedObjectContext:[AppDelegate defaultManagedObjectContext]];
}

- (void)addChild:(CCNode *)child
{
	[self addChild:child atIndex:[[self children] count]];
}

- (void)addChild:(CCNode *)child atIndex:(NSInteger)index
{													 
	[child setParent:self];
	
	NSArray *children = [[self children] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES] autorelease]]];
		
	if(index < 1)
	{
		[child setSortIndex:[NSNumber numberWithInt:0]];
	}
	else if(index >= [children count])
	{
		[child setSortIndex:[NSNumber numberWithInteger:[[[children lastObject] sortIndex] integerValue]+1]];
	}
	else {
		[child setSortIndex:[NSNumber numberWithInteger:[[[children objectAtIndex:index-1] sortIndex] integerValue]+1]];
	}

	[[self children] addObject:child];
}

- (BOOL)isAncestorOfNode:(CCNode *)node
{
	CCNode *parent = self;
	
	BOOL isAncestor = NO;
	
	while (parent)
	{
		if([parent isEqualTo:node])
		{
			isAncestor = YES;
			break;
		}
		
		parent = [parent parent];
	}
	
	return isAncestor;
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
	return YES;
}

- (BOOL)isItemNode
{
	return NO;
}

@end
