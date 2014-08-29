//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@class TokenManager;

@interface FirstScreenViewController : UIViewController{
    NSNumber* _activeTokenHandle;
    TokenManager* _tokenManager;
    
    __weak IBOutlet UIImageView *_headerImage;
    __weak IBOutlet UIImageView *_tokenImage;
    __weak IBOutlet UILabel *_tokenModelLabel;
    __weak IBOutlet UILabel *_statusInfoLabel;
    __weak IBOutlet UILabel *_commonNameLabel;
    __weak IBOutlet UIButton *_loginButton;
    __weak IBOutlet UIImageView *_batteryChargeImage;
    __weak IBOutlet UITextField *_pinTextInput;
    __weak IBOutlet UILabel *_pinIncorrectLabel;
    __weak IBOutlet UILabel *_batteryPercentageLabel;
}

-(void)setActiveTokenWithHandle:(NSNumber*) handle;
-(void)removeActiveToken;
-(void)prepareForSettingAktiveToken;
-(void)bluetoothWasPoweredOff;

@end
