// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <openssl/cms.h>

#import "PaymentInfoTableViewController.h"

#import "PaymentsDB.h"

#include "Token.h"
#include "TokenManager.h"

#import <RtPcsc/rtnfc.h>

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
        TokenManager* tokenManager = [TokenManager sharedInstance];
        Token* token = [tokenManager tokenForHandle:self.activeTokenHandle];
        if(sum >= 50000 || [token type] == TokenTypeNFC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Подтверждение перевода"
                                                                           message:@"Введите ПИН-код для подтверждения перевода"
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"Введите PIN-код";
                textField.secureTextEntry = YES;
                NSString* storedPin = [[[TokenManager sharedInstance] tokenForHandle:self.activeTokenHandle] getStoredPin];
                if(storedPin) textField.text = storedPin;
            }];

            UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:@"Перевести" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSString *pin = [((UITextField *)[[alert textFields] objectAtIndex:0]) text];
                self.hud.labelText = @"Проверяю PIN-код...";
                self.hud.mode = MBProgressHUDModeIndeterminate;
                [self.hud show:YES];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
                    Token* activeToken = token;
                    if ([token type] == TokenTypeNFC) {
                        [tokenManager waitForActiveNFCToken:^(NSError* e){ NSLog(@"%@", e.description); }];
                        Token *activeNFCToken = [tokenManager activeNFCToken];
                        
                        if ([[token serialNumber] isEqualToString:[activeNFCToken serialNumber]]) {
                            activeToken = [tokenManager activeNFCToken];
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^() {
                                self.hud.labelText = @"Поднесите выбранный ранее токен!";
                                self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
                                self.hud.mode = MBProgressHUDModeCustomView;
                                [self.hud hide:YES afterDelay:3.5];
                                if ([activeNFCToken type] == TokenTypeNFC) {
                                    [activeNFCToken closeSession];
                                    stopNFC();
                                }
                            });
                            return;
                        }
                    }
                    if ([activeToken type] != TokenTypeNFC) {
                        [activeToken logoutWithSuccessCallback:^(void){}
                                                 errorCallback:^(NSError* e){}];
                    }
                    [activeToken loginWithPin:pin successCallback:^(void){
                        [self signWithData:paymentData token:activeToken];
                    } errorCallback:^(NSError * e) {
                        self.hud.labelText = @"Ошибка подписи!";
                        self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
                        self.hud.mode = MBProgressHUDModeCustomView;
                        [self.hud hide:YES afterDelay:1.5];
                        if ([activeToken type] == TokenTypeNFC) {
                            [activeToken closeSession];
                            stopNFC();
                        }
                    }];
                });
            }];
            [alert addAction:confirmAction];

            UIAlertAction* rejectAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:rejectAction];

            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [self signWithData:paymentData token:token];
        }
    }
        
}

-(void)signWithData:(NSData*)paymentData token:(Token*)token {
    if(_activeTokenHandle){
        self.hud.labelText = @"Подписываю...";
        [self.hud show:YES];
        
        [token signData:paymentData withCertificate:_choosenCert successCallback:^(NSValue* cms){
            self.hud.labelText = @"Успешно!";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-checkmark.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];

            CMS_ContentInfo_free([cms pointerValue]);

            if ([token type] == TokenTypeNFC) {
                [token closeSession];
                stopNFC();
            }
        }errorCallback:^(NSError* e){
            self.hud.labelText = @"Ошибка!";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];

            if ([token type] == TokenTypeNFC) {
                [token closeSession];
                stopNFC();
            }
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
