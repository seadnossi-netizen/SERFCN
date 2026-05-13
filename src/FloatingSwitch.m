#import "FloatingSwitch.h"

@interface FloatingSwitch ()
@property (nonatomic, strong) UIView  *containerView;
@property (nonatomic, strong) UIView  *trackView;
@property (nonatomic, strong) UIView  *thumbView;
@property (nonatomic, strong) UILabel *offLabel;
@property (nonatomic, strong) UILabel *onLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint  originalCenter;
// Menu state
@property (nonatomic, assign) BOOL              menuVisible;
@property (nonatomic, weak)   UIView           *presentedMenuView;
@property (nonatomic, weak)   UIViewController *presentedMenuVC;
@end

@implementation FloatingSwitch

static FloatingSwitch *_sharedInstance = nil;

+ (instancetype)shared { return _sharedInstance; }

- (instancetype)initFloating {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] &&
                s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
        self = scene
            ? [super initWithWindowScene:scene]
            : [super initWithFrame:[UIScreen mainScreen].bounds];
    } else {
        self = [super initWithFrame:[UIScreen mainScreen].bounds];
    }

    if (self) {
        self.frame           = [UIScreen mainScreen].bounds;
        self.windowLevel     = UIWindowLevelAlert + 200;
        self.backgroundColor = [UIColor clearColor];
        self.hidden          = YES;
        _menuVisible         = NO;

        // A transparent root VC so child VCs (MenuViewController) can
        // present UIAlertControllers and other VCs properly.
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        self.rootViewController = rootVC;

        [self setupUI];
        [self setupGestures];
        [self setupPosition];
    }
    _sharedInstance = self;
    return self;
}

// ── UI ────────────────────────────────────────────────────────────────────────

- (void)setupUI {
    UIView *root = self.rootViewController.view;

    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 36)];
    _containerView.backgroundColor       = [UIColor colorWithWhite:0.08 alpha:0.95];
    _containerView.layer.cornerRadius    = 18;
    _containerView.layer.borderWidth     = 0.5;
    _containerView.layer.borderColor     = [UIColor colorWithWhite:0.25 alpha:1].CGColor;
    _containerView.clipsToBounds         = YES;
    _containerView.userInteractionEnabled = YES;
    [root addSubview:_containerView];

    _trackView = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 84, 30)];
    _trackView.backgroundColor    = [UIColor colorWithWhite:0.15 alpha:1];
    _trackView.layer.cornerRadius = 15;
    [_containerView addSubview:_trackView];

    _offLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, 5, 32, 20)];
    _offLabel.text          = @"OFF";
    _offLabel.font          = [UIFont boldSystemFontOfSize:12];
    _offLabel.textColor     = [UIColor colorWithWhite:0.5 alpha:1];
    _offLabel.textAlignment = NSTextAlignmentCenter;
    [_trackView addSubview:_offLabel];

    _onLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 32, 20)];
    _onLabel.text          = @"ON";
    _onLabel.font          = [UIFont boldSystemFontOfSize:12];
    _onLabel.textColor     = [UIColor colorWithWhite:0.2 alpha:1];
    _onLabel.textAlignment = NSTextAlignmentCenter;
    [_trackView addSubview:_onLabel];

    _thumbView = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 30, 30)];
    _thumbView.backgroundColor    = [UIColor colorWithWhite:0.25 alpha:1];
    _thumbView.layer.cornerRadius = 15;
    _thumbView.layer.shadowColor  = [UIColor blackColor].CGColor;
    _thumbView.layer.shadowOffset = CGSizeMake(0, 1);
    _thumbView.layer.shadowRadius = 2;
    _thumbView.layer.shadowOpacity = 0.5;
    [_trackView addSubview:_thumbView];

    _isOn = NO;
}

- (void)setupGestures {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleTap:)];
    [_containerView addGestureRecognizer:tap];

    _panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePan:)];
    [_containerView addGestureRecognizer:_panGesture];
}

- (void)setupPosition {
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    _containerView.frame = CGRectMake(screenW - 100, screenH * 0.45, 90, 36);
}

