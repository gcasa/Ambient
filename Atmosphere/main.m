#import <Cocoa/Cocoa.h>
#import "ATAppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        ATAppDelegate *delegate = [ATAppDelegate new];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];
        NSMenuItem *applicationMenuItem = [[NSMenuItem alloc] initWithTitle:@"Atmosphere" action:nil keyEquivalent:@""];
        [mainMenu addItem:applicationMenuItem];

        NSMenu *applicationMenu = [[NSMenu alloc] initWithTitle:@"Atmosphere"];
        NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"About Atmosphere"
                                                          action:@selector(orderFrontStandardAboutPanel:)
                                                   keyEquivalent:@""];
        aboutItem.target = app;
        [applicationMenu addItem:aboutItem];
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
