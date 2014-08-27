//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@class CBCentralManager;

@class BluetoothDelegate;
@class TokenManager;

@interface FirstScreenViewController : UIViewController{
	BluetoothDelegate* _delegate;
	CBCentralManager* _manager;
	TokenManager* _tokenManager;
    NSNumber* _activeTokenHandle;
    __weak IBOutlet UIImageView *_headerImage;
    __weak IBOutlet UIImageView *_tokenImage;
    __weak IBOutlet UILabel *_tokenModelLabel;
    __weak IBOutlet UILabel *_tokenSerialNumberLabel;
    __weak IBOutlet UILabel *_statusInfoLabel;
}
@end
