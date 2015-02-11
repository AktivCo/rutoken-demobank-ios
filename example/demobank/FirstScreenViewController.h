// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <UIKit/UIKit.h>

@class TokenManager;

typedef NS_ENUM(NSInteger, FirstVCState) {
	FirstVCStateBlueToothPoweredOff,
	FirstVCStateWaitingForSpecificToken,
	FirstVCStateWaitingForAnyToken,
	FirstVCStateTokenPresent
};

@interface FirstScreenViewController : UIViewController{
    NSNumber* _activeTokenHandle;
    TokenManager* _tokenManager;
    
    __weak IBOutlet UILabel *_tokenModelLabel;
    __weak IBOutlet UILabel *_statusInfoLabel;
    __weak IBOutlet UIImageView *_batteryChargeImage;
    __weak IBOutlet UILabel *_batteryPercentageLabel;
    __weak IBOutlet UIButton *_chooseCertButton;
}
-(void)setState:(FirstVCState)state withUserInfo:(NSDictionary*)userInfo;
-(void)prepareForSettingAktiveToken;

@end
