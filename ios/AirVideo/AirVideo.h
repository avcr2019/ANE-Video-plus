#import "FlashRuntimeExtensions.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface AirVideo : NSObject

@property (nonatomic, strong) AVPlayerViewController *playerController;
@property (nonatomic, strong) AVPlayer *player;

+ (AirVideo *)sharedInstance;
+ (void)dispatchEvent:(NSString *)eventName withInfo:(NSString *)info;
+ (void)log:(NSString *)message;

- (void)showPlayerAtX:(int)x y:(int)y width:(int)width height:(int)height;
- (void)hidePlayer;
- (void)setPlayerBoundsAtX:(int)x y:(int)y width:(int)width height:(int)height;
- (void)loadVideo:(NSString *)urlString;
- (void)pause;
- (void)resume;
- (void)replay;
- (void)showControls:(BOOL)show;

@end

// C interface
DEFINE_ANE_FUNCTION(showPlayer);
DEFINE_ANE_FUNCTION(hidePlayer);
DEFINE_ANE_FUNCTION(loadVideo);
DEFINE_ANE_FUNCTION(setPlayerBounds);
DEFINE_ANE_FUNCTION(pausePlayer);
DEFINE_ANE_FUNCTION(resumePlayer);
DEFINE_ANE_FUNCTION(replayPlayer);
DEFINE_ANE_FUNCTION(showControls);

// ANE Setup
void AirVideoContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet);
void AirVideoContextFinalizer(FREContext ctx);
void AirVideoInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet);
void AirVideoFinalizer(void *extData);
