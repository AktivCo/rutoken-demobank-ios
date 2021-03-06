// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <rtpkcs11ecp/rtpkcs11.h>

@class Certificate;

typedef NS_ENUM(NSInteger, TokenColor) {
    TokenColorBlack,
    TokenColorWhite
};

typedef NS_ENUM(NSInteger, TokenType) {
    TokenTypeNFC,
    TokenTypeBT
};

@interface Token : NSObject {
    CK_SLOT_ID _slotId;
    CK_SESSION_HANDLE _session;
}

@property(nonatomic, readonly) NSString* label;
@property(nonatomic, readonly) NSString* serialNumber;
@property(nonatomic, readonly) NSString* model;
@property(nonatomic, readonly) NSUInteger totalMemory;
@property(nonatomic, readonly) NSUInteger freeMemory;
@property(nonatomic, readonly) TokenType type;

@property(nonatomic, readonly) TokenColor color;
@property(nonatomic, readonly) double charge;
@property(nonatomic, readonly) bool charging;
@property(nonatomic, readonly) NSMutableArray* certificates;
@property(nonatomic, readonly) bool isLocked;


-(id)initWithSlotId:(CK_SLOT_ID)slotId;

-(void)closeSession;

-(void)activateSmWithPassword:(NSString*)password successCallback:(void (^)(void))successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)readCertificatesWithSuccessCallback:(void (^)(void))successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)loginWithPin:(NSString*)pin successCallback:(void (^)(void))successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)logoutWithSuccessCallback:(void (^)(void))successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)signData:(NSData*)data withCertificate:(Certificate*)certificate  successCallback:(void (^)(NSValue*))successCallback
        errorCallback:(void (^)(NSError*))errorCallback;

-(NSString*)getStoredPin;
-(void)savePin:(NSString*) pin;

@end

