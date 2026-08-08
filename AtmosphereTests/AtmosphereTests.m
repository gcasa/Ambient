#import <XCTest/XCTest.h>
#import <CoreAudio/CoreAudio.h>
#import "ATPresetStore.h"
#import "ATTimerController.h"
#import "ATAudioEngine.h"
#import "ATSound.h"

static AudioDeviceID ATDefaultOutputDevice(void) {
    AudioDeviceID device=kAudioObjectUnknown;UInt32 size=sizeof(device);
    AudioObjectPropertyAddress address={kAudioHardwarePropertyDefaultOutputDevice,kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};
    return AudioObjectGetPropertyData(kAudioObjectSystemObject,&address,0,NULL,&size,&device)==noErr?device:kAudioObjectUnknown;
}

static BOOL ATDeviceHasOutput(AudioDeviceID device) {
    AudioObjectPropertyAddress aliveAddress={kAudioDevicePropertyDeviceIsAlive,kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};
    UInt32 alive=0,size=sizeof(alive);if(AudioObjectGetPropertyData(device,&aliveAddress,0,NULL,&size,&alive)!=noErr||!alive)return NO;
    AudioObjectPropertyAddress streamAddress={kAudioDevicePropertyStreamConfiguration,kAudioDevicePropertyScopeOutput,kAudioObjectPropertyElementMain};
    UInt32 listSize=0;if(AudioObjectGetPropertyDataSize(device,&streamAddress,0,NULL,&listSize)!=noErr||!listSize)return NO;
    AudioBufferList *list=malloc(listSize);BOOL hasOutput=NO;
    if(AudioObjectGetPropertyData(device,&streamAddress,0,NULL,&listSize,list)==noErr)for(UInt32 index=0;index<list->mNumberBuffers;index++)if(list->mBuffers[index].mNumberChannels){hasOutput=YES;break;}
    free(list);return hasOutput;
}

static NSArray<NSNumber *> *ATOutputDevices(void) {
    AudioObjectPropertyAddress address={kAudioHardwarePropertyDevices,kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};
    UInt32 size=0;if(AudioObjectGetPropertyDataSize(kAudioObjectSystemObject,&address,0,NULL,&size)!=noErr)return @[];
    AudioDeviceID *devices=malloc(size);NSMutableArray *outputs=[NSMutableArray new];
    if(AudioObjectGetPropertyData(kAudioObjectSystemObject,&address,0,NULL,&size,devices)==noErr)for(UInt32 index=0;index<size/sizeof(AudioDeviceID);index++)if(ATDeviceHasOutput(devices[index]))[outputs addObject:@(devices[index])];
    free(devices);return outputs;
}

static NSString *ATDeviceName(AudioDeviceID device) {
    AudioObjectPropertyAddress address={kAudioObjectPropertyName,kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};CFStringRef name=NULL;UInt32 size=sizeof(name);
    if(AudioObjectGetPropertyData(device,&address,0,NULL,&size,&name)!=noErr||!name)return [NSString stringWithFormat:@"device %u",device];
    return CFBridgingRelease(name);
}

static OSStatus ATSetDefaultOutputDevice(AudioDeviceID device) {
    AudioObjectPropertyAddress address={kAudioHardwarePropertyDefaultOutputDevice,kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};
    return AudioObjectSetPropertyData(kAudioObjectSystemObject,&address,0,NULL,sizeof(device),&device);
}

@interface AtmosphereTests : XCTestCase
@property NSString *suiteName;
@property NSUserDefaults *defaults;
@end

