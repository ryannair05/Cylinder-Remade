#import "tweak.h"
#import "luastuff.h"
#import "../Defines.h"

static BOOL _enabled;
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
    
    [self enumerateIconViewsUsingBlock:^(SBIconView *v)  {
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

            manipulate((UIView *) view, offset, _randSeedForCurrentPage); //defined in luastuff.m
            view.wasModifiedByCylinder = true;
        }
    }
}

static void end_scroll(__unsafe_unretained SBFolderView *self)
{
    [self enumerateIconListViewsUsingBlock:^(SBIconListView *view)  {
        reset_icon_layout(view);
        view.wasModifiedByCylinder = false;
    }];
}

%hook SBFolderView //SBIconController
-(void)scrollViewDidScroll:(SBIconScrollView *)scrollView
{   
    %orig;

    //if its a rotation, then dont
    //cylinder-ize it.
    if(!_enabled) return;

    page_swipe(self, scrollView);
}

-(void)scrollViewDidEndDecelerating:(SBIconScrollView *)scrollView
{
    %orig;

    if(_enabled) {
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
    NSUserDefaults *settings = [[NSUserDefaults alloc] initWithSuiteName:@"com.ryannair05.cylinderremade"];
    [settings registerDefaults:@{
        PrefsEnabledKey: @YES,
        PrefsRandomizedKey: @NO,
        PrefsEffectKey: DEFAULT_EFFECTS,
    }];

    if (settings && ![settings boolForKey:PrefsEnabledKey])
    {
        _enabled = false;
    }
    else
    {
        BOOL random = [settings boolForKey:PrefsRandomizedKey];
        NSArray *effects = [settings arrayForKey:PrefsEffectKey];
        _enabled = init_lua(effects, random);
    }
}


// the reason for this is create_state() in luastuff.m,
// which loadPrefs() calls, is called when SpringBoard loads.
// Unfortunately calling UIScreen.mainScreen.bounds.size
// causes a bootloop. so instead of setting that 
// global variable there, we set it when we know that
// everything in SpringBoard has already loaded
%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application 
{
    %orig;
	loadPrefs();
}
%end

%ctor{
    %init;

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
