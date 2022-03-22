#import "UIView+Cylinder.h"
#import <objc/runtime.h>

@implementation UIView(Cylinder)
-(BOOL)wasModifiedByCylinder
{
    return objc_getAssociatedObject(self, @selector(wasModifiedByCylinder));
}

-(void)setWasModifiedByCylinder:(BOOL)wasModifiedByCylinder
{
    objc_setAssociatedObject(self, @selector(wasModifiedByCylinder), @(wasModifiedByCylinder), OBJC_ASSOCIATION_ASSIGN);
}

@end
