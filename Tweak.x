#import "src/menu.h"
#import "src/FloatingSwitch.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

static MenuViewController *_menuVC = nil;

static void toggleMenu(BOOL show) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (show) {
            if (!_menuVC) _menuVC = [[MenuViewController alloc] init];
            [_menuVC showMenuAnimated:YES];
        } else {
            [_menuVC dismissMenuAnimated:YES];
        }
    });
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        // Load APIKey.dylib at runtime — no static linker reference needed.
        // The dylib hides all ObjC symbols so we resolve everything via the runtime.
        dlopen("/var/jb/usr/lib/APIKey.dylib", RTLD_LAZY | RTLD_GLOBAL);

        Class cls = NSClassFromString(@"APIClient");
        if (!cls) return;

        // +sharedAPIClient
        id client = ((id (*)(Class, SEL))objc_msgSend)(cls, @selector(sharedAPIClient));
        if (!client) return;

        // -setToken:
        ((void (*)(id, SEL, NSString *))objc_msgSend)(client, @selector(setToken:),
            @"YkSXOtvqlVQy/9oPcI7bv8KzcPGuWbBAJo4zPV8oSeyNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=");

        // -setLanguage:
        ((void (*)(id, SEL, NSString *))objc_msgSend)(client, @selector(setLanguage:), @"en");

        // -hideUI:  (suppress the login/enter-key UI)
        ((void (*)(id, SEL, BOOL))objc_msgSend)(client, @selector(hideUI:), YES);

        // -silentMode:
        ((void (*)(id, SEL, BOOL))objc_msgSend)(client, @selector(silentMode:), YES);

        // -paid:  callback fires only when the licence is valid
        void (^paidBlock)(void) = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                FloatingSwitch *fs = [FloatingSwitch shared];
                fs.onToggle = ^(BOOL isOn) { toggleMenu(isOn); };
                [fs show];
            });
        };
        ((void (*)(id, SEL, void (^)(void)))objc_msgSend)(client, @selector(paid:), paidBlock);
    });
}
