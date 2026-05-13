#import "src/menu.h"
#import "API/APIClient.h"

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        apiclient_set_token("YkSXOtvqlVQy/9oPcI7bv8KzcPGuWbBAJo4zPV8oSeyNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=");
        apiclient_set_language("en");

        apiclient_paid(^{
            MenuViewController *menu = [[MenuViewController alloc] init];
            [menu showMenuAnimated:YES];
        });
    });
}
