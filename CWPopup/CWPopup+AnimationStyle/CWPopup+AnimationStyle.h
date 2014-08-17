//
//  CWPopup+AnimationStyle.h
//  CWPopupDemo
//
//  Created by allenlee on 2014/8/14.
//  Copyright (c) 2014年 Cezary Wojcik. All rights reserved.
//

#import "UIViewController+CWPopup.h"

typedef NS_ENUM(NSInteger, PopupAnimationStyle) {
	PopupAnimationStyleNone,
	PopupAnimationStyleFade,
	PopupAnimationStyleFromLeft,
    PopupAnimationStyleFromRight,
	PopupAnimationStyleFromTop,
	PopupAnimationStyleFromBottom,
};
#define DefaultPopupPositionPercentageOffset UIOffsetZero


@interface UIViewController (CWPopupWithAnimationStyle)

@property (nonatomic, readwrite) BOOL useFadeViewForPopup;
@property (nonatomic, readwrite) UIViewController *popupPresentingViewController;
@property (nonatomic, readwrite) UIOffset popupPositionPercentageOffset;

- (void)presentPopupViewController:(UIViewController *)viewControllerToPresent withAnimationStyle:(PopupAnimationStyle)style completion:(void (^)(void))completion;
- (void)presentPopupViewController:(UIViewController *)viewControllerToPresent withAnimationStyle:(PopupAnimationStyle)style animationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

- (void)dismissPopupViewControllerWithAnimationStyle:(PopupAnimationStyle)style completion:(void (^)(void))completion;
- (void)dismissPopupViewControllerWithAnimationStyle:(PopupAnimationStyle)style animationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

- (void)dismissSelfPopupWithAnimationStyle:(PopupAnimationStyle)style completion:(void (^)(void))completion;
- (void)dismissSelfPopupWithAnimationStyle:(PopupAnimationStyle)style animationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

- (PopupAnimationStyle)getDismissStyleByPresentStyle:(PopupAnimationStyle)presentStyle;

@end
