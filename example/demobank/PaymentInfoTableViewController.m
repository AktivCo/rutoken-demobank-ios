// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <openssl/cms.h>

#import "PaymentInfoTableViewController.h"

#import "PaymentsDB.h"

#include "Token.h"
#include "TokenManager.h"
#include "Certificate.h"

#import "MBProgressHUD.h"

@interface PaymentInfoTableViewController ()

@property (nonatomic)  MBProgressHUD * hud;
@property (nonatomic) NSArray* viewPayment;
@property (nonatomic) NSDictionary* payment;

@end

@implementation PaymentInfoTableViewController

- (IBAction)signAndSend:(id)sender {
    NSInteger sum = [_payment[@"Информация"][@"Сумма"] integerValue];
    NSData* paymentData = [self paymentToJson];

    if(nil != _activeTokenHandle){
        if(sum >= 50000) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Подтверждение перевода" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Перевести" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSString *pin = [((UITextField *)[[alert textFields] objectAtIndex:0]) text];
                self.hud.labelText = @"Проверяю PIN-код...";
                [self.hud show:YES];
             
                TokenManager* tokenManager = [TokenManager sharedInstance];
                Token* token = [tokenManager tokenForHandle:self.activeTokenHandle];
                [token logoutWithSuccessCallback:^(void){}
                                   errorCallback:^(NSError* e){}];
                
                [token loginWithPin:pin successCallback:^(void){
                    [self  signWithData:paymentData];
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
            [self signWithData:paymentData];
        }
    }
        
}

-(void)signWithData:(NSData*)paymentData {
    if(_activeTokenHandle){
        TokenManager* tokenManager = [TokenManager sharedInstance];
        Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
        Certificate* cert = [[token certificates] objectAtIndex:0];
        
        self.hud.labelText = @"Подписываю...";
        [self.hud show:YES];
        
        [token signData:paymentData withCertificate:cert successCallback:^(NSValue* cms){
            self.hud.labelText = @"Успешно!";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-checkmark.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];

            CMS_ContentInfo_free([cms pointerValue]);
        }errorCallback:^(NSError* e){
            self.hud.labelText = @"Ошибка!";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];
        }];
        
    }
}

- (NSData*)paymentToJson {
    return [NSJSONSerialization dataWithJSONObject:_payment options:0 error:NULL];
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

    PaymentsDB* paymentsDB = [PaymentsDB sharedInstance];
    _payment = [[paymentsDB getPayments] objectAtIndex:[_paymentNumber integerValue]];

    _viewPayment = @[
                     @{
                         @"header":@"Плательщик",
                         @"data":@[
                                 @"Наименование",
                                 @"ИНН",
                                 @"КПП",
                                 @"Счет",
                                 ],
                         },
                     @{
                         @"header":@"Банк плательщика",
                         @"data":@[
                                 @"Наименование",
                                 @"БИК",
                                 @"Счет",
                                 ],
                         },
                     @{
                         @"header":@"Получатель",
                         @"data":@[
                                 @"Наименование",
                                 @"ИНН",
                                 @"КПП",
                                 @"Счет",
                                 ],
                         },
                     @{
                         @"header":@"Банк получателя",
                         @"data":@[
                                 @"Наименование",
                                 @"БИК",
                                 @"Счет",
                                 ],
                         },
                     @{
                         @"header":@"Информация",
                         @"data":@[
                                 @"Сумма",
                                 @"Назначение",
                                 ],
                         },
                     ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_viewPayment count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_viewPayment[section][@"data"] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PaymentCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"PaymentCell"];
    }

    NSString* section = _viewPayment[[indexPath section]][@"header"];
    NSString* row = _viewPayment[[indexPath section]][@"data"][[indexPath row]];
    [cell.textLabel setText:row];
    [cell.detailTextLabel setText:_payment[section][row]];

    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _viewPayment[section][@"header"];
}

@end
