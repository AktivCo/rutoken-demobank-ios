// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import "PaymentInfoTableViewController.h"

#include "Token.h"
#include "TokenManager.h"
#include "Certificate.h"

#import "MBProgressHUD.h"

@interface PaymentInfoTableViewController ()

@property (nonatomic)  MBProgressHUD * hud;

@end

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
        if([[_costLabel text] integerValue] >= 50000) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Подтверждение перевода" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Перевести" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSString *pin = [((UITextField *)[[alert textFields] objectAtIndex:0]) text];
                self.hud.labelText = @"Проверяю PIN-код...";
                [self.hud show:YES];
             
                TokenManager* tokenManager = [TokenManager sharedInstance];
                Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
                [token logoutWithSuccessCallback:^(void){}
                                   errorCallback:^(NSError* e){}];
                
                [token loginWithPin:pin successCallback:^(void){
                    [self  sign];
                } errorCallback:^(NSError * e) {
                    self.hud.labelText = @"Ошибка!";
                    self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
                    self.hud.mode = MBProgressHUDModeCustomView;
                    [self.hud hide:YES afterDelay:1.5];
                }];
            }]];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Введите PIN-код";
                textField.secureTextEntry = YES;
            }];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [self sign];
        }
    }
        
}

-(void)sign{
    if(_activeTokenHandle){
        TokenManager* tokenManager = [TokenManager sharedInstance];
        Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
        Certificate* cert = [[token certificates] objectAtIndex:0];
        
        self.hud.labelText = @"Подписываю...";
        [self.hud show:YES];
        
        NSString* paymentString = @"Payment";
        NSData* paymentData = [NSData dataWithBytes:[paymentString UTF8String] length:[paymentString length]];
        
        [token signData:paymentData withCertificate:cert successCallback:^(NSData* result){
            self.hud.labelText = @"Успешно!";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-checkmark.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];
        }errorCallback:^(NSError* e){
            self.hud.labelText = @"Ошибка!";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];
        }];
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    _hud.dimBackground = YES;
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.animationType = MBProgressHUDAnimationZoomIn;
    _hud.minSize = CGSizeMake(150.f, 150.f);
    [self.view addSubview:self.hud];
}

@end
