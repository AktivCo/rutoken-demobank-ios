//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@class CBCentralManager;

@class BluetoothDelegate;

@interface FirstScreenViewController : UIViewController{
	BluetoothDelegate* _delegate;
	CBCentralManager* _manager;
	__weak IBOutlet UILabel* _blueToothState;
}
@end
