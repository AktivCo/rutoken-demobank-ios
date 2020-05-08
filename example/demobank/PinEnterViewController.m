// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <openssl/cms.h>

#import "PinEnterViewController.h"

#import "TokenManager.h"
#import "Token.h"
#import "PaymentsTableViewController.h"

#import "MBProgressHUD.h"

#import <RtPcsc/rtnfc.h>

@interface PinEnterViewController ()

@property (nonatomic)  MBProgressHUD * hud;

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
    
    TokenManager* tokenManager = [TokenManager sharedInstance];
    
    Token* token =[tokenManager tokenForHandle:_activeTokenHandle];
    NSArray* certs = [token certificates];
    if(0 == [certs count]){
        [_pinErrorLabel setHidden:NO];
        [_pinErrorLabel setText:@"На токене нет сертификатов"];
        [_loginButton setHidden:YES];
        [_pinTextInput setHidden:YES];
    } else {
        NSString* storedPin = [token getStoredPin];
        if(storedPin) [_pinTextInput setText:storedPin];
    }
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
    self.hud.animationType = MBProgressHUDAnimationZoomIn;
    self.hud.dimBackground = YES;
    self.hud.minSize = CGSizeMake(150.f, 150.f);
    [self.view addSubview:self.hud];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard
{
    [_pinTextInput resignFirstResponder];
}

- (IBAction)_loginToken:(id)sender {
    [_loginButton setEnabled:NO];
    [self dismissKeyboard];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    TokenManager* tokenManager = [TokenManager sharedInstance];
    
    Token* token =[tokenManager tokenForHandle:_activeTokenHandle];
    
    NSString* authString = @"Auth Me";
    NSData* authData = [NSData dataWithBytes:[authString UTF8String] length:[authString length]];
    
    self.hud.labelText = @"Проверяю PIN-код токена...";
    self.hud.mode = MBProgressHUDModeIndeterminate;
    [self.hud show:YES];
    NSString *pin = [_pinTextInput text];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        Token* activeToken = token;
        if ([token type] == TokenTypeNFC) {
            [tokenManager waitForActiveNFCToken:^(NSError* e){ NSLog(@"%@", e.description); }];
            Token *activeNFCToken = [tokenManager activeNFCToken];
            
            if ([[token serialNumber] isEqualToString:[activeNFCToken serialNumber]]) {
                activeToken = [tokenManager activeNFCToken];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    self.hud.labelText = @"Произошла ошибка";
                    self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
                    self.hud.mode = MBProgressHUDModeCustomView;
                    [self.hud hide:YES afterDelay:1.5];
                    
                    [self->_pinTextInput setText:@""];
                    [self->_pinErrorLabel setHidden:NO];
                    [self->_pinErrorLabel setText:@"Поднесите выбранный ранее токен"];
                    [self->_loginButton setEnabled:YES];
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    if ([activeNFCToken type] == TokenTypeNFC) {
                        [activeNFCToken closeSession];
                        stopNFC();
                    }
                });
                return;
            }
        }
        
        [activeToken loginWithPin:pin
                  successCallback:^(void) {
            self.hud.labelText = @"Выполняю вход в ЛК...";
            [activeToken signData:authData withCertificate:self.choosenCert successCallback:^(NSValue* cms) {
                self.hud.labelText = @"Вход выполнен";
                self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-checkmark.png"]];
                self.hud.mode = MBProgressHUDModeCustomView;
                [self.hud hide:YES afterDelay:1.5];

                CMS_ContentInfo_free([cms pointerValue]);

                [activeToken savePin:[self->_pinTextInput text]];
                
                [self->_loginButton setEnabled:YES];
                [self->_pinErrorLabel setHidden:YES];
                [self->_pinErrorLabel setText:@""];
                [self->_pinTextInput setText:@""];
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];

                [self performSegueWithIdentifier:@"toPayments" sender:self];
                if ([activeToken type] == TokenTypeNFC) {
                    [activeToken closeSession];
                    stopNFC();
                }
            } errorCallback:^(NSError * e) {
                self.hud.labelText = @"Произошла ошибка";
                self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
                self.hud.mode = MBProgressHUDModeCustomView;
                [self.hud hide:YES afterDelay:1.5];
                
                [self->_pinTextInput setText:@""];
                [self->_pinErrorLabel setHidden:NO];
                [self->_pinErrorLabel setText:@"Что-то не так с сертификатом"];
                [self->_loginButton setEnabled:YES];
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                if ([activeToken type] == TokenTypeNFC) {
                    [activeToken closeSession];
                    stopNFC();
                }
            }];
        } errorCallback:^(NSError * e) {
            self.hud.labelText = @"Произошла ошибка";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];
            
            [self->_pinTextInput setText:@""];
            [self->_pinErrorLabel setHidden:NO];
            [self->_pinErrorLabel setText:@"ПИН введен неверно"];
            [self->_loginButton setEnabled:YES];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            if ([activeToken type] == TokenTypeNFC) {
                [activeToken closeSession];
                stopNFC();
            }
        }];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"toPayments"]){
        PaymentsTableViewController* vc = [segue destinationViewController];
        [vc setActiveTokenHandle:_activeTokenHandle];
        [vc setChoosenCert:_choosenCert];
    }
}


@end
