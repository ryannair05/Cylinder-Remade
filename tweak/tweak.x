#import "tweak.h"
#import <objc/runtime.h> 
#import <objc/message.h>
#import "../Defines.h"

static CylinderAnimator* animator;
static u_int32_t _randSeedForCurrentPage;

static BOOL SBIconListView_wasModifiedByCylinder(SBIconView * self, SEL _cmd) { 
    return [objc_getAssociatedObject(self, @selector(wasModifiedByCylinder)) boolValue];
}
     
static void SBIconListView_setWasModifiedByCylinder(SBIconView * self, SEL _cmd, BOOL wasModifiedByCylinder) { 
    objc_setAssociatedObject(self, @selector(wasModifiedByCylinder), @(wasModifiedByCylinder), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void reset_icon_layout(__unsafe_unretained SBIconListView *self)
{
    self.layer.transform = CATransform3DIdentity;
    [self.layer restorePosition];
    self.alpha = 1;
    
    [self enumerateIconViewsUsingBlock:^(SBIconView *v, NSUInteger idx, BOOL *stop) {
        v.layer.transform = CATransform3DIdentity;
    }];

}

static void page_swipe(SBFolderView *self, SBIconScrollView *scrollView)
{
    CGRect eye = {scrollView.contentOffset, scrollView.frame.size};

    for (__unsafe_unretained SBIconListView *view in self.iconListViews) {
        // make sure the view actually has icons
        if (view.subviews.count < 1) continue;

        if (view.wasModifiedByCylinder)
        {
            reset_icon_layout(view);
        }

        if(CGRectIntersectsRect(eye, view.frame))
        {
            const float offset = scrollView.contentOffset.x - view.frame.origin.x;

            [animator manipulate:(UIView *)view offset:offset rand:_randSeedForCurrentPage]; //defined in CylinderAnimator.swift
            view.wasModifiedByCylinder = true;
        }
    }
}

static void end_scroll(__unsafe_unretained SBFolderView *self)
{
    [self enumerateIconListViewsUsingBlock:^(SBIconListView *view)  {
        reset_icon_layout(view);
        [view setAlphaForAllIcons:1];
        view.wasModifiedByCylinder = false;
    }];
}

%hook SBFolderView //SBIconController
-(void)scrollViewDidScroll:(SBIconScrollView *)scrollView
{   
    %orig;

    //if its a rotation, then dont
    //cylinder-ize it.
    if(!animator.enabled) return;

    page_swipe(self, scrollView);
}

-(void)scrollViewDidEndDecelerating:(SBIconScrollView *)scrollView
{
    %orig;

    if(animator.enabled) {
        end_scroll(self);
        _randSeedForCurrentPage = arc4random();
    }
}
%end

%group iOS15
%hook SBRootFolderView 
- (void)updateVisibleColumnRangeWithTotalLists:(NSUInteger)arg1 iconVisibilityHandling:(NSInteger)arg2
{
    return %orig(arg1, 0);
}
%end
%end

%group iOS14
%hook SBFolderView 
// For iOS 13, SpringBoard "optimizes" the icon visibility by only showing the bare
// minimum. I have no idea why this works, but it does. An interesting stack trace can
// be found by forcing a crash in -[SBRecycledViewsContainer addSubview:]. Probably best to decompile this function in IDA or something.
-(void)updateVisibleColumnRangeWithTotalLists:(NSUInteger)arg1 columnsPerList:(NSUInteger)arg2 iconVisibilityHandling:(NSInteger)arg3
{
    return %orig(arg1, arg2, 0);
}

%end
%end

static void loadPrefs()
{
    [animator reloadPrefs];
}

%ctor{
    %init;

    animator = [[CylinderAnimator alloc] initWithMsgSend:(ObjcMsgSendType)objc_msgSend];

    if (@available(iOS 15, *)) {
        %init(iOS15);
    }
    else {
        %init(iOS14);
    }

    //listen to notification center (for settings change)
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, (CFNotificationCallback)loadPrefs, (CFStringRef)kCylinderSettingsChanged, NULL, CFNotificationSuspensionBehaviorCoalesce);

    Class SBIconListViewClass = objc_getClass("SBIconListView");
    class_addMethod(SBIconListViewClass, @selector(wasModifiedByCylinder), (IMP)&SBIconListView_wasModifiedByCylinder, "B@:");
    class_addMethod(SBIconListViewClass, @selector(setWasModifiedByCylinder:), (IMP)&SBIconListView_setWasModifiedByCylinder, "v@:B");
}
