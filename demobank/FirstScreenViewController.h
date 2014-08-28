//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@class CBCentralManager;

@class BluetoothDelegate;
@class TokenManager;

typedef NS_ENUM(NSInteger, TokenState) {
	kTokenDisconnected,
	kTokenConnecting,
	kTokenConnected
};

@interface FirstScreenViewController : UIViewController{
	BluetoothDelegate* _delegate;
	CBCentralManager* _manager;
	TokenManager* _tokenManager;
    NSNumber* _activeTokenHandle;
    TokenState _tokenState;
    NSUInteger _connectingTokens;
    
    __weak IBOutlet UIImageView *_headerImage;
    __weak IBOutlet UIImageView *_tokenImage;
    __weak IBOutlet UILabel *_tokenModelLabel;
    __weak IBOutlet UILabel *_tokenSerialNumberLabel;
    __weak IBOutlet UILabel *_statusInfoLabel;
    __weak IBOutlet UILabel *_commonNameLabel;
    __weak IBOutlet UIButton *_loginButton;
    __weak IBOutlet UIImageView *_batteryChargeImage;
    __weak IBOutlet UILabel *_pinTextInputLabel;
    __weak IBOutlet UITextField *_pinTextInput;
}
@end
