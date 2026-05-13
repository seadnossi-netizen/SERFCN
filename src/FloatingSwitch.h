#import <UIKit/UIKit.h>

@interface FloatingSwitch : UIWindow
+ (instancetype)shared;
- (void)show;
- (void)hide;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy)   void (^onToggle)(BOOL isOn);

// Menu hosting — menu is presented as a subview of this full-screen window.
// hitTest passes through touches to underlying app windows when menu is hidden.
- (void)presentMenuViewController:(UIViewController *)vc animated:(BOOL)animated;
- (void)dismissPresentedMenuViewControllerAnimated:(BOOL)animated
                                        completion:(dispatch_block_t)completion;
@end
