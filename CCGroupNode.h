//
//  CCGroupNode.h
//  Violet
//

#import <Cocoa/Cocoa.h>

#import "CCNode.h"

@interface CCGroupNode : CCNode 
{

}

@property (assign) NSNumber *isExpanded;
@property (assign) NSNumber *isSpecialGroup;
@property (retain) NSMutableSet *children;

+ (CCGroupNode*)groupNode;

- (void)addChild:(CCNode *)child;
- (void)addChild:(CCNode *)child atIndex:(NSInteger)index;
- (BOOL)isAncestorOfNode:(CCNode *)node;
- (BOOL)isLeaf;

@end
