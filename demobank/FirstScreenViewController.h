//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@class TokenManager;

@interface FirstScreenViewController : UIViewController{
    NSNumber* _activeTokenHandle;
    TokenManager* _tokenManager;
    
    __weak IBOutlet UIImageView *_tokenImage;
    __weak IBOutlet UILabel *_tokenModelLabel;
    __weak IBOutlet UILabel *_statusInfoLabel;
    __weak IBOutlet UIImageView *_batteryChargeImage;
    __weak IBOutlet UILabel *_batteryPercentageLabel;
    __weak IBOutlet UIButton *_chooseCertButton;
}

-(void)setActiveTokenWithHandle:(NSNumber*) handle;
-(void)removeActiveToken;
-(void)prepareForSettingAktiveToken;
-(void)bluetoothWasPoweredOff;

@end
