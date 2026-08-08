#import <XCTest/XCTest.h>
#import "ATPresetStore.h"
#import "ATAudioEngine.h"
#import "ATSound.h"

@interface AtmospherePerformanceTests : XCTestCase
@end

@implementation AtmospherePerformanceTests
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
@end
