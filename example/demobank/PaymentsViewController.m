// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import "PaymentsViewController.h"

#import "PaymentsTableViewController.h"

#import "TokenManager.h"
#import "Token.h"

@implementation PaymentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"embeddedSegue"]){
        PaymentsTableViewController* vc = [segue destinationViewController];
        [vc setActiveTokenHandle:_activeTokenHandle];
    }
}


@end
