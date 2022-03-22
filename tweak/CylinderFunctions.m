#import <UIKit/UIView.h>
#import <objc/message.h>

CGFloat getMaxColumns(__unsafe_unretained UIView* view) {
    return ((NSUInteger(*)(UIView *, SEL)) objc_msgSend) (view, @selector(iconColumnsForCurrentOrientation));
}

CGFloat getMaxRows(__unsafe_unretained UIView* view) {
    return  ((NSUInteger(*)(UIView *, SEL)) objc_msgSend) (view, @selector(iconRowsForCurrentOrientation));
}

CGFloat getMaxIcons(__unsafe_unretained UIView* view) {
    return  ((NSUInteger(*)(UIView *, SEL)) objc_msgSend) (view, @selector(maximumIconCount));
}