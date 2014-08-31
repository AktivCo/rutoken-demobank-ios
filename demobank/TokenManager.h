//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

#import "Token.h"

@class Pkcs11EventHandler;
@class TokenInfoLoader;

typedef NS_ENUM(NSInteger, InnerState) {
	kState1,
	kState2,
	kState3,
	kState4,
	kState5,
	kState6
} ;

@interface TokenManager : NSObject {
	CK_FUNCTION_LIST_PTR _functions;
	CK_FUNCTION_LIST_EXTENDED_PTR _extendedFunctions;
	Pkcs11EventHandler* _pkcs11EventHandler;
    TokenInfoLoader* _tokenInfoLoader;
    NSInteger _currentHandle;
	NSMutableDictionary* _tokens;
    NSMutableDictionary* _handles;
	NSMutableDictionary* _slotStates;
	NSMutableDictionary* _slotWorkers;
}

+(TokenManager*)sharedInstance;

-(void)start;
-(void)stop;
-(NSArray*)tokenHandles;
-(Token*)tokenForHandle:(NSNumber*)tokenId;
@end
