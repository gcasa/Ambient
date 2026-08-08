#import <Cocoa/Cocoa.h>
#import "ATAppDelegate.h"

// NSApplication's delegate reference is not owning. Keep the delegate alive for
// the lifetime of the process because status-menu items also target it.
static ATAppDelegate *ATApplicationDelegate;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        ATApplicationDelegate = [ATAppDelegate new];
        app.delegate = ATApplicationDelegate;
        BOOL hideDockIcon = [NSUserDefaults.standardUserDefaults boolForKey:@"ATHideDockIcon"];
        [app setActivationPolicy:hideDockIcon ? NSApplicationActivationPolicyAccessory : NSApplicationActivationPolicyRegular];

        NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];
        NSMenuItem *applicationMenuItem = [[NSMenuItem alloc] initWithTitle:@"Atmosphere" action:nil keyEquivalent:@""];
        [mainMenu addItem:applicationMenuItem];

        NSMenu *applicationMenu = [[NSMenu alloc] initWithTitle:@"Atmosphere"];
        NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"About Atmosphere"
                                                          action:@selector(showInfoPanel:)
                                                   keyEquivalent:@""];
        aboutItem.target = ATApplicationDelegate;
        [applicationMenu addItem:aboutItem];
        NSMenuItem *preferencesItem = [[NSMenuItem alloc] initWithTitle:@"Preferences…"
                                                                action:@selector(showPreferences:)
                                                         keyEquivalent:@","];
        preferencesItem.target = ATApplicationDelegate;
        [applicationMenu addItem:preferencesItem];
        [applicationMenu addItem:NSMenuItem.separatorItem];

        NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit Atmosphere"
                                                         action:@selector(terminate:)
                                                  keyEquivalent:@"q"];
        quitItem.target = app;
        [applicationMenu addItem:quitItem];
        applicationMenuItem.submenu = applicationMenu;
        app.mainMenu = mainMenu;

        [app run];
    }
    return 0;
}
