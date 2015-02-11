// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import "SignViewController.h"

#include "Token.h"
#include "TokenManager.h"
#include "Certificate.h"

@interface SignViewController ()

@end

@implementation SignViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)sign{
    if(_activeTokenHandle){
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [_progressIndicator startAnimating];
        TokenManager* tokenManager = [TokenManager sharedInstance];
        Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
        Certificate* cert = [[token certificates] objectAtIndex:0];
        
        NSString* paymentString = @"Payment";
        NSData* paymentData = [NSData dataWithBytes:[paymentString UTF8String] length:[paymentString length]];
        
        [token signData:paymentData withCertificate:cert successCallback:^(NSData* result){
            [_progressLabel setHidden:YES];
            [_successLabel setHidden:NO];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            [_progressIndicator stopAnimating];
        }errorCallback:^(NSError* e){
            [_progressLabel setHidden:YES];
            [_errorLabel setHidden:NO];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            [_progressIndicator stopAnimating];
        }];
        
    }
}

- (IBAction)_loginToken:(id)sender {
    [_loginButton setEnabled:NO];
    TokenManager* tokenManager = [TokenManager sharedInstance];
    Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
    [token logoutWithSuccessCallback:^(void){}
                       errorCallback:^(NSError* e){}];
    
    [token loginWithPin:[_pinTextInput text] successCallback:^(void){
        [_loginButton setEnabled:YES];
        [_pinTextInput setHidden:YES];
        [_loginButton setHidden:YES];
        [_pinIncorrect setHidden:YES];
        [_progressLabel setHidden:NO];
        [_welcomeLabel setHidden:YES];
        _loggedOff = NO;
        [self sign];
        } errorCallback:^(NSError * e) {
            [_pinTextInput setText:@""];
            [_pinIncorrect setHidden:NO];
            [_loginButton setEnabled:YES];
            _loggedOff = YES;
        }];
}

- (void)viewDidLoad
{
    _loggedOff = NO;
    [super viewDidLoad];
    [_pinIncorrect setHidden:YES];
    [_successLabel setHidden:YES];
    [_progressIndicator stopAnimating];
    [_progressLabel setHidden:YES];
    [_errorLabel setHidden:YES];
    [_welcomeLabel setHidden:NO];
    if(NO == _askPin){
        [_pinTextInput setHidden:YES];
        [_loginButton setHidden:YES];
        [_progressLabel setHidden:NO];
        [_welcomeLabel setHidden:YES];
        [self sign];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if(_loggedOff) [_navigation popToRootViewControllerAnimated:NO];
}

@end
