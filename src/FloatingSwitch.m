#import "FloatingSwitch.h"

@interface FloatingSwitch ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, strong) UILabel *offLabel;
@property (nonatomic, strong) UILabel *onLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint originalCenter;
@end

@implementation FloatingSwitch

static FloatingSwitch *_sharedInstance = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[FloatingSwitch alloc] initFloating];
    });
    return _sharedInstance;
}

- (instancetype)initFloating {
    // iOS 13+ requires a UIWindowScene for UIWindow subclasses
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] &&
                s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
        if (scene) {
            self = [super initWithWindowScene:scene];
        } else {
            self = [super initWithFrame:[UIScreen mainScreen].bounds];
        }
    } else {
        self = [super initWithFrame:[UIScreen mainScreen].bounds];
    }

    if (self) {
        self.frame = CGRectMake(0, 0, 90, 36);
        self.windowLevel = UIWindowLevelAlert + 200;
        self.backgroundColor = [UIColor clearColor];
        self.hidden = YES;
        [self setupUI];
        [self setupGestures];
        [self setupPosition];
    }
    return self;
}

- (void)setupUI {
    _containerView = [[UIView alloc] initWithFrame:self.bounds];
    _containerView.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.95];
    _containerView.layer.cornerRadius = 18;
    _containerView.layer.borderWidth = 0.5;
    _containerView.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1].CGColor;
    _containerView.clipsToBounds = YES;
    [self addSubview:_containerView];

    _trackView = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 84, 30)];
    _trackView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    _trackView.layer.cornerRadius = 15;
    [_containerView addSubview:_trackView];

    _offLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, 5, 32, 20)];
    _offLabel.text = @"OFF";
    _offLabel.font = [UIFont boldSystemFontOfSize:12];
    _offLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    _offLabel.textAlignment = NSTextAlignmentCenter;
    [_trackView addSubview:_offLabel];

    _onLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 32, 20)];
    _onLabel.text = @"ON";
    _onLabel.font = [UIFont boldSystemFontOfSize:12];
    _onLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1];
    _onLabel.textAlignment = NSTextAlignmentCenter;
    [_trackView addSubview:_onLabel];

    _thumbView = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 30, 30)];
    _thumbView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
    _thumbView.layer.cornerRadius = 15;
    _thumbView.layer.shadowColor = [UIColor blackColor].CGColor;
    _thumbView.layer.shadowOffset = CGSizeMake(0, 1);
    _thumbView.layer.shadowRadius = 2;
    _thumbView.layer.shadowOpacity = 0.5;
    [_trackView addSubview:_thumbView];

    _isOn = NO;
}

- (void)setupGestures {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];

    _panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:_panGesture];
}

- (void)setupPosition {
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    self.frame = CGRectMake(screenW - 100, screenH * 0.45, 90, 36);
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    [self setOn:!_isOn animated:YES];
    if (self.onToggle) self.onToggle(_isOn);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _originalCenter = self.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [gesture translationInView:nil];
        self.center = CGPointMake(_originalCenter.x + t.x, _originalCenter.y + t.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat fx = self.frame.origin.x;
        CGFloat fy = self.frame.origin.y;
        // Snap to nearest edge
        CGFloat snapX = (fx + 45 < screenW / 2) ? 10 : screenW - 100;
        [UIView animateWithDuration:0.2 animations:^{
            self.frame = CGRectMake(snapX, fy, 90, 36);
        }];
        [[NSUserDefaults standardUserDefaults] setFloat:snapX forKey:@"FloatingSwitchX"];
        [[NSUserDefaults standardUserDefaults] setFloat:fy forKey:@"FloatingSwitchY"];
    }
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    CGFloat targetX = on ? 51 : 3;
    UIColor *thumbColor = on
        ? [UIColor colorWithRed:1.0 green:0.353 blue:0.122 alpha:1.0]
        : [UIColor colorWithWhite:0.25 alpha:1];
    UIColor *onColor  = on ? [UIColor whiteColor] : [UIColor colorWithWhite:0.2 alpha:1];
    UIColor *offColor = on ? [UIColor colorWithWhite:0.3 alpha:1] : [UIColor colorWithWhite:0.5 alpha:1];

    void (^update)(void) = ^{
        self->_thumbView.frame = CGRectMake(targetX, 3, 30, 30);
        self->_thumbView.backgroundColor = thumbColor;
        self->_onLabel.textColor  = onColor;
        self->_offLabel.textColor = offColor;
    };
    if (animated) {
        [UIView animateWithDuration:0.25 delay:0
             usingSpringWithDamping:0.7 initialSpringVelocity:0.5
                            options:0 animations:update completion:nil];
    } else {
        update();
    }
}

- (void)show {
    float savedX = [[NSUserDefaults standardUserDefaults] floatForKey:@"FloatingSwitchX"];
    float savedY = [[NSUserDefaults standardUserDefaults] floatForKey:@"FloatingSwitchY"];
    if (savedX != 0 || savedY != 0) {
        self.frame = CGRectMake(savedX, savedY, 90, 36);
    } else {
        [self setupPosition];
    }
    self.hidden = NO;
    self.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{ self.alpha = 1; }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0; }
                     completion:^(BOOL f){ self.hidden = YES; }];
}

@end
