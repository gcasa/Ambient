#import <AVFoundation/AVFoundation.h>
@class ATSound;

NS_ASSUME_NONNULL_BEGIN
@interface ATAudioEngine : NSObject
@property (nonatomic) float masterVolume;
@property (nonatomic, getter=isMasterMuted) BOOL masterMuted;
@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, copy, readonly) NSArray<NSString *> *activeIdentifiers;
@property (nonatomic, copy, nullable) void (^stateChanged)(void);
@property (nonatomic, copy, nullable) void (^errorOccurred)(NSError *error);
- (BOOL)startSound:(ATSound *)sound volume:(float)volume error:(NSError **)error;
- (void)stopSound:(NSString *)identifier;
- (void)setVolume:(float)volume forSound:(NSString *)identifier;
- (float)volumeForSound:(NSString *)identifier;
- (void)setMuted:(BOOL)muted forSound:(NSString *)identifier;
- (BOOL)isMuted:(NSString *)identifier;
- (BOOL)isActive:(NSString *)identifier;
- (void)pauseAll;
- (BOOL)resumeAll:(NSError **)error;
- (void)prepareForSystemSleep;
- (void)recoverAfterSystemWake;
- (void)clear;
- (void)fadeOutOver:(NSTimeInterval)duration completion:(dispatch_block_t)completion;
@end
NS_ASSUME_NONNULL_END
