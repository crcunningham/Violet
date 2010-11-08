//
//  CCOutlineView.h
//  Violet
//

#import <Cocoa/Cocoa.h>

@class CCNode;

@interface CCOutlineView : NSOutlineView
{
	NSMenu *_defaultMenu;
	NSMenu *_groupMenu;
	NSMenu *_itemMenu;
}

@property (assign) CCNode *clickedNode;

@end
