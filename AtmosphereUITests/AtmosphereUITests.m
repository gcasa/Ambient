#import <XCTest/XCTest.h>

@interface AtmosphereUITests : XCTestCase
@property XCUIApplication *app;
@end

@implementation AtmosphereUITests
- (void)setUp {
    [super setUp];
    self.continueAfterFailure=NO;
    self.app=[XCUIApplication new];
    self.app.launchArguments=@[@"-ApplePersistenceIgnoreState",@"YES",@"-ATUITesting",@"YES"];
    [self.app launch];
    XCUIElement *window=self.app.windows[@"Atmosphere"];
    XCTAssertTrue([window waitForExistenceWithTimeout:3]);
    XCUIElement *stop=self.app.buttons[@"stop-all"];
    if(stop.exists)[stop click];
}

- (void)testSearchPlayPauseAndClearWorkflow {
    XCUIElement *search=self.app.searchFields[@"sound-search"];
    XCTAssertTrue([search waitForExistenceWithTimeout:2]);
    [search click];
    [search typeText:@"Rain"];

    XCUIElement *rain=self.app.buttons[@"sound-rain"];
    XCTAssertTrue([rain waitForExistenceWithTimeout:2]);
    [rain click];

    XCUIElement *status=self.app.staticTexts[@"mix-status"];
    NSPredicate *oneSound=[NSPredicate predicateWithFormat:@"value CONTAINS '1 sound playing'"];
    [self expectationForPredicate:oneSound evaluatedWithObject:status handler:nil];
    [self waitForExpectationsWithTimeout:2 handler:nil];

    XCUIElement *pause=self.app.buttons[@"pause-all"];
    [pause click];
    XCTAssertTrue([self.app.buttons[@"pause-all"] waitForExistenceWithTimeout:1]);
    [self.app.buttons[@"pause-all"] click];

    XCUIElement *mute=self.app.buttons[@"mute-all"];
    [mute click];
    [self.app.buttons[@"mute-all"] click];

    [self.app.buttons[@"stop-all"] click];
    NSPredicate *empty=[NSPredicate predicateWithFormat:@"value == 'Choose sounds to begin'"];
    [self expectationForPredicate:empty evaluatedWithObject:status handler:nil];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testCategoryFilterAndTimerWorkflow {
    XCUIElement *category=self.app.popUpButtons[@"category-filter"];
    XCTAssertTrue([category waitForExistenceWithTimeout:2]);
    [category click];
    [self.app.menuItems[@"Noise"] click];
    XCTAssertTrue([self.app.buttons[@"sound-white"] waitForExistenceWithTimeout:2]);
    XCTAssertFalse(self.app.buttons[@"sound-rain"].exists);

    XCUIElement *timer=self.app.popUpButtons[@"sleep-timer"];
    [timer click];
    [self.app.menuItems[@"15 minutes"] click];
    XCUIElement *timerStatus=self.app.staticTexts[@"timer-status"];
    NSPredicate *running=[NSPredicate predicateWithFormat:@"value CONTAINS 'remaining'"];
    [self expectationForPredicate:running evaluatedWithObject:timerStatus handler:nil];
    [self waitForExpectationsWithTimeout:2 handler:nil];

    [timer click];
    [self.app.menuItems[@"Cancel timer"] click];
}

- (void)testMasterVolumeAndPresetSheetAreAccessible {
    XCUIElement *master=self.app.sliders[@"master-volume"];
    XCTAssertTrue([master waitForExistenceWithTimeout:2]);
    [master adjustToNormalizedSliderPosition:.4];

    [self.app.buttons[@"save-preset"] click];
    XCUIElement *sheet=self.app.sheets.firstMatch;
    XCTAssertTrue([sheet waitForExistenceWithTimeout:2]);
    XCUIElement *name=sheet.textFields.firstMatch;
    [name typeText:@"UI Test Preset"];
    [sheet.buttons[@"Save"] click];
    XCTAssertFalse([sheet waitForExistenceWithTimeout:1]);
}
@end
