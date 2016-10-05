// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import "FirstScreenViewController.h"

#import "TokenManager.h"
#import "Token.h"
#import "PinEnterViewController.h"
#import "Certificate.h"

static NSString* bluetoothOffMessage = @"Для работы приложения \nнеобходимо включить bluetooth";
static NSString* waitingForAnyTokenMessage = @"Для входа в демобанк \nподключите токен";
static NSString* waitingForSpecificTokenMessage = @"Для входа в демобанк \nподключите токен";
static NSString* noCertsOnTokenMessage = @"На токене отсутствуют сертифкаты";

@interface FirstScreenViewController () {
	
}
@property (weak, nonatomic) IBOutlet UIImageView *_backgroundImageView;
@end

@implementation FirstScreenViewController

- (void)viewDidLoad {
	[super viewDidLoad];
		
    _tokenManager = [TokenManager sharedInstance];
    _activeTokenHandle = nil;
    [self hideAllUCs];
}

-(void)setState:(FirstVCState)state withUserInfo:(NSDictionary*)userInfo {
	[self hideAllUCs];
	switch (state) {
		case FirstVCStateBlueToothPoweredOff:
			[_statusInfoLabel setText:bluetoothOffMessage];
			[_statusInfoLabel setHidden:NO];
			break;
			
		case FirstVCStateTokenPresent:
		{
			_activeTokenHandle = [userInfo objectForKey:@"tokenHandle"];
			if( nil == _activeTokenHandle) {
				[self setState:FirstVCStateWaitingForAnyToken withUserInfo:nil];
				break;
			}
			
			Token* token = [_tokenManager tokenForHandle:_activeTokenHandle];
			NSString* tokenLabel;
			if([[token model] isEqualToString:@"Rutoken ECP BT"]) tokenLabel = @"Рутокен ЭЦП Bluetooth";
			else tokenLabel = @"Рутокен";
			
			uint decSerial;
			[[NSScanner scannerWithString:[token serialNumber]] scanHexInt:&decSerial];
			NSString* decSerialString = [NSString stringWithFormat:@"0%lu", (unsigned long)decSerial];
			tokenLabel = [NSString stringWithFormat:@"%@ %@", tokenLabel, [decSerialString substringFromIndex:[decSerialString length] -5]];
			[_tokenModelLabel setText:tokenLabel];
			[_tokenModelLabel setHidden:NO];
			
			NSArray* certs = [token certificates];
			if(0 != [certs count]){
				Certificate* cert = [certs objectAtIndex:0];
				[_chooseCertButton setTitle:cert.cn forState:UIControlStateNormal];
				[_chooseCertButton setHidden:NO];
			} else {
				[_statusInfoLabel setText:noCertsOnTokenMessage];
				[_statusInfoLabel setHidden:NO];
			}
			
			if(YES == [token charging]) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_charge.png"]];
			else if ([token charge] > 80) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_4_sec.png"]];
			else if ([token charge] <= 80 && [token charge] > 60 ) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_3_sec.png"]];
			else if ([token charge] <= 60 && [token charge] > 40) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_2_sec.png"]];
			else if ([token charge] <= 40 && [token charge] > 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_1_sec.png"]];
			else if ([token charge] <= 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_empty.png"]];
			
			[_batteryPercentageLabel setText:[NSString stringWithFormat:@"%lu%%" ,(unsigned long)[token charge]]];
			
			[_batteryChargeImage setHidden:NO];
			[_batteryPercentageLabel setHidden:NO];
			
			if(TokenColorBlack == token.color) [self._backgroundImageView setImage:[UIImage imageNamed:@"ipad_black_background.png"]];
			if(TokenColorWhite == token.color) [self._backgroundImageView setImage:[UIImage imageNamed:@"ipad_white_background.png"]];
		}
			break;
			
		case FirstVCStateWaitingForAnyToken:
			_activeTokenHandle = nil;
			[_statusInfoLabel setText:waitingForAnyTokenMessage];
			[_statusInfoLabel setHidden:NO];
			[self._backgroundImageView setImage:[UIImage imageNamed:@"ipad_grey_background.png"]];
			break;
			
		case FirstVCStateWaitingForSpecificToken:
			_activeTokenHandle = nil;
			[_statusInfoLabel setText:waitingForSpecificTokenMessage];
			[_statusInfoLabel setHidden:NO];
			[self._backgroundImageView setImage:[UIImage imageNamed:@"ipad_grey_background.png"]];
			break;
			
		default:
			break;
	}
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

-(void)prepareForSettingAktiveToken{
    [self hideAllUCs];
}

-(void)hideAllUCs{
    [_tokenModelLabel setHidden:YES];
    [_statusInfoLabel setHidden:YES];
    [_batteryChargeImage setHidden:YES];
    [_chooseCertButton setHidden:YES];
    [_batteryPercentageLabel setHidden:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PinEnterViewController* vc = [segue destinationViewController];
    [vc setActiveTokenHandle:_activeTokenHandle];
}

@end
