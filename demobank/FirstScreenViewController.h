//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@class CBCentralManager;

@class BluetoothDelegate;
@class TokenManager;

@interface FirstScreenViewController : UIViewController{
	BluetoothDelegate* _delegate;
	CBCentralManager* _manager;
	TokenManager* _tokenManager;
	__weak IBOutlet UITextView *_textLogs;
}
@end