// ── hitTest ───────────────────────────────────────────────────────────────────

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!_menuVisible) {
        if (CGRectContainsPoint(_containerView.frame, point)) {
            return [super hitTest:point withEvent:event];
        }
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

// ── Gestures ──────────────────────────────────────────────────────────────────

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    [self setOn:!_isOn animated:YES];
    if (self.onToggle) self.onToggle(_isOn);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _originalCenter = _containerView.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [gesture translationInView:self];
        _containerView.center = CGPointMake(_originalCenter.x + t.x,
                                            _originalCenter.y + t.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat fx = _containerView.frame.origin.x;
        CGFloat fy = _containerView.frame.origin.y;
        CGFloat snapX = (fx + 45 < screenW / 2.0) ? 10 : screenW - 100;
        [UIView animateWithDuration:0.2 animations:^{
            self->_containerView.frame = CGRectMake(snapX, fy, 90, 36);
        }];
        [[NSUserDefaults standardUserDefaults] setFloat:snapX forKey:@"FloatingSwitchX"];
        [[NSUserDefaults standardUserDefaults] setFloat:fy    forKey:@"FloatingSwitchY"];
    }
}

// ── Toggle visual ─────────────────────────────────────────────────────────────

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    CGFloat targetX   = on ? 51 : 3;
    UIColor *thumb    = on ? [UIColor colorWithRed:1.0 green:0.353 blue:0.122 alpha:1]
                           : [UIColor colorWithWhite:0.25 alpha:1];
    UIColor *onColor  = on ? [UIColor whiteColor]                : [UIColor colorWithWhite:0.2 alpha:1];
    UIColor *offColor = on ? [UIColor colorWithWhite:0.3 alpha:1] : [UIColor colorWithWhite:0.5 alpha:1];

    void (^update)(void) = ^{
        self->_thumbView.frame           = CGRectMake(targetX, 3, 30, 30);
        self->_thumbView.backgroundColor = thumb;
        self->_onLabel.textColor         = onColor;
        self->_offLabel.textColor        = offColor;
    };
    if (animated) {
        [UIView animateWithDuration:0.25 delay:0
             usingSpringWithDamping:0.7 initialSpringVelocity:0.5
                            options:0 animations:update completion:nil];
    } else {
        update();
    }
}

// ── Show / Hide window ────────────────────────────────────────────────────────

- (void)show {
    float savedX = [[NSUserDefaults standardUserDefaults] floatForKey:@"FloatingSwitchX"];
    float savedY = [[NSUserDefaults standardUserDefaults] floatForKey:@"FloatingSwitchY"];
    if (savedX != 0 || savedY != 0) {
        _containerView.frame = CGRectMake(savedX, savedY, 90, 36);
    } else {
        [self setupPosition];
    }
    [self.rootViewController.view bringSubviewToFront:_containerView];
    self.hidden = NO;
    self.alpha  = 0;
    [UIView animateWithDuration:0.3 animations:^{ self.alpha = 1; }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0; }
                     completion:^(BOOL f){ self.hidden = YES; }];
}

// ── Menu hosting — proper child VC containment ────────────────────────────────

- (void)presentMenuViewController:(UIViewController *)vc animated:(BOOL)animated {
    if (_presentedMenuView) return;

    _menuVisible    = YES;
    _presentedMenuVC = vc;

    UIViewController *rootVC = self.rootViewController;
    [rootVC addChildViewController:vc];

    UIView *menuView = vc.view;
    menuView.frame = rootVC.view.bounds;
    menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [rootVC.view insertSubview:menuView belowSubview:_containerView];
    _presentedMenuView = menuView;

    [vc didMoveToParentViewController:rootVC];
    [vc viewWillAppear:animated];

    if (animated) {
        menuView.alpha = 0;
        [UIView animateWithDuration:0.18 animations:^{
            menuView.alpha = 1;
        } completion:^(BOOL f) {
            [vc viewDidAppear:animated];
        }];
    } else {
        [vc viewDidAppear:NO];
    }
}

- (void)dismissPresentedMenuViewControllerAnimated:(BOOL)animated
                                        completion:(dispatch_block_t)completion {
    UIViewController *menuVC  = _presentedMenuVC;
    UIView           *menuView = _presentedMenuView;
    if (!menuView) {
        if (completion) completion();
        return;
    }
    _menuVisible       = NO;
    _presentedMenuView = nil;
    _presentedMenuVC   = nil;

    [menuVC willMoveToParentViewController:nil];

    void (^teardown)(void) = ^{
        [menuView removeFromSuperview];
        [menuVC removeFromParentViewController];
        if (completion) completion();
    };

    if (animated) {
        [UIView animateWithDuration:0.18 animations:^{
            menuView.alpha = 0;
        } completion:^(BOOL f){ teardown(); }];
    } else {
        teardown();
    }
}

@end
