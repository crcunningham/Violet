//
//  CCItemNode.h
//  Violet
//

#import <Cocoa/Cocoa.h>

#import "CCNode.h"

@interface CCItemNode : CCNode
{

}

+ (CCItemNode *)itemNode;

- (BOOL)isLeaf;

@end
