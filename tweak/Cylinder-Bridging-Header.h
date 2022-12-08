#import "CALayer+Cylinder.h"

@interface SBIconListView : UIView
@property(nonatomic, assign, readonly) NSUInteger maximumIconCount;
@property(nonatomic, assign, readonly) NSUInteger iconColumnsForCurrentOrientation;
@property(nonatomic, assign, readonly) NSUInteger iconRowsForCurrentOrientation;

- (void)enumerateIconViewsUsingBlock:(void (^)(UIView* _Nonnull icon, NSUInteger idx, BOOL *stop))block;

@end