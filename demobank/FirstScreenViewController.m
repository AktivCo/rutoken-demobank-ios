//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "FirstScreenViewController.h"

#import "TokenManager.h"

@implementation FirstScreenViewController

- (void)viewDidLoad {
	[super viewDidLoad];
		
    _tokenManager = [TokenManager sharedInstance];
    _activeTokenHandle = nil;
    [self resetView];
}

-(void)setActiveTokenWithHandle:(NSNumber *)handle{
    _activeTokenHandle = handle;
    [self resetView];
    
    Token* token = [_tokenManager tokenForHandle:_activeTokenHandle];
    NSString* tokenLabel;
    if([[token model] isEqualToString:@"Rutoken ECP BT"]) tokenLabel = @"Рутокен ЭЦП Bluetooth";
    else tokenLabel = @"Рутокен";
    
    NSUInteger decSerial;
    [[NSScanner scannerWithString:[token serialNumber]] scanHexInt:&decSerial];
    NSString* decSerialString = [NSString stringWithFormat:@"0%u", decSerial];
    tokenLabel = [NSString stringWithFormat:@"%@ %@", tokenLabel, [decSerialString substringFromIndex:[decSerialString length] -5]];
    [_tokenModelLabel setText:tokenLabel];
    [_commonNameLabel setText:@"Иванов Иван Иванович"];
    [_loginButton setHidden:NO];
    [_loginButton setTitle:@"Войти" forState:UIControlStateNormal];
    [_pinTextInput setHidden:NO];
    
    if(YES == [token charging]) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_charge.png"]];
    else if ([token charge] > 80) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_4_sec.png"]];
    else if ([token charge] <= 80 && [token charge] > 60 ) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_3_sec.png"]];
    else if ([token charge] <= 60 && [token charge] > 40) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_2_sec.png"]];
    else if ([token charge] <= 40 && [token charge] > 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_1_sec.png"]];
    else if ([token charge] <= 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_empty.png"]];
    
    [_batteryPercentageLabel setText:[NSString stringWithFormat:@"%u%%" ,(NSUInteger)[token charge]]];
}

-(void)removeActiveToken{
    _activeTokenHandle = nil;
    [self resetView];
    [_statusInfoLabel setText:@"Для работы с демобанком подключите токен"];
}

-(void)prepareForSettingAktiveToken{
    [self resetView];
    [_statusInfoLabel setText:@"Токен подключается..."];
}

-(void)bluetoothWasPoweredOff{
    [self resetView];
    [_statusInfoLabel setText:@"Для работы с демобанком включите bluetooth"];
}

- (IBAction)loginToken:(id)sender {
    [_loginButton setEnabled:NO];
    Token* token =[_tokenManager tokenForHandle:_activeTokenHandle];
    Certificate* cert = [[token certificates] objectAtIndex:0];
    
    NSString* authString = @"Auth Me";
    NSData* authData = [NSData dataWithBytes:[authString UTF8String] length:[authString length]];
    
    if(nil != token && nil != cert){
        [token login:[_pinTextInput text] successCallback:^(void){
            [token sign:cert data:authData successCallback:^(NSData * result) {
                [_loginButton setEnabled:YES];
                [_pinIncorrectLabel setHidden:YES];
                [_pinTextInput setText:@""];
            } errorCallback:^(NSError * e) {
                [_pinTextInput setText:@""];
                [_pinIncorrectLabel setHidden:NO];
                [_pinIncorrectLabel setText:@"Что-то не так с сертификатом"];
                [_loginButton setEnabled:YES];
            }];
        } errorCallback:^(NSError * e) {
            [_pinTextInput setText:@""];
            [_pinIncorrectLabel setHidden:NO];
            [_pinIncorrectLabel setText:@"ПИН введен неверно"];
            [_loginButton setEnabled:YES];
        }];
    }
}

-(void)resetView{
    [_tokenModelLabel setText:@""];
    [_statusInfoLabel setText:@""];
    [_commonNameLabel setText:@""];
    [_batteryChargeImage setImage:nil];
    [_loginButton setHidden:YES];
    [_loginButton setTitle:@"" forState:UIControlStateNormal];
    [_pinTextInput setHidden:YES];
    [_pinIncorrectLabel setHidden:YES];
    [_batteryPercentageLabel setText:@""];
}

@end
