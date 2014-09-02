//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "PinEnterViewController.h"

#import "TokenManager.h"
#import "PaymentsViewController.h"

@interface PinEnterViewController ()

@end

@implementation PinEnterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_pinErrorLabel setHidden:YES];
}

- (IBAction)_loginToken:(id)sender {
    [_loginButton setEnabled:NO];
    TokenManager* tokenManager = [TokenManager sharedInstance];
    
    Token* token =[tokenManager tokenForHandle:_activeTokenHandle];
    Certificate* cert = [[token certificates] objectAtIndex:0];
    
    NSString* authString = @"Auth Me";
    NSData* authData = [NSData dataWithBytes:[authString UTF8String] length:[authString length]];
    
    if(nil != token && nil != cert){
        [token login:[_pinTextInput text] successCallback:^(void){
            [token sign:cert data:authData successCallback:^(NSData * result) {
                [_loginButton setEnabled:YES];
                [_pinErrorLabel setHidden:YES];
                [_pinErrorLabel setText:@""];
                [_pinTextInput setText:@""];
                PaymentsViewController* vc =[[UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil] instantiateViewControllerWithIdentifier:@"PaymentsVC"];
                [vc setActiveTokenHandle:_activeTokenHandle];
                NSMutableArray *vcs = [[self.navigationController viewControllers] mutableCopy];
                NSUInteger lastVcIndex = [vcs count] - 1;
                if (lastVcIndex > 0) {
                    [vcs replaceObjectAtIndex:lastVcIndex withObject:vc];
                    [self.navigationController setViewControllers:vcs animated:YES];
                }
                //[self performSegueWithIdentifier:@"segueToPayments" sender:self];
            } errorCallback:^(NSError * e) {
                [_pinTextInput setText:@""];
                [_pinErrorLabel setHidden:NO];
                [_pinErrorLabel setText:@"Что-то не так с сертификатом"];
                [_loginButton setEnabled:YES];
            }];
        } errorCallback:^(NSError * e) {
            [_pinTextInput setText:@""];
            [_pinErrorLabel setHidden:NO];
            [_pinErrorLabel setText:@"ПИН введен неверно"];
            [_loginButton setEnabled:YES];
        }];
    }    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
