//
//  CCOutlineView.m
//  Violet
//
//

#import "CCOutlineView.h"

#import "CCNode.h"
#import "CCGroupNode.h"
#import "CCItemNode.h"

@implementation CCOutlineView

@synthesize clickedNode;

- (void)awakeFromNib
{
	clickedNode  = nil;
	_defaultMenu = nil;
	_itemMenu	 = nil;
	_groupMenu   = nil;
}

- (void)reloadData;
{
	[super reloadData];
	
	for (NSUInteger row = 0; row < [self numberOfRows]; row++) 
	{
		NSTreeNode *item = [self itemAtRow:row];
		
		id object = [item representedObject];
		
		if([object isKindOfClass:[CCGroupNode class]])
		{
			if ([[(CCGroupNode*)object isSpecialGroup] boolValue] || [[(CCGroupNode*)object isExpanded] boolValue]) 
			{
				[self expandItem:item];
			}
		}
	}
}

- (NSMenu *)groupMenu
{
	if (!_groupMenu)
	{
		_groupMenu = [[NSMenu alloc] initWithTitle:@"Group Menu"];
		
		[_groupMenu insertItemWithTitle:@"Delete Group" action:@selector(delete:) keyEquivalent:@"" atIndex:0];

		NSMenuItem *newItem = [[[NSMenuItem alloc] initWithTitle:@"New" action:nil keyEquivalent:@""] autorelease];
		NSMenu *newSubmenu  = [[[NSMenu alloc] initWithTitle:@"New"] autorelease];
		[newSubmenu insertItemWithTitle:@"Group" action:@selector(addGroup:) keyEquivalent:@"" atIndex:0];
		[newSubmenu insertItemWithTitle:@"Item" action:@selector(addItem:) keyEquivalent:@"" atIndex:0];
		[newItem setSubmenu:newSubmenu];
		
		[_groupMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
		[_groupMenu insertItemWithTitle:@"Export Group" action:@selector(export:) keyEquivalent:@"" atIndex:0];
	}
	
	return _groupMenu;
}

- (NSMenu *)itemMenu
{
	if(!_itemMenu)
	{
		_itemMenu = [[NSMenu alloc] initWithTitle:@"Item Menu"];
				
		[_itemMenu insertItemWithTitle:@"Delete Item" action:@selector(delete:) keyEquivalent:@"" atIndex:0];
		
		NSMenuItem *newItem = [[[NSMenuItem alloc] initWithTitle:@"New" action:nil keyEquivalent:@""] autorelease];
		NSMenu *newSubmenu  = [[[NSMenu alloc] initWithTitle:@"New"] autorelease];
		[newSubmenu insertItemWithTitle:@"Group" action:@selector(addGroup:) keyEquivalent:@"" atIndex:0];
		[newSubmenu insertItemWithTitle:@"Item" action:@selector(addItem:) keyEquivalent:@"" atIndex:0];
		[newItem setSubmenu:newSubmenu];
		
		[_itemMenu insertItem:newItem atIndex:0];
		
		[_itemMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
		[_itemMenu insertItemWithTitle:@"Export Item" action:@selector(export:) keyEquivalent:@"" atIndex:0];
	}
	
	return _itemMenu;
}

- (NSMenu *)defaultMenu
{
	if(!_defaultMenu)
	{
		_defaultMenu = [[NSMenu alloc] initWithTitle:@"Default Menu"];
		
		NSMenuItem *newItem = [[[NSMenuItem alloc] initWithTitle:@"New" action:nil keyEquivalent:@""] autorelease];
		NSMenu *newSubmenu  = [[[NSMenu alloc] initWithTitle:@"New"] autorelease];
		[newSubmenu insertItemWithTitle:@"Group" action:@selector(addGroup:) keyEquivalent:@"" atIndex:0];
		[newSubmenu insertItemWithTitle:@"Item" action:@selector(addItem:) keyEquivalent:@"" atIndex:0];
		[newItem setSubmenu:newSubmenu];
		
		[_defaultMenu insertItem:newItem atIndex:0];
	}
	
	return _defaultMenu;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSPoint point	 = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row	 = [self rowAtPoint:point];
	NSTreeNode *item = [self itemAtRow:row];
	id object	     = [item representedObject];
	NSMenu *result	 = nil;
	
	if([object isKindOfClass:[CCNode class]] && [(CCNode *)object isDeviceNode])
	{
		result = nil;
		[self setClickedNode:nil];
	}
	else if([object isKindOfClass:[CCGroupNode class]])
	{
		if(![[(CCGroupNode*)object isSpecialGroup] boolValue])
		{
			result = [self groupMenu];
			[self setClickedNode:(CCNode *)object];
		}
	}
	else if([object isKindOfClass:[CCItemNode class]])
	{
		result = [self itemMenu];
		[self setClickedNode:(CCNode *)object];
	}
	else 
	{
		// Until the device nodes are sorted out
		//result = [self defaultMenu];
		result = nil;
		[self setClickedNode:nil];
	}
	
	
	return result;
}


- (void)dealloc
{
	[_defaultMenu release];
	[_groupMenu release];
	[_itemMenu release];
	
	[super dealloc];
}


@end
