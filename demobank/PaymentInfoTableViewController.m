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
        [vc setNavigation:[self navigationController]];
        if([[_costLabel text] integerValue] < 50000)[vc setAskPin:NO];
        else [vc setAskPin:YES];
    }
}



@end
