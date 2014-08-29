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

@interface DemobankNavigationController : UINavigationController {
    BluetoothDelegate* _delegate;
	CBCentralManager* _manager;
	TokenManager* _tokenManager;
    NSNumber* _activeTokenHandle;
    TokenState _tokenState;
    NSUInteger _connectingTokens;
}

@end
