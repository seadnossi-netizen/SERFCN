#import "src/menu.h"
#import "src/FloatingSwitch.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

static MenuViewController *_menuVC = nil;

static void toggleMenu(BOOL show) {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (show) {
                if (!_menuVC) _menuVC = [[MenuViewController alloc] init];
                [_menuVC showMenuAnimated:YES];
            } else {
                [_menuVC dismissMenuAnimated:YES];
            }
        } @catch (NSException *e) { /* swallow */ }
    });
}

static void launchAPI(void) {
    // Try both rootless paths for APIKey.dylib
    const char *paths[] = {
        "/var/jb/usr/lib/APIKey.dylib",
        "/var/jb/Library/Frameworks/APIKey.dylib",
        "/usr/lib/APIKey.dylib",
        NULL
    };
    void *handle = NULL;
    for (int i = 0; paths[i] != NULL; i++) {
        handle = dlopen(paths[i], RTLD_LAZY | RTLD_GLOBAL);
        if (handle) break;
    }

    // Get APIClient class — registered by ObjC runtime when dylib loads
    Class cls = NSClassFromString(@"APIClient");
    if (!cls) return;

    id client = ((id (*)(Class, SEL))objc_msgSend)(cls, @selector(sharedAPIClient));
    if (!client) return;

    // Configure
    ((void (*)(id, SEL, NSString *))objc_msgSend)(client, @selector(setToken:),
        @"YkSXOtvqlVQy/9oPcI7bv8KzcPGuWbBAJo4zPV8oSeyNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=");
    ((void (*)(id, SEL, NSString *))objc_msgSend)(client, @selector(setLanguage:), @"en");
    ((void (*)(id, SEL, BOOL))objc_msgSend)(client, @selector(hideUI:), YES);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(client, @selector(silentMode:), YES);

    // paid: block — pass as id to avoid ARC/block ABI mismatch
    __block BOOL fired = NO;
    void (^paidBlock)(void) = ^{
        if (fired) return;
        fired = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                FloatingSwitch *fs = [FloatingSwitch shared];
                if (!fs) return;
                if (!fs.onToggle) {
                    fs.onToggle = ^(BOOL isOn) { toggleMenu(isOn); };
                }
                [fs show];
            } @catch (NSException *e) { /* swallow */ }
        });
    };
    ((void (*)(id, SEL, id))objc_msgSend)(client, @selector(paid:), paidBlock);
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        @try {
            launchAPI();
        } @catch (NSException *e) { /* swallow */ }
    });
}
