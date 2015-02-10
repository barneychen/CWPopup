//
//  CWPopup.m
//  CWPopupDemo
//
//  Created by allenlee on 2014/8/14.
//  Copyright (c) 2014年 Cezary Wojcik. All rights reserved.
//

#import "CWPopup.h"
#import <objc/runtime.h>

//#define ANIMATION_TIME 0.5f
#define ANIMATION_TIME_PRESENT 0.36f
#define ANIMATION_TIME_DISMISS 0.28f
#define STATUS_BAR_SIZE 22

NSString const *CWPopupKey;
NSString const *CWBlurViewKey;
NSString const *CWUseBlurForPopup;

NSString const *CWPopupFadeViewColorKEY = @"CWPopupFadeViewColorKEY";
NSString const *CWPopupPresentingKey = @"CWPopupPresentingKey";
NSString const *CWPopupPositionPercentageOffsetKey = @"CWPopupPositionPercentageOffsetKey";


@interface UIViewController (CWPopupWithAnimationStyle_Private)

- (UIImage *)getScreenImage;
- (UIImage *)getBlurredImage:(UIImage *)imageToBlur;
- (void)addBlurView;
- (CGRect)getPopupFrameForViewController:(UIViewController *)viewController;
- (CGRect)getEZPopupFrameForViewController:(UIViewController *)viewController;
- (void)screenOrientationChanged;

- (UIView *)getPresentSuperView;
- (BOOL)shouldDelay;

@end

@implementation UIViewController (CWPopupWithAnimationStyle)
@dynamic popupFadeViewColor;
@dynamic popupPresentingViewController;
@dynamic popupPositionPercentageOffset;

+(void)load {
	[super load];
	
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		SEL originalSelector = @selector(getPopupFrameForViewController:);
		SEL swizzledSelector = @selector(getEZPopupFrameForViewController:);
		[self swizzleMethod:originalSelector withMethod:swizzledSelector];
	});
}

//http://nshipster.com/method-swizzling/
+ (void)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
	Class class = [self class];
	
	// When swizzling a class method, use the following:
	// Class class = object_getClass((id)self);
	
	Method originalMethod = class_getInstanceMethod(class, originalSelector);
	Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
	
	BOOL didAddMethod =
	class_addMethod(class,
					originalSelector,
					method_getImplementation(swizzledMethod),
					method_getTypeEncoding(swizzledMethod));
	
	if (didAddMethod) {
		class_replaceMethod(class,
							swizzledSelector,
							method_getImplementation(originalMethod),
							method_getTypeEncoding(originalMethod));
	} else {
		method_exchangeImplementations(originalMethod, swizzledMethod);
	}
}

- (CGRect)getEZPopupFrameForViewController:(UIViewController *)viewController {
	
	CGRect frame = viewController.view.frame;
	CGFloat x;
	CGFloat y;
    
    CGRect screenFrame = [self getScreenFrame];
    x = (screenFrame.size.width - frame.size.width)/2;
    y = (screenFrame.size.height - frame.size.height)/2;
    
	frame = CGRectMake(x, y, frame.size.width, frame.size.height);
	frame = CGRectIntegral(frame);
	
	if (!UIOffsetEqualToOffset(self.popupPositionPercentageOffset, DefaultPopupPositionPercentageOffset)) {
		CGFloat dx = x * self.popupPositionPercentageOffset.horizontal;
		CGFloat dy = y * self.popupPositionPercentageOffset.vertical;
		frame.origin.x = dx;
		frame.origin.y = dy;
	}
	frame.origin.x += self.popupViewOffset.x;
	frame.origin.y += self.popupViewOffset.y;
	
    return frame;
}

- (void)presentPopupViewController:(UIViewController *)viewControllerToPresent withAnimationStyle:(PopupAnimationStyle)style completion:(void (^)(void))completion {
	NSTimeInterval duration = ANIMATION_TIME_PRESENT;
	[self presentPopupViewController:viewControllerToPresent withAnimationStyle:style animationDuration:duration completion:completion];
}

- (UIView *)getPresentSuperView {
    UIView * __block superView;
	
	[self.view.window.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
		if ( CGSizeEqualToSize(subview.frame.size, self.view.window.frame.size)
			|| (subview.frame.size.width == self.view.window.frame.size.height && subview.frame.size.height == self.view.window.frame.size.width) ) {
			superView = subview;
		}
	}];
	
    return superView;
}

- (BOOL)shouldDelay {
    UIView *superView = [self.view.window.subviews lastObject];
    
    Class class = NSClassFromString(@"SVProgressHUD");
    if (class) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        UIView *sharedView = [class performSelector:@selector(sharedView)];
        UIView *overlayView = [sharedView performSelector:@selector(overlayView)];
#pragma clang diagnostic pop
        
        if ([superView isEqual:overlayView]) {
            return YES;
        }
    }
    return NO;
}

