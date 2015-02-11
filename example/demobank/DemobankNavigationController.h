// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

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
