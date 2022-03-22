
#import "CALayer+Cylinder.h"
#import "luastuff.h"

@interface SBIcon : NSObject
@property (nonatomic,copy,readonly) NSString * displayName; 
@end 


@interface SBIconImageView : UIView
@end 

@interface SBIconImageCrossfadeView : UIView
@end 

@interface SBIconView : UIView {
    SBIconImageView* _iconImageView;
    SBIconImageCrossfadeView* _crossfadeView;
}

@property (nonatomic,retain) SBIcon *icon;
@end 

NS_CLASS_AVAILABLE_IOS(4_0) @interface SBIconListView : UIView
@property(readonly, nonatomic) NSUInteger maximumIconCount;
@property(readonly, nonatomic) NSUInteger maxIcons API_DEPRECATED_WITH_REPLACEMENT("maximumIconCount", ios(4.0, 13.0));
@property(readonly, nonatomic) NSUInteger iconColumnsForCurrentOrientation;
@property(readonly, nonatomic) NSUInteger iconRowsForCurrentOrientation;

-(NSArray *)icons;
-(void)layoutIconsNow;
- (void)setIconsNeedLayout;

- (void)setAlphaForAllIcons:(CGFloat)alpha;
- (void)enumerateIconViewsUsingBlock:(void(^)())block;

@end

@interface SBIconScrollView : UIScrollView
@end 

@interface SBFolder : NSObject
@property (nonatomic, assign, readonly) NSUInteger listCount;
@end

@interface SBRootFolder : SBFolder
@end

@interface SBIconController : UIViewController
+ (id)sharedInstance;
@property (nonatomic, assign, readonly) SBRootFolder *rootFolder;
@end

@interface SBFolderView : UIView 
@property (assign,getter=isRotating,nonatomic) BOOL rotating;
@property (nonatomic,copy,readonly) NSArray * iconListViews API_AVAILABLE(ios(7.0));

- (void)enumerateIconListViewsUsingBlock:(void(^)())block;
@end 