- (void)presentPopupViewController:(UIViewController *)viewControllerToPresent withAnimationStyle:(PopupAnimationStyle)style animationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion {
	if (self.popupViewController == nil) {
        UIView *superView = [self getPresentSuperView];
        if ([self shouldDelay]) {
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                [self presentPopupViewController:viewControllerToPresent withAnimationStyle:style animationDuration:duration completion:completion];
            });
            return;
        }
        
        // initial setup
        self.popupViewController = viewControllerToPresent;
        self.popupViewController.view.autoresizesSubviews = NO;
        self.popupViewController.view.autoresizingMask = UIViewAutoresizingNone;
		self.popupViewController.popupPresentingViewController = self;
        CGRect finalFrame = [self getPopupFrameForViewController:viewControllerToPresent];
        // parallax setup if iOS7+
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            UIInterpolatingMotionEffect *interpolationHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
            interpolationHorizontal.minimumRelativeValue = @-10.0;
            interpolationHorizontal.maximumRelativeValue = @10.0;
            UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
            interpolationHorizontal.minimumRelativeValue = @-10.0;
            interpolationHorizontal.maximumRelativeValue = @10.0;
            [self.popupViewController.view addMotionEffect:interpolationHorizontal];
            [self.popupViewController.view addMotionEffect:interpolationVertical];
        }
#endif
        // shadow setup
        viewControllerToPresent.view.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        viewControllerToPresent.view.layer.shadowColor = [UIColor blackColor].CGColor;
        viewControllerToPresent.view.layer.shadowRadius = 3.0f;
        viewControllerToPresent.view.layer.shadowOpacity = 0.8f;
        viewControllerToPresent.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:viewControllerToPresent.view.layer.bounds].CGPath;
        // rounded corners
        viewControllerToPresent.view.layer.cornerRadius = 5.0f;
        // blurview
        if (self.useBlurForPopup) {
            UIImageView *blurView = [UIImageView new];
            blurView.frame = superView.bounds;
            blurView.alpha = 0.0f;
            blurView.image = [self getBlurredImage:[self getScreenImage]];
            [self.view addSubview:blurView];
            [self.view bringSubviewToFront:self.popupViewController.view];
            objc_setAssociatedObject(self, &CWBlurViewKey, blurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else {
            UIView *fadeView = [UIView new];
            fadeView.frame = superView.bounds;
            fadeView.backgroundColor = (self.popupFadeViewColor)? self.popupFadeViewColor : [UIColor blackColor];
            fadeView.userInteractionEnabled = YES;
            fadeView.alpha = 0.0f;
            [self.view addSubview:fadeView];
            objc_setAssociatedObject(self, &CWBlurViewKey, fadeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        UIView *blurView = objc_getAssociatedObject(self, &CWBlurViewKey);
        // setup
        if (style != PopupAnimationStyleNone) { // animate
            CGRect initialFrame;
			if (style == PopupAnimationStyleFromBottom) {
				initialFrame = CGRectMake(finalFrame.origin.x, [UIScreen mainScreen].bounds.size.height + viewControllerToPresent.view.frame.size.height/2, finalFrame.size.width, finalFrame.size.height);
				
			}else if (style == PopupAnimationStyleFromTop) {
				initialFrame = CGRectMake(finalFrame.origin.x, 0 - viewControllerToPresent.view.frame.size.height, finalFrame.size.width, finalFrame.size.height);
				
			}else if (style == PopupAnimationStyleFromLeft) {
				initialFrame = CGRectMake(0 - [UIScreen mainScreen].bounds.size.width, finalFrame.origin.y , finalFrame.size.width, finalFrame.size.height);
				
			}else if (style == PopupAnimationStyleFromRight) {
				initialFrame = CGRectMake(viewControllerToPresent.view.frame.size.width + [UIScreen mainScreen].bounds.size.width, finalFrame.origin.y , finalFrame.size.width, finalFrame.size.height);
			}else if (style == PopupAnimationStyleFade) {
				initialFrame = finalFrame;
			}
			
            [self viewWillDisappear:YES];
            viewControllerToPresent.view.frame = initialFrame;
            [superView addSubview:viewControllerToPresent.view];
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                viewControllerToPresent.view.frame = finalFrame;
                blurView.alpha = self.useBlurForPopup ? 1.0f : 0.4f;
            } completion:^(BOOL finished) {
                [completion invoke];
                [self viewDidDisappear:YES];
            }];
        } else { // don't animate
            [self viewWillDisappear:NO];
            viewControllerToPresent.view.frame = finalFrame;
            [superView addSubview:viewControllerToPresent.view];
            blurView.alpha = self.useBlurForPopup ? 1.0f : 0.4f;
            [completion invoke];
            [self viewDidDisappear:NO];
        }
        // if screen orientation changed
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenOrientationChanged) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
}

- (void)dismissPopupViewControllerWithAnimationStyle:(PopupAnimationStyle)style completion:(void (^)(void))completion {
	NSTimeInterval duration = ANIMATION_TIME_DISMISS;
	[self dismissPopupViewControllerWithAnimationStyle:style animationDuration:duration completion:completion];
}

