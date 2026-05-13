#import "src/menu.h"
#import "API/APIClient.h"

static void showMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        MenuViewController *menu = [[MenuViewController alloc] init];
        [menu showMenuAnimated:YES];
    });
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        apiclient_set_token("YkSXOtvqlVQy/9oPcI7bv8KzcPGuWbBAJo4zPV8oSeyNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=");
        apiclient_set_language("en");
        apiclient_hide_ui(false);
        apiclient_silent_mode(false);

        apiclient_paid(^{
            showMenu();
        });
    });
}
