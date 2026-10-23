#import "AirVideo.h"

@interface AirVideo () <AVPlayerViewControllerDelegate>
@end

@implementation AirVideo

static FREContext _context = nil;

+ (AirVideo *)sharedInstance {
    static AirVideo *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AirVideo alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _playerController = [[AVPlayerViewController alloc] init];
        _playerController.delegate = self;
        _playerController.showsPlaybackControls = YES;
        _playerController.videoGravity = AVLayerVideoGravityResize;
        
        // 🛡️ 1. إلغاء النوافذ العائمة وزر الـ PiP
        _playerController.allowsPictureInPicturePlayback = NO;
        
        // 🛡️ 2. منع الدخول التلقائي في ملء الشاشة
        if (@available(iOS 11.0, *)) {
            _playerController.entersFullScreenWhenPlaybackBegins = NO;
        }
        
        // 🛡️ 3. إلغاء عداد السرعة نهائياً
        if (@available(iOS 16.0, *)) {
            _playerController.speeds = @[];
        }
                                                   
        // مراقبة العودة للتطبيق لاستئناف التشغيل التلقائي
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [self hidePlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_player release];
    [_playerController release];
    [super dealloc];
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    if (self.player && self.playerController.view.superview) {
        [self.player play];
    }
}

// 🎯 دالة سحرية للبحث عن زر التكبير وإخفائه تماماً من الواجهة
- (void)removeFullscreenButtonFromView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        
        if ([subview isKindOfClass:[UIButton class]] || [className containsString:@"Button"]) {
            UIButton *btn = (UIButton *)subview;
            NSString *label = btn.accessibilityLabel ? btn.accessibilityLabel.lowercaseString : @"";
            NSString *identifier = btn.accessibilityIdentifier ? btn.accessibilityIdentifier.lowercaseString : @"";
            
            if ([label containsString:@"full"] || [label containsString:@"zoom"] || 
                [identifier containsString:@"full"] || [className containsString:@"FullScreen"]) {
                btn.hidden = YES;
                btn.alpha = 0.0;
                btn.userInteractionEnabled = NO;
                [btn removeFromSuperview];
            }
        }
        [self removeFullscreenButtonFromView:subview];
    }
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController willBeginFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [playerViewController dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)loadVideo:(NSString *)urlString {
    NSURL *url = nil;
    if ([urlString hasPrefix:@"file://"] || [urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:urlString];
    } else {
        url = [NSURL fileURLWithPath:urlString];
    }
    
    // 🛡️ تنظيف الـ Observer القديم قبل تحميل أي فيديو جديد
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:AVPlayerItemDidPlayToEndTimeNotification 
                                                  object:nil];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    
    // ربط المراقب بالـ Item الجديد فقط لمنع تسريب الرام
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidFinish:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item];
    
    if (!self.player) {
        self.player = [AVPlayer playerWithPlayerItem:item];
        self.player.allowsExternalPlayback = NO;
        self.playerController.player = self.player;
    } else {
        self.player.allowsExternalPlayback = NO;
        [self.player replaceCurrentItemWithPlayerItem:item];
    }
    
    [self.player play];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.playerController.view) {
            [self removeFullscreenButtonFromView:self.playerController.view];
        }
    });
}

- (void)showPlayerAtX:(int)x y:(int)y width:(int)width height:(int)height {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale <= 0) scale = 1.0;
    
    CGRect frame;
    if (width > 0 && height > 0) {
        CGFloat xPt = (CGFloat)x / scale;
        CGFloat yPt = (CGFloat)y / scale;
        CGFloat wPt = (CGFloat)width / scale;
        CGFloat hPt = (CGFloat)height / scale;
        frame = CGRectMake(xPt, yPt, wPt, hPt);
    } else {
        frame = rootViewController.view.bounds;
    }
    
    self.playerController.view.frame = frame;
    if (!self.playerController.view.superview) {
        [rootViewController.view addSubview:self.playerController.view];
        [rootViewController addChildViewController:self.playerController];
        [self.playerController didMoveToParentViewController:rootViewController];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeFullscreenButtonFromView:self.playerController.view];
    });
}

- (void)setPlayerBoundsAtX:(int)x y:(int)y width:(int)width height:(int)height {
    if (!self.playerController || !self.playerController.view.superview) return;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale <= 0) scale = 1.0;
    
    CGRect frame;
    if (width > 0 && height > 0) {
        CGFloat xPt = (CGFloat)x / scale;
        CGFloat yPt = (CGFloat)y / scale;
        CGFloat wPt = (CGFloat)width / scale;
        CGFloat hPt = (CGFloat)height / scale;
        frame = CGRectMake(xPt, yPt, wPt, hPt);
    } else {
        frame = rootViewController.view.bounds;
    }
    self.playerController.view.frame = frame;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeFullscreenButtonFromView:self.playerController.view];
    });
}

// 🛡️ دالة الإغلاق والتنظيف التام للذاكرة (Zero Memory Leak)
- (void)hidePlayer {
    if (self.playerController) {
        if (self.player) {
            [self.player pause];
            [self.player.currentItem cancelPendingSeeks];
            [self.player.currentItem.asset cancelLoading];
            [self.player replaceCurrentItemWithPlayerItem:nil];
            self.player = nil;
        }
        
        self.playerController.player = nil;

        if (self.playerController.view.superview) {
            [self.playerController willMoveToParentViewController:nil];
            [self.playerController.view removeFromSuperview];
            [self.playerController removeFromParentViewController];
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:AVPlayerItemDidPlayToEndTimeNotification 
                                                      object:nil];
    }
}

