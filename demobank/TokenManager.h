//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

#import "Token.h"

@class Pkcs11EventHandler;

typedef NS_ENUM(NSInteger, EventType) {
	TA, //Token added
	TR, //Token removed
	TIL, //Token's information loaded
	TILF //Token's information loading failed
};

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

-(void)proccessEventTokenAddedAtSlot:(CK_SLOT_ID)slotId;
-(void)proccessEventTokenRemovedAtSlot:(CK_SLOT_ID)slotId;
-(void)proccessEventTokenInfoLoadedAtSlot:(CK_SLOT_ID)slotId withToken:(Token*)token;
-(void)proccessEventTokenInfoLoadingFailedAtSlot:(CK_SLOT_ID)slotId;
@end
