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

@interface TokenManager : NSObject

+(TokenManager*)sharedInstance;

-(void)start;
-(void)stop;
-(NSArray*)serials;
-(Token*)tokenForSerial:(NSString*)serial;
-(void)proccessEventTokenAddedAtSlot:(CK_SLOT_ID)slotId;
-(void)proccessEventTokenRemovedAtSlot:(CK_SLOT_ID)slotId;
-(void)proccessEventTokenInfoLoadedAtSlot:(CK_SLOT_ID)slotId withToken:(Token*)token;
-(void)proccessEventTokenInfoLoadingFailedAtSlot:(CK_SLOT_ID)slotId;
@end
