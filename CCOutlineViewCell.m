//
//  CCOutlineViewCell.m
//  Violet
//

#import "CCOutlineViewCell.h"

@implementation CCOutlineViewCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{

	NSString *string = [self stringValue];
	NSColor *color   = [self textColor];
	NSFont *font	 = [self font];
	
	NSDictionary *textAttributes;
	
	if ([self isHighlighted]) 
	{
		color = [NSColor whiteColor];
		
		textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						  color , NSForegroundColorAttributeName,
						  font, NSFontAttributeName,
						  nil];
	}
	else
	{
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(0.0, -2.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]];
		
		textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						  color , NSForegroundColorAttributeName,
						  shadow, NSShadowAttributeName,
						  font, NSFontAttributeName,
						  nil];
		[shadow release];
	}
	
	NSSize size = [string sizeWithAttributes:textAttributes];
	cellFrame.origin.y += cellFrame.size.height/2 - size.height/2;	
	cellFrame.origin.x += 2;

	[string drawWithRect:cellFrame options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
}

- (void)setObjectValue:(id <NSCopying>)obj
{
//	NSLog(@"%@", obj);
	[super setObjectValue:obj];
}

- (void)setStringValue:(NSString *)aString
{
	[super setStringValue:aString];
}

@end
