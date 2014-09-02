//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "PaymentsViewController.h"

#import "TokenManager.h"
#import "Token.h"

@implementation PaymentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(nil != _activeTokenHandle){
        TokenManager* tokenManager = [TokenManager sharedInstance];
        Token* token = [tokenManager tokenForHandle:_activeTokenHandle];
        
        NSString* tokenLabel = @"Рутоке";
        
        if([[token model] isEqualToString:@"Rutoken ECP BT"]) tokenLabel = @"Рутокен ЭЦП Bluetooth";
        
        [_tokenModelLabel setText:tokenLabel];
        
        NSUInteger decSerial;
        [[NSScanner scannerWithString:[token serialNumber]] scanHexInt:&decSerial];
        NSString* decSerialString = [NSString stringWithFormat:@"0%u", decSerial];
        [_tokenSerial setText:[decSerialString substringFromIndex:[decSerialString length] -5]];
        
        if(YES == [token charging]) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_charge.png"]];
        else if ([token charge] > 80) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_4_sec.png"]];
        else if ([token charge] <= 80 && [token charge] > 60 ) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_3_sec.png"]];
        else if ([token charge] <= 60 && [token charge] > 40) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_2_sec.png"]];
        else if ([token charge] <= 40 && [token charge] > 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_1_sec.png"]];
        else if ([token charge] <= 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_empty.png"]];
        
        [_batteryPercentageLabel setText:[NSString stringWithFormat:@"%u%%" ,(NSUInteger)[token charge]]];
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
