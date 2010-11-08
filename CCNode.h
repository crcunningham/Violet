//
//  CCNode.h
//  Violet
//

#import <Cocoa/Cocoa.h>


@interface CCNode : NSManagedObject
{

}

@property (retain) NSString *name;
@property (retain) NSNumber *sortIndex;
@property (retain) CCNode *parent;
@property (retain) NSString *path;

@property (readonly) BOOL isLeaf;
@property (readonly) BOOL isDeviceNode;
@property (readonly) BOOL isGroupNode;
@property (readonly) BOOL isItemNode;

@end
