#import "src/menu.h"
#import "src/FloatingSwitch.h"
#import "API/APIClient.h"

static MenuViewController *_menuVC = nil;

static void toggleMenu(BOOL show) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (show) {
            if (!_menuVC) {
                _menuVC = [[MenuViewController alloc] init];
            }
            [_menuVC showMenuAnimated:YES];
        } else {
            [_menuVC dismissMenuAnimated:YES];
        }
    });
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        apiclient_set_token("YkSXOtvqlVQy/9oPcI7bv8KzcPGuWbBAJo4zPV8oSeyNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=");
        apiclient_set_language("en");

        // Hide API's own UI so it doesn't conflict with our overlay window
        apiclient_hide_ui(true);
        apiclient_silent_mode(true);

        // apiclient_paid only calls the callback if the license is valid
        apiclient_paid(^{
            dispatch_async(dispatch_get_main_queue(), ^{
                FloatingSwitch *fs = [FloatingSwitch shared];
                fs.onToggle = ^(BOOL isOn) {
                    toggleMenu(isOn);
                };
                [fs show];
            });
        });
    });
}
