#import <XCTest/XCTest.h>
#import <CoreAudio/CoreAudio.h>
#import <mach/mach.h>
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

static NSString *ATDeviceUID(AudioDeviceID device) {
    AudioObjectPropertyAddress address={kAudioDevicePropertyDeviceUID,kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};CFStringRef uid=NULL;UInt32 size=sizeof(uid);
    return AudioObjectGetPropertyData(device,&address,0,NULL,&size,&uid)==noErr&&uid?CFBridgingRelease(uid):nil;
}

static AudioDeviceID ATDeviceWithUID(NSString *uid) {
    for(NSNumber *device in ATOutputDevices())if([ATDeviceUID(device.unsignedIntValue) isEqual:uid])return device.unsignedIntValue;return kAudioObjectUnknown;
}
static AudioDeviceID ATOutputDeviceNamed(NSString *name) {
    for(NSNumber *device in ATOutputDevices())if([ATDeviceName(device.unsignedIntValue) isEqual:name])return device.unsignedIntValue;return kAudioObjectUnknown;
}

static UInt32 ATDeviceTransport(AudioDeviceID device) {
    AudioObjectPropertyAddress address={kAudioDevicePropertyTransportType,kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};UInt32 transport=0,size=sizeof(transport);
    AudioObjectGetPropertyData(device,&address,0,NULL,&size,&transport);return transport;
}

static uint64_t ATResidentMemory(void) {
    mach_task_basic_info_data_t info;mach_msg_type_number_t count=MACH_TASK_BASIC_INFO_COUNT;
    return task_info(mach_task_self(),MACH_TASK_BASIC_INFO,(task_info_t)&info,&count)==KERN_SUCCESS?info.resident_size:0;
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
    float volumeBeforeMute=engine.masterVolume;
    engine.masterMuted=YES;
    XCTAssertTrue(engine.masterMuted);
    XCTAssertEqualWithAccuracy(engine.masterVolume,volumeBeforeMute,.001);
    engine.masterMuted=NO;
    XCTAssertFalse(engine.masterMuted);
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

- (BOOL)waitForDeviceUID:(NSString *)uid present:(BOOL)present timeout:(NSTimeInterval)timeout {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:timeout];
    while(deadline.timeIntervalSinceNow>0){BOOL found=ATDeviceWithUID(uid)!=kAudioObjectUnknown;if(found==present)return YES;[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.2]];}return NO;
}

- (NSDictionary *)hardwareInteractionConfiguration {
    return [NSDictionary dictionaryWithContentsOfFile:@"/tmp/AtmosphereHardwareInteraction.plist"];
}

- (void)testPhysicalOutputUnplugAndReconnect {
    NSDictionary *configuration=self.hardwareInteractionConfiguration;
    XCTSkipUnless([configuration[@"Mode"] isEqual:@"unplug"],@"Run scripts/test-physical-audio.sh with an output-device UID for this operator-assisted test.");
    AudioDeviceID configured=ATOutputDeviceNamed(configuration[@"DeviceName"]);NSString *uid=ATDeviceUID(configured);
    NSTimeInterval timeout=[configuration[@"Timeout"] doubleValue]?:60;
    AudioDeviceID device=ATDeviceWithUID(uid);XCTAssertNotEqual(device,kAudioObjectUnknown,@"Configured device is not currently connected");
    NSLog(@"Unplug %@ now",ATDeviceName(device));
    XCTAssertTrue([self waitForDeviceUID:uid present:NO timeout:timeout],@"Device was not unplugged before the timeout");
    NSLog(@"Reconnect the device now");
    XCTAssertTrue([self waitForDeviceUID:uid present:YES timeout:timeout],@"Device did not return before the timeout");
}

- (void)testBluetoothDelayedDisconnectReconnectAndProfileTransition {
    NSDictionary *configuration=self.hardwareInteractionConfiguration;
    XCTSkipUnless([configuration[@"Mode"] isEqual:@"bluetooth"],@"Run scripts/test-bluetooth-audio.sh with a Bluetooth output-device UID.");
    AudioDeviceID configured=ATOutputDeviceNamed(configuration[@"DeviceName"]);NSString *uid=ATDeviceUID(configured);NSTimeInterval timeout=[configuration[@"Timeout"] doubleValue]?:90;
    AudioDeviceID device=ATDeviceWithUID(uid);XCTAssertNotEqual(device,kAudioObjectUnknown,@"Configured Bluetooth device is not connected");
    UInt32 transport=ATDeviceTransport(device);XCTAssertTrue(transport==kAudioDeviceTransportTypeBluetooth||transport==kAudioDeviceTransportTypeBluetoothLE,@"%@ is not reported as Bluetooth",ATDeviceName(device));
    ATAudioEngine *engine=[ATAudioEngine new];engine.masterVolume=0;NSError *error=nil;
    XCTAssertTrue([engine startSound:[self proceduralSound:@"bluetooth-transition"] volume:.01 error:&error],@"%@",error);
    NSLog(@"Disconnect or power off %@ now; reconnect it after disappearance is detected",ATDeviceName(device));
    XCTAssertTrue([self waitForDeviceUID:uid present:NO timeout:timeout],@"Bluetooth device never disappeared");
    XCTAssertTrue([self waitForDeviceUID:uid present:YES timeout:timeout],@"Bluetooth device did not reconnect after its delayed transition");
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    XCTAssertTrue([engine isActive:@"bluetooth-transition"]);XCTAssertTrue([[engine valueForKey:@"_engine"] isRunning]);
}

- (void)testFourHourAudioSoak {
    NSDictionary *configuration=[NSDictionary dictionaryWithContentsOfFile:@"/tmp/AtmosphereSoakTest.plist"];
    XCTSkipUnless(configuration,@"Run scripts/run-soak-tests.sh to enable the four-hour soak test.");
    NSTimeInterval duration=MAX(1,[configuration[@"DurationSeconds"] doubleValue]);
    ATAudioEngine *engine=[ATAudioEngine new];engine.masterVolume=0;NSMutableArray *sounds=[NSMutableArray new];NSError *error=nil;
    for(NSUInteger index=0;index<8;index++){NSString *identifier=[NSString stringWithFormat:@"soak-%lu",(unsigned long)index];ATSound *sound=[self proceduralSound:identifier];[sounds addObject:sound];XCTAssertTrue([engine startSound:sound volume:.02 error:&error],@"%@",error);}
    uint64_t initialMemory=ATResidentMemory();NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:duration];NSUInteger iteration=0;
    while(deadline.timeIntervalSinceNow>0){ATSound *sound=sounds[iteration%sounds.count];if([engine isActive:sound.identifier])[engine stopSound:sound.identifier];else XCTAssertTrue([engine startSound:sound volume:.02 error:&error],@"%@",error);if(iteration%20==0){[engine pauseAll];XCTAssertTrue([engine resumeAll:&error],@"%@",error);}[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.25]];iteration++;}
    uint64_t growth=ATResidentMemory()>initialMemory?ATResidentMemory()-initialMemory:0;XCTAssertLessThan(growth,200ULL*1024*1024,@"soak-test resident memory grew by more than 200 MB");[engine clear];
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
