//
//  UITabBar+Swizzling.m
//  FPRuntimeTabBar
//
//  Created by polycom on 2017/6/19.
//  Copyright © 2017年 com.polycom. All rights reserved.
//

#import "UITabBar+Swizzling.h"
#import <objc/runtime.h>
#import "AppDelegate.h"

@interface UITabBar ()

@property (nonatomic, strong) NSMutableDictionary *badgeValues;

@end

@implementation UITabBar (Swizzling)

static void ExchageMethod(SEL originalSelector, SEL swizzledSelector, Class class) {
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if(didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        ExchageMethod(@selector(layoutSubviews), @selector(s_layoutSubviews), class);
        ExchageMethod(@selector(hitTest:withEvent:), @selector(s_hitTest:withEvent:), class);
        ExchageMethod(@selector(touchesBegan:withEvent:), @selector(s_touchesBegan:withEvent:), class);
    });
}

- (NSMutableDictionary *)badgeValues {
    return objc_getAssociatedObject(self, @selector(badgeValues));
}

- (void)setBadgeValues:(NSMutableDictionary *)badgeValues {
    objc_setAssociatedObject(self, @selector(badgeValues), badgeValues, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)s_layoutSubviews {
    [self s_layoutSubviews];
    
    NSInteger index = 0;
    CGFloat space = 12, tabBarButtonLabelHeight = 16;
    
    for(UIView *childView in self.subviews) {
        if(![childView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            continue;
        }
        self.selectionIndicatorImage = [[UIImage alloc] init];
        [self bringSubviewToFront:childView];
        
        UIView *tabBarImageView, *tabBarButtonLabel, *tabBarBadgeView;
        for(UIView *sTabBarItem in childView.subviews) {
            if([sTabBarItem isKindOfClass:NSClassFromString(@"UITabBarSwappableImageView")]) {
                tabBarImageView = sTabBarItem;
            } else if([sTabBarItem isKindOfClass:NSClassFromString(@"UITabBarButtonLabel")]) {
                tabBarButtonLabel = sTabBarItem;
            } else if([sTabBarItem isKindOfClass:NSClassFromString(@"_UIBadgeView")]) {
                tabBarBadgeView = sTabBarItem;
            }
        }
        NSString *tabBarButtonLabelText = ((UILabel *)tabBarButtonLabel).text;
        
        CGFloat y = CGRectGetHeight(self.bounds) - (CGRectGetHeight(tabBarButtonLabel.bounds) + CGRectGetHeight(tabBarImageView.bounds));
        
        if(y < 0) {
            if(!tabBarButtonLabelText.length) {
                space -= tabBarButtonLabelHeight;
            } else {
                space = 12;
            }
            
            childView.frame = CGRectMake(childView.frame.origin.x, y - space, childView.frame.size.width,  childView.frame.size.height - y + space);
        } else {
            space = MIN(space, y);
        }
        
        CGFloat badgeW_H = 8;
        CGFloat bandgeX = CGRectGetMaxX(childView.frame) - (CGRectGetWidth(childView.frame) - CGRectGetWidth(tabBarImageView.frame) - badgeW_H) / 2.0;
        CGFloat bandgeY = y < 0 ? CGRectGetMinY(childView.frame) + 10 : CGRectGetMinY(childView.frame) + 8;
        
        if(!self.badgeValues) {
            self.badgeValues = [NSMutableDictionary dictionary];
        }
        
        NSString *key = @(index).stringValue;
        UILabel *currentBadgeValue = self.badgeValues[key];
        
        if(tabBarBadgeView && y < 0 && CGRectGetWidth(self.frame) > 0 && CGRectGetHeight(self.frame) > 0) {
            tabBarBadgeView.hidden = YES;
            
            if(!currentBadgeValue) {
                currentBadgeValue = [self cloneBadgeViewWithOldBadge:tabBarBadgeView];
                self.badgeValues[key] = currentBadgeValue;
            }
            
            CGSize size = [currentBadgeValue.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 18)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:@{NSFontAttributeName:currentBadgeValue.font} context:nil].size;
            currentBadgeValue.frame = CGRectMake(bandgeX - (ceilf(size.width) + 10) / 2, bandgeY, ceilf(size.width) + 10, CGRectGetHeight(currentBadgeValue.frame));
            [self addSubview:currentBadgeValue];
        } else {
            if(currentBadgeValue) {
                [currentBadgeValue removeFromSuperview];
                [self.badgeValues removeObjectForKey:key];
            }
        }
        
        index++;
    }
}

- (UILabel *)cloneBadgeViewWithOldBadge:(UIView *)badgeView {
    if(!badgeView) {
        return nil;
    }
    
    UILabel *oldLabel;
    
    for(UIView *sView in badgeView.subviews) {
        if([sView isKindOfClass:[UILabel class]]) {
            oldLabel = (UILabel *)sView;
            break;
        }
    }
    
    UILabel *newLabel = [[UILabel alloc] init];
    newLabel.text = oldLabel.text;
    newLabel.font = oldLabel.font;
    CGSize size = [newLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 18)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:oldLabel.font}
                                              context:nil].size;
    newLabel.frame = CGRectMake(0, 0, ceilf(size.width) + 10, size.height);
    newLabel.textColor = [UIColor whiteColor];
    newLabel.textAlignment = NSTextAlignmentCenter;
    newLabel.backgroundColor = [UIColor redColor];
    newLabel.layer.masksToBounds = YES;
    newLabel.layer.cornerRadius = CGRectGetHeight(newLabel.frame) / 2;
    
    return newLabel;
}

- (UIView *)s_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if(!self.clipsToBounds && !self.hidden && self.alpha > 0) {
        UIView *result = [super hitTest:point withEvent:event];
        if(result) {
            return result;
        } else {
            for(UIView *subView in self.subviews.reverseObjectEnumerator) {
                CGPoint subPoint = [subView convertPoint:point fromView:self];
                result = [subView hitTest:subPoint withEvent:event];
                
                if(result) {
                    return result;
                }
            }
        }
    }
    
    return nil;
}

- (void)s_touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self s_touchesBegan:touches withEvent:event];
    
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [allTouches anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    
    NSInteger tabCount = 0;
    for(UIView *childView in self.subviews) {
        if(![childView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            continue;
        }
        
        tabCount++;
    }
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width / tabCount;
    NSUInteger clickIndex = ceil(point.x) / ceilf(width);
    
    UITabBarController *controller = (UITabBarController *)[(AppDelegate *)[[UIApplication sharedApplication] delegate] window].rootViewController;
    [controller setSelectedIndex:clickIndex];
}


@end
