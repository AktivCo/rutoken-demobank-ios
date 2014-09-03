//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "FirstScreenViewController.h"

#import "TokenManager.h"
#import "Token.h"
#import "PinEnterViewController.h"
#import "Certificate.h"

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
	
	NSArray* certs = [token certificates];
	if(0 != [certs count]){
		Certificate* cert = [certs objectAtIndex:0];
		[_chooseCertButton setTitle:cert.cn forState:UIControlStateNormal];
		[_chooseCertButton setHidden:NO];
	} else {
		[_statusInfoLabel setText:@"На токене отсутствуют сертификаты"];
	}
    
    if(YES == [token charging]) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_charge.png"]];
    else if ([token charge] > 80) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_4_sec.png"]];
    else if ([token charge] <= 80 && [token charge] > 60 ) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_3_sec.png"]];
    else if ([token charge] <= 60 && [token charge] > 40) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_2_sec.png"]];
    else if ([token charge] <= 40 && [token charge] > 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_1_sec.png"]];
    else if ([token charge] <= 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_empty.png"]];
    
    [_batteryPercentageLabel setText:[NSString stringWithFormat:@"%u%%" ,(NSUInteger)[token charge]]];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(nil != _activeTokenHandle){
        Token* token = [_tokenManager tokenForHandle:_activeTokenHandle];
        if(nil != token){
            [token logoutWithSuccessCallback:^(void){} errorCallback:^(NSError * e){}];
        }
    }
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

//- (IBAction)loginToken:(id)sender {
//}

-(void)resetView{
    [_tokenModelLabel setText:@""];
    [_statusInfoLabel setText:@""];
    [_batteryChargeImage setImage:nil];
    [_chooseCertButton setHidden:YES];
    [_batteryPercentageLabel setText:@""];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PinEnterViewController* vc = [segue destinationViewController];
    [vc setActiveTokenHandle:_activeTokenHandle];
}

@end
