//
//  NavigationController.h
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright (c) 2020, Aktiv-Soft JSC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBCentralManager;

@class BluetoothDelegate;
@class TokenManager;

typedef NS_ENUM(NSInteger, TokenState) {
    kTokenDisconnected,
    kTokenConnecting,
    kTokenConnected
};

@interface NavigationController : UINavigationController {
    BluetoothDelegate* _delegate;
    CBCentralManager* _manager;
    TokenManager* _tokenManager;
    NSNumber* _activeTokenHandle;
    TokenState _tokenState;
    NSUInteger _connectingTokens;
}
@end

