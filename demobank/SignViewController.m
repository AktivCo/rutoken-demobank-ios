//
//  SignViewController.m
//  demobank
//
//  Created by Андрей Трифонов on 02.09.14.
//  Copyright (c) 2014 Aktiv Co. All rights reserved.
//

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
        
        [token sign:cert data:paymentData successCallback:^(NSData* result){
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
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_pinIncorrect setHidden:YES];
    [_successLabel setHidden:YES];
    [_progressIndicator stopAnimating];
    [_progressLabel setHidden:YES];
    [_errorLabel setHidden:YES];
    if(NO == _askPin){
        [_pinLabel setHidden:YES];
        [_pinTextInput setHidden:YES];
        [_loginButton setHidden:YES];
        [_progressLabel setHidden:NO];
        [self sign];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