- (void)dismissPopupViewControllerWithAnimationStyle:(PopupAnimationStyle)style animationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion {
	
	UIView *blurView = objc_getAssociatedObject(self, &CWBlurViewKey);
	if (style != PopupAnimationStyleNone) { // animate
		CGRect initialFrame = self.popupViewController.view.frame;
		
		CGRect finalFrame;
		
		if (style == PopupAnimationStyleFromBottom) {
			finalFrame = CGRectMake(initialFrame.origin.x, 0 - initialFrame.size.height/2, initialFrame.size.width, initialFrame.size.height);
			
		}else if (style == PopupAnimationStyleFromTop) {
			finalFrame = CGRectMake(initialFrame.origin.x, [UIScreen mainScreen].bounds.size.height + initialFrame.size.height/2, initialFrame.size.width, initialFrame.size.height);
			
		}else if (style == PopupAnimationStyleFromLeft) {
			finalFrame = CGRectMake(initialFrame.origin.x + self.view.frame.size.width + self.view.frame.size.width, initialFrame.origin.y, initialFrame.size.width, initialFrame.size.height);
			
		}else if (style == PopupAnimationStyleFromRight) {
			finalFrame = CGRectMake(initialFrame.origin.x - self.view.frame.size.width, initialFrame.origin.y, initialFrame.size.width, initialFrame.size.height);
		}else if (style == PopupAnimationStyleFade) {
			finalFrame = initialFrame;
		}
        
		
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.popupViewController.view.frame = finalFrame;
            // uncomment the line below to have slight rotation during the dismissal
            // self.popupViewController.view.transform = CGAffineTransformMakeRotation(M_PI/6);
            blurView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            
            [self viewWillAppear:YES];
            [self.popupViewController.view removeFromSuperview];
            [blurView removeFromSuperview];
			self.popupViewController.popupPresentingViewController = nil;
            self.popupViewController = nil;
            [completion invoke];
            [self viewDidAppear:YES];
        }];
		
		NSTimeInterval delay2 = 0.5 *(0.9*duration);
		NSTimeInterval duration2 = ((0.9*duration) -delay2);
		[UIView animateWithDuration:duration2 delay:delay2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.popupViewController.view.alpha = 0.1;
        } completion:^(BOOL finished) {

        }];
		
    } else { // don't animate
        [self viewWillAppear:NO];
        [self.popupViewController.view removeFromSuperview];
        [blurView removeFromSuperview];
		self.popupViewController.popupPresentingViewController = nil;
        self.popupViewController = nil;
        blurView = nil;
        [completion invoke];
        [self viewDidAppear:NO];
    }
    // remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)dismissSelfPopupWithAnimationStyle:(PopupAnimationStyle)style completion:(void (^)(void))completion {
	[self dismissSelfPopupWithAnimationStyle:style animationDuration:ANIMATION_TIME_DISMISS completion:completion];
}

- (void)dismissSelfPopupWithAnimationStyle:(PopupAnimationStyle)style animationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion {
	//find presenting view controller (parent)
	[self.popupPresentingViewController dismissPopupViewControllerWithAnimationStyle:style animationDuration:duration completion:completion];
}

- (PopupAnimationStyle)getDismissStyleByPresentStyle:(PopupAnimationStyle)presentStyle {
	
	PopupAnimationStyle dismissStyle;
	switch (presentStyle) {
		case PopupAnimationStyleFromBottom:
			dismissStyle = PopupAnimationStyleFromTop;	break;
		case PopupAnimationStyleFromTop:
			dismissStyle = PopupAnimationStyleFromBottom;	break;
		case PopupAnimationStyleFromLeft:
			dismissStyle = PopupAnimationStyleFromRight;	break;
		case PopupAnimationStyleFromRight:
			dismissStyle = PopupAnimationStyleFromLeft;	break;
		default:
			dismissStyle = presentStyle;	break;
	}
	return dismissStyle;
}

#pragma mark - getter & setter
- (void)setPopupFadeViewColor:(UIColor *)popupFadeViewColor {
    objc_setAssociatedObject(self, &CWPopupFadeViewColorKEY, popupFadeViewColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)popupFadeViewColor  {
    return objc_getAssociatedObject(self, &CWPopupFadeViewColorKEY);
}

- (void)setPopupPresentingViewController:(UIViewController *)popupPresentingViewController {
    objc_setAssociatedObject(self, &CWPopupPresentingKey, popupPresentingViewController, OBJC_ASSOCIATION_ASSIGN); //OBJC_ASSOCIATION_RETAIN_NONATOMIC
}

- (UIViewController *)popupPresentingViewController {
    return objc_getAssociatedObject(self, &CWPopupPresentingKey);
}

- (void)setPopupPositionPercentageOffset:(UIOffset)presentPositionOffet {
	id object = self;
	id value = [NSValue valueWithUIOffset:presentPositionOffet];
    objc_setAssociatedObject(object, &CWPopupPositionPercentageOffsetKey, value, OBJC_ASSOCIATION_COPY);
}

- (UIOffset)popupPositionPercentageOffset {
	id object = self;
	id value = objc_getAssociatedObject(object, &CWPopupPositionPercentageOffsetKey);
	
    return [value UIOffsetValue];
}

@end
