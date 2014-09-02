//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "PaymentInfoTableViewController.h"

#include "Token.h"
#include "TokenManager.h"
#include "Certificate.h"

@implementation PaymentInfoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}
- (IBAction)signAndSend:(id)sender {
    if(nil != _activeTokenHandle){
        TokenManager* tokenManager = [TokenManager sharedInstance];
        Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
        Certificate* cert = [[token certificates] objectAtIndex:0];
        
        NSString* paymentString = @"Payment";
        NSData* paymentData = [NSData dataWithBytes:[paymentString UTF8String] length:[paymentString length]];
        
        [token sign:cert data:paymentData successCallback:^(NSData* result){
            
        }errorCallback:^(NSError* e){
            
        }];
    }
        
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}


@end
