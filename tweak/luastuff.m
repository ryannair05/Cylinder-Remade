#import "luastuff.h"
#import "Cylinder-Swift.h"
#import "../Defines.h"
#import <objc/message.h>

static NSMutableArray<NSString *> *_scriptSelectors = nil;
static BOOL _randomize;

BOOL init_lua(NSArray *scripts, BOOL random)
{
    if(scripts.count == 0) return false;

    _randomize = random;

    _scriptSelectors = [NSMutableArray arrayWithCapacity:scripts.count];

    for (NSDictionary *scriptDict in scripts)
    {
        NSString *script = [scriptDict valueForKey:PrefsEffectDirKey];

        [_scriptSelectors addObject:[script stringByAppendingString:@"::"]];
    }

    return true;
}


void manipulate(__unsafe_unretained UIView *view, float offset, u_int32_t rand)
{
    if (_randomize) {
        SEL scriptSelector = NSSelectorFromString(_scriptSelectors[rand % _scriptSelectors.count]);

        ((void(*)(Class, SEL, UIView *, CGFloat)) objc_msgSend) (CylinderAnimator.class, scriptSelector, view, offset);
    }

    else {
        for (NSString *scriptString in _scriptSelectors)
        {
            SEL scriptSelector = NSSelectorFromString(scriptString);

            ((void(*)(Class, SEL, UIView *, CGFloat)) objc_msgSend) (CylinderAnimator.class, scriptSelector, view, offset);
        }
    }
}