#import <XCTest/XCTest.h>
#import "ATPresetStore.h"
#import "ATAudioEngine.h"
#import "ATSound.h"

@interface AtmospherePerformanceTests : XCTestCase
@end

@implementation AtmospherePerformanceTests
- (NSDictionary *)committedBaselines {
    NSURL *url=[NSBundle bundleForClass:self.class].resourceURL;url=[url URLByAppendingPathComponent:@"PerformanceBaselines.plist"];
    NSDictionary *baselines=[NSDictionary dictionaryWithContentsOfURL:url];XCTAssertNotNil(baselines);return baselines;
}
- (void)assertOperation:(NSString *)name block:(dispatch_block_t)block {
    NSNumber *maximum=self.committedBaselines[@"MaximumSeconds"][name];XCTAssertNotNil(maximum);
    CFAbsoluteTime start=CFAbsoluteTimeGetCurrent();block();NSTimeInterval elapsed=CFAbsoluteTimeGetCurrent()-start;
    XCTAssertLessThan(elapsed,maximum.doubleValue,@"%@ took %.6fs; committed maximum is %.6fs",name,elapsed,maximum.doubleValue);
}
- (NSArray<id<XCTMetric>> *)resourceMetrics {
    return @[[XCTClockMetric new],[[XCTCPUMetric alloc] initLimitingToCurrentThread:NO],[XCTMemoryMetric new]];
}

- (void)testCatalogLookupPerformance {
    ATSoundCatalog *catalog=[ATSoundCatalog new];
    NSArray<NSString *> *identifiers=[catalog.sounds valueForKey:@"identifier"];
    [self measureWithMetrics:self.resourceMetrics block:^{
        for(NSUInteger pass=0;pass<1000;pass++)
            for(NSString *identifier in identifiers)
                XCTAssertNotNil([catalog soundWithIdentifier:identifier]);
    }];
}

- (void)testPreferenceSerializationPerformance {
    NSString *suite=[@"AtmospherePerformance." stringByAppendingString:NSUUID.UUID.UUIDString];
    NSUserDefaults *defaults=[[NSUserDefaults alloc] initWithSuiteName:suite];
    ATPresetStore *store=[[ATPresetStore alloc] initWithUserDefaults:defaults];
    NSMutableDictionary *mix=[NSMutableDictionary new];
    for(NSUInteger index=0;index<24;index++)mix[[NSString stringWithFormat:@"sound-%lu",(unsigned long)index]]=@((index+1)/25.0);
    [self measureWithMetrics:self.resourceMetrics block:^{
        for(NSUInteger pass=0;pass<500;pass++) {
            [store saveRecentMix:mix];
            XCTAssertEqual(store.recentMix.count,24);
        }
    }];
    [defaults removePersistentDomainForName:suite];
}

- (void)testActiveMultiVoiceControlPerformance {
    ATAudioEngine *engine=[ATAudioEngine new];
    NSMutableArray<NSString *> *identifiers=[NSMutableArray new];
    NSError *error=nil;
    for(NSUInteger index=0;index<6;index++) {
        NSString *identifier=[NSString stringWithFormat:@"performance-%lu",(unsigned long)index];
        ATSound *sound=[ATSound sound:identifier name:identifier category:@"Test" symbol:@"waveform" generator:@"white" tags:@[]];
        XCTAssertTrue([engine startSound:sound volume:.1 error:&error],@"%@",error);
        [identifiers addObject:identifier];
    }
    [self measureWithMetrics:self.resourceMetrics block:^{
        for(NSUInteger pass=0;pass<20;pass++)
            for(NSUInteger index=0;index<identifiers.count;index++) {
                [engine setVolume:(float)((pass+index)%10)/10 forSound:identifiers[index]];
                [engine setMuted:(pass+index)%7==0 forSound:identifiers[index]];
            }
    }];
    [engine clear];
    XCTestExpectation *detached=[self expectationWithDescription:@"voices detached"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[detached fulfill];});
    [self waitForExpectations:@[detached] timeout:1];
}

- (void)testCommittedReferenceThresholds {
    ATSoundCatalog *catalog=[ATSoundCatalog new];NSArray *identifiers=[catalog.sounds valueForKey:@"identifier"];
    [self assertOperation:@"CatalogLookup" block:^{for(NSUInteger pass=0;pass<1000;pass++)for(NSString *identifier in identifiers)[catalog soundWithIdentifier:identifier];}];
    NSString *suite=[@"AtmosphereBaseline." stringByAppendingString:NSUUID.UUID.UUIDString];NSUserDefaults *defaults=[[NSUserDefaults alloc]initWithSuiteName:suite];ATPresetStore *store=[[ATPresetStore alloc]initWithUserDefaults:defaults];NSMutableDictionary *mix=[NSMutableDictionary new];for(NSUInteger i=0;i<24;i++)mix[[NSString stringWithFormat:@"sound-%lu",(unsigned long)i]]=@.2;
    [self assertOperation:@"PreferenceSerialization" block:^{for(NSUInteger pass=0;pass<500;pass++){[store saveRecentMix:mix];(void)store.recentMix;}}];[defaults removePersistentDomainForName:suite];
    ATAudioEngine *engine=[ATAudioEngine new];engine.masterVolume=0;NSError *error=nil;NSMutableArray *active=[NSMutableArray new];for(NSUInteger i=0;i<6;i++){NSString *identifier=[NSString stringWithFormat:@"baseline-%lu",(unsigned long)i];[active addObject:identifier];XCTAssertTrue([engine startSound:[ATSound sound:identifier name:identifier category:@"Test" symbol:@"waveform" generator:@"white" tags:@[]] volume:.01 error:&error]);}
    [self assertOperation:@"ActiveVoiceControl" block:^{for(NSUInteger pass=0;pass<20;pass++)for(NSString *identifier in active){[engine setVolume:.2 forSound:identifier];[engine setMuted:pass%7==0 forSound:identifier];}}];[engine clear];
}
@end
