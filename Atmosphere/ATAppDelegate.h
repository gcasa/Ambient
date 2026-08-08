#import <Cocoa/Cocoa.h>
@interface ATAppDelegate : NSObject <NSApplicationDelegate, NSSearchFieldDelegate>
- (void)showInfoPanel:(id)sender;
- (void)showPreferences:(id)sender;
@end
