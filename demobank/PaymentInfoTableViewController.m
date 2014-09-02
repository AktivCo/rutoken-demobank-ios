//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "PaymentInfoTableViewController.h"

#include "Token.h"
#include "TokenManager.h"
#include "Certificate.h"

#import "SignViewController.h"

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
//        TokenManager* tokenManager = [TokenManager sharedInstance];
//        Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
//        Certificate* cert = [[token certificates] objectAtIndex:0];
//        
//        NSString* paymentString = @"Payment";
//        NSData* paymentData = [NSData dataWithBytes:[paymentString UTF8String] length:[paymentString length]];
//        
//        [token sign:cert data:paymentData successCallback:^(NSData* result){
//            [self performSegueWithIdentifier:@"SignOK" sender:self];
//            [[self navigationController] popViewControllerAnimated:NO];
//            
//        }errorCallback:^(NSError* e){
//            
//        }];
        
        [self performSegueWithIdentifier:@"SignOK" sender:self];
        [[self navigationController] popViewControllerAnimated:NO];
    }
        
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"SignOK"]){
        SignViewController* vc = [segue destinationViewController];
        [vc setActiveTokenHandle:_activeTokenHandle];
        [vc setAskPin:NO];
    }
}



@end
