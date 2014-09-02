//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "PaymentsTableViewController.h"

#import "PaymentInfoTableViewController.h"

@implementation PaymentsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"paymentInfo"]){
        PaymentInfoTableViewController* vc = [segue destinationViewController];
        [vc setActiveTokenHandle:_activeTokenHandle];
    }
}


@end