- (void)pause {
    if (self.player) {
        [self.player pause];
    }
}

- (void)resume {
    if (self.player) {
        if (self.player.currentItem) {
            CMTime cur = self.player.currentTime;
            CMTime dur = self.player.currentItem.duration;
            if (CMTIME_IS_VALID(cur) && CMTIME_IS_VALID(dur)) {
                if (CMTimeGetSeconds(cur) >= CMTimeGetSeconds(dur) - 0.5) {
                    [self.player seekToTime:kCMTimeZero];
                }
            }
        }
        [self.player play];
    }
}

- (void)replay {
    if (self.player) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
    }
}

- (void)showControls:(BOOL)show {
    if (self.playerController) {
        self.playerController.showsPlaybackControls = show;
        self.playerController.view.userInteractionEnabled = show;
        
        if (show) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeFullscreenButtonFromView:self.playerController.view];
            });
        }
    }
}

- (void)playerDidFinish:(NSNotification *)notification {
    if (notification.object == self.player.currentItem) {
        if (self.player) {
            [self.player seekToTime:kCMTimeZero];
        }
        [AirVideo dispatchEvent:@"PLAYBACK_DID_FINISH" withInfo:@"OK"];
    }
}

+ (void)dispatchEvent:(NSString *)eventName withInfo:(NSString *)info {
    if (_context) {
        FREDispatchStatusEventAsync(_context, (const uint8_t *)[eventName UTF8String], (const uint8_t *)[info UTF8String]);
    }
}

+ (void)log:(NSString *)message {
    [AirVideo dispatchEvent:@"LOGGING" withInfo:message];
}

@end

// C Functions
DEFINE_ANE_FUNCTION(showPlayer) {
    int32_t x = -1, y = -1, w = -1, h = -1;
    if (argc >= 4) {
        FREGetObjectAsInt32(argv[0], &x);
        FREGetObjectAsInt32(argv[1], &y);
        FREGetObjectAsInt32(argv[2], &w);
        FREGetObjectAsInt32(argv[3], &h);
    }
    [[AirVideo sharedInstance] showPlayerAtX:x y:y width:w height:h];
    return nil;
}

DEFINE_ANE_FUNCTION(setPlayerBounds) {
    int32_t x = 0, y = 0, w = 0, h = 0;
    if (argc >= 4) {
        FREGetObjectAsInt32(argv[0], &x);
        FREGetObjectAsInt32(argv[1], &y);
        FREGetObjectAsInt32(argv[2], &w);
        FREGetObjectAsInt32(argv[3], &h);
    }
    [[AirVideo sharedInstance] setPlayerBoundsAtX:x y:y width:w height:h];
    return nil;
}

DEFINE_ANE_FUNCTION(hidePlayer) {
    [[AirVideo sharedInstance] hidePlayer];
    return nil;
}

DEFINE_ANE_FUNCTION(loadVideo) {
    uint32_t length;
    const uint8_t *urlStr;
    if (FREGetObjectAsUTF8(argv[0], &length, &urlStr) == FRE_OK) {
        NSString *url = [NSString stringWithUTF8String:(const char *)urlStr];
        [[AirVideo sharedInstance] loadVideo:url];
    }
    return nil;
}

DEFINE_ANE_FUNCTION(pausePlayer) {
    [[AirVideo sharedInstance] pause];
    return nil;
}

DEFINE_ANE_FUNCTION(resumePlayer) {
    [[AirVideo sharedInstance] resume];
    return nil;
}

DEFINE_ANE_FUNCTION(replayPlayer) {
    [[AirVideo sharedInstance] replay];
    return nil;
}

DEFINE_ANE_FUNCTION(showControls) {
    uint32_t show = 1;
    if (argc >= 1) {
        FREGetObjectAsBool(argv[0], &show);
    }
    [[AirVideo sharedInstance] showControls:(show != 0)];
    return nil;
}

void AirVideoContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) {
    _context = ctx;
    static FRENamedFunction functions[] = {
        { (const uint8_t*)"showPlayer", NULL, &showPlayer },
        { (const uint8_t*)"hidePlayer", NULL, &hidePlayer },
        { (const uint8_t*)"loadVideo", NULL, &loadVideo },
        { (const uint8_t*)"setPlayerBounds", NULL, &setPlayerBounds },
        { (const uint8_t*)"pause", NULL, &pausePlayer },
        { (const uint8_t*)"resume", NULL, &resumePlayer },
        { (const uint8_t*)"replay", NULL, &replayPlayer },
        { (const uint8_t*)"showControls", NULL, &showControls }
    };
    *numFunctionsToTest = sizeof(functions) / sizeof(FRENamedFunction);
    *functionsToSet = functions;
}

void AirVideoContextFinalizer(FREContext ctx) {
    _context = nil;
}

void AirVideoInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &AirVideoContextInitializer;
    *ctxFinalizerToSet = &AirVideoContextFinalizer;
}

void AirVideoFinalizer(void *extData) {}
