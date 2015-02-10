//
//  MainViewController.m
//  CWPopupDemo
//
//  Created by Cezary Wojcik on 8/21/13.
//  Copyright (c) 2013 Cezary Wojcik. All rights reserved.
//

#import "MainViewController.h"
#import "SamplePopupViewController.h"
//#import "UIViewController+CWPopup.h"
#import "CWPopup.h"

@interface MainViewController ()
- (IBAction)btnPresentPopup:(UIButton *)sender;

@property (nonatomic) PopupAnimationStyle currentStyle;

- (IBAction)btnPresentPopupFromBottom:(UIButton *)sender;
- (IBAction)btnPresentPopupFromTop:(UIButton *)sender;
- (IBAction)btnPresentPopupFromLeft:(UIButton *)sender;
- (IBAction)btnPresentPopupFromRight:(UIButton *)sender;
- (void)presentPopupWithCurrentPopupAnimationStyle;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPopup)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapRecognizer];
    self.useBlurForPopup = YES;
//	self.popupFadeViewColor = [UIColor clearColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Popup Functions

- (IBAction)btnPresentPopup:(UIButton *)sender {

	self.currentStyle = PopupAnimationStyleFromBottom;
	self.popupPositionPercentageOffset = UIOffsetMake(1, 1);

    SamplePopupViewController *samplePopupViewController = [[SamplePopupViewController alloc] initWithNibName:@"SamplePopupViewController" bundle:nil];
    [self presentPopupViewController:samplePopupViewController animated:YES completion:^(void) {
        NSLog(@"popup view presented");
    }];
}

- (IBAction)btnPresentPopupFromBottom:(UIButton *)sender {
	
	self.currentStyle = PopupAnimationStyleFromBottom;
	self.popupPositionPercentageOffset = UIOffsetMake(1, 0.52);

	[self presentPopupWithCurrentPopupAnimationStyle];
}

- (IBAction)btnPresentPopupFromTop:(UIButton *)sender {
	
	self.currentStyle = PopupAnimationStyleFromTop;
	self.popupPositionPercentageOffset = UIOffsetMake(1, 1.52);

	[self presentPopupWithCurrentPopupAnimationStyle];
}

- (IBAction)btnPresentPopupFromLeft:(UIButton *)sender {
	
	self.currentStyle = PopupAnimationStyleFromLeft;
	self.popupPositionPercentageOffset = UIOffsetMake(1.6, 1);
	
	[self presentPopupWithCurrentPopupAnimationStyle];
}
- (IBAction)btnPresentPopupFromRight:(UIButton *)sender {
	
	self.currentStyle = PopupAnimationStyleFromRight;
	self.popupPositionPercentageOffset = UIOffsetMake(0.2, 1);
	
	[self presentPopupWithCurrentPopupAnimationStyle];
}

- (void)presentPopupWithCurrentPopupAnimationStyle {
	
    SamplePopupViewController *samplePopupViewController = [[SamplePopupViewController alloc] initWithNibName:@"SamplePopupViewController" bundle:nil];
    [self presentPopupViewController:samplePopupViewController withAnimationStyle:self.currentStyle completion:^(void) {
        NSLog(@"popup view presented");
    }];
}

- (void)dismissPopup {
    if (self.popupViewController != nil) {
		if (self.currentStyle == PopupAnimationStyleNone) {
			[self dismissPopupViewControllerAnimated:NO completion:^{
				NSLog(@"popup view dismissed");
			}];
		}else {
			PopupAnimationStyle dismissStyle = [self getDismissStyleByPresentStyle:self.currentStyle];
			[self dismissPopupViewControllerWithAnimationStyle:dismissStyle completion:^{
				NSLog(@"popup view dismissed");
			}];
		}

    }
}

#pragma mark - gesture recognizer delegate functions

// so that tapping popup view doesnt dismiss it
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return touch.view == self.view;
}

@end