@implementation AtmosphereTests
- (void)setUp {
    [super setUp];
    self.suiteName=[@"AtmosphereTests." stringByAppendingString:NSUUID.UUID.UUIDString];
    self.defaults=[[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
    [self.defaults removePersistentDomainForName:self.suiteName];
}
- (void)tearDown {
    [self.defaults removePersistentDomainForName:self.suiteName];
    self.defaults=nil;
    [super tearDown];
}

- (void)testPresetCRUDAndRecentMixRoundTrip {
    ATPresetStore *store=[[ATPresetStore alloc] initWithUserDefaults:self.defaults];
    NSDictionary *mix=@{@"rain":@.35,@"fire":@.2};
    [store savePresetNamed:@"Cabin" mix:mix];
    XCTAssertEqual(store.userPresets.count,1);
    XCTAssertEqualObjects(store.userPresets.firstObject[@"mix"],mix);
    [store renamePresetAtIndex:0 name:@"Quiet Cabin"];
    XCTAssertEqualObjects(store.userPresets.firstObject[@"name"],@"Quiet Cabin");
    [store saveRecentMix:mix];
    XCTAssertEqualObjects(store.recentMix,mix);
    [store deletePresetAtIndex:0];
    XCTAssertEqual(store.userPresets.count,0);
}

- (void)testPresetStoreRejectsCorruptedPreferences {
    ATPresetStore *store=[[ATPresetStore alloc] initWithUserDefaults:self.defaults];
    [self.defaults setObject:@"not an array" forKey:@"ATUserPresets"];
    XCTAssertEqual(store.userPresets.count,0);
    [self.defaults setObject:@[@{@"name":@42,@"mix":@{}},@{@"name":@"Broken",@"mix":@{@"rain":@"loud"}}] forKey:@"ATUserPresets"];
    XCTAssertEqual(store.userPresets.count,0);
    [self.defaults setObject:@{@"rain":@"loud"} forKey:@"ATRecentMix"];
    XCTAssertEqualObjects(store.recentMix,@{});
}

- (void)testTimerCompletesAndCarriesFadeSetting {
    ATTimerController *timer=[ATTimerController new];
    timer.fadeOut=YES;
    XCTestExpectation *finished=[self expectationWithDescription:@"timer finished"];
    timer.finished=^(BOOL fadeOut){ XCTAssertTrue(fadeOut);[finished fulfill]; };
    [timer startDuration:.03];
    XCTAssertTrue(timer.running);
    [self waitForExpectations:@[finished] timeout:1];
    XCTAssertFalse(timer.running);
    XCTAssertEqual(timer.remaining,0);
}

- (void)testTimerCancellationDoesNotFinish {
    ATTimerController *timer=[ATTimerController new];
    XCTestExpectation *notFinished=[self expectationWithDescription:@"timer remains cancelled"];
    notFinished.inverted=YES;
    timer.finished=^(BOOL fadeOut){ [notFinished fulfill]; };
    [timer startDuration:.03];
    [timer cancel];
    [self waitForExpectations:@[notFinished] timeout:.1];
    XCTAssertFalse(timer.running);
}

- (ATSound *)proceduralSound:(NSString *)identifier {
    return [ATSound sound:identifier name:identifier category:@"Test" symbol:@"waveform" generator:@"white" tags:@[]];
}

- (void)testAudioStartVolumeMutePauseResumeAndStop {
    ATAudioEngine *engine=[ATAudioEngine new];
    NSError *error=nil;
    ATSound *sound=[self proceduralSound:@"test-white"];
    XCTAssertTrue([engine startSound:sound volume:.3 error:&error],@"%@",error);
    XCTAssertTrue([engine isActive:sound.identifier]);
    [engine setVolume:.65 forSound:sound.identifier];
    XCTAssertEqualWithAccuracy([engine volumeForSound:sound.identifier],.65,.001);
    [engine setMuted:YES forSound:sound.identifier];
    XCTAssertTrue([engine isMuted:sound.identifier]);
    [engine pauseAll];
    XCTAssertTrue(engine.paused);
    XCTAssertTrue([engine resumeAll:&error],@"%@",error);
    XCTAssertFalse(engine.paused);
    [engine stopSound:sound.identifier];
    XCTAssertFalse([engine isActive:sound.identifier]);
}

- (void)testAudioRecoversFromConfigurationChange {
    ATAudioEngine *engine=[ATAudioEngine new];
    NSError *error=nil;
    XCTAssertTrue([engine startSound:[self proceduralSound:@"route-test"] volume:.2 error:&error],@"%@",error);
    AVAudioEngine *underlying=[engine valueForKey:@"_engine"];
    [NSNotificationCenter.defaultCenter postNotificationName:AVAudioEngineConfigurationChangeNotification object:underlying];
    XCTestExpectation *settled=[self expectationWithDescription:@"recovery settled"];
    dispatch_async(dispatch_get_main_queue(),^{ [settled fulfill]; });
    [self waitForExpectations:@[settled] timeout:1];
    XCTAssertTrue([engine isActive:@"route-test"]);
    XCTAssertTrue(underlying.running);
}

- (void)testAudioSuspendsAndRecoversAcrossSystemSleep {
    ATAudioEngine *engine=[ATAudioEngine new];
    NSError *error=nil;
    XCTAssertTrue([engine startSound:[self proceduralSound:@"wake-test"] volume:.2 error:&error],@"%@",error);
    AVAudioEngine *underlying=[engine valueForKey:@"_engine"];
    [engine prepareForSystemSleep];
    XCTAssertFalse(underlying.running);
    XCTAssertFalse(engine.paused,@"system sleep must not become a user pause");
    [engine recoverAfterSystemWake];
    XCTAssertTrue(underlying.running);
    XCTAssertTrue([engine isActive:@"wake-test"]);
}

- (void)testRealOutputDeviceSwitchAndRecovery {
    AudioDeviceID original=ATDefaultOutputDevice();
    XCTAssertNotEqual(original,kAudioObjectUnknown);
    AudioDeviceID alternate=kAudioObjectUnknown;
    for(NSNumber *candidate in ATOutputDevices())if(candidate.unsignedIntValue!=original){alternate=candidate.unsignedIntValue;break;}
    XCTSkipIf(alternate==kAudioObjectUnknown,@"This hardware test requires at least two live output devices.");

    ATAudioEngine *engine=[ATAudioEngine new];engine.masterVolume=0;
    NSError *error=nil;XCTAssertTrue([engine startSound:[self proceduralSound:@"hardware-route-test"] volume:.01 error:&error],@"%@",error);
    AVAudioEngine *underlying=[engine valueForKey:@"_engine"];
    XCTestExpectation *changed=[self expectationWithDescription:[NSString stringWithFormat:@"switch from %@ to %@",ATDeviceName(original),ATDeviceName(alternate)]];
    id observer=[NSNotificationCenter.defaultCenter addObserverForName:AVAudioEngineConfigurationChangeNotification object:underlying queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note){[changed fulfill];}];
    @try {
        OSStatus switchStatus=ATSetDefaultOutputDevice(alternate);
        XCTAssertEqual(switchStatus,noErr,@"Core Audio could not select %@ (OSStatus %d)",ATDeviceName(alternate),(int)switchStatus);
        [self waitForExpectations:@[changed] timeout:5];
        XCTAssertEqual(ATDefaultOutputDevice(),alternate);
        XCTAssertTrue([engine isActive:@"hardware-route-test"]);
        XCTAssertTrue(underlying.running,@"the audio engine did not recover after a real route change");
    } @finally {
        [NSNotificationCenter.defaultCenter removeObserver:observer];
        OSStatus restoreStatus=ATSetDefaultOutputDevice(original);
        XCTAssertEqual(restoreStatus,noErr,@"Failed to restore %@ (OSStatus %d)",ATDeviceName(original),(int)restoreStatus);
    }
}

- (void)testRepeatedMultiSoundSwitchingStress {
    ATAudioEngine *engine=[ATAudioEngine new];
    NSError *error=nil;
    for(NSUInteger pass=0;pass<20;pass++) {
        for(NSUInteger index=0;index<6;index++) {
            NSString *identifier=[NSString stringWithFormat:@"stress-%lu",(unsigned long)index];
            XCTAssertTrue([engine startSound:[self proceduralSound:identifier] volume:.1 error:&error],@"pass %lu: %@",(unsigned long)pass,error);
            [engine setVolume:(float)(index+1)/10 forSound:identifier];
            [engine setMuted:index%2==0 forSound:identifier];
        }
        [engine clear];
    }
    XCTAssertEqual(engine.activeIdentifiers.count,0);
    XCTestExpectation *detachments=[self expectationWithDescription:@"async detachments finished"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.6*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[detachments fulfill];});
    [self waitForExpectations:@[detachments] timeout:1];
}
@end
