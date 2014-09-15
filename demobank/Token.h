//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@class Certificate;

@interface Token : NSObject {
	CK_SLOT_ID _slotId;
    CK_SESSION_HANDLE _session;
}

@property(nonatomic, readonly) NSString* label;
@property(nonatomic, readonly) NSString* serialNumber;
@property(nonatomic, readonly) NSString* model;
@property(nonatomic, readonly) NSUInteger totalMemory;
@property(nonatomic, readonly) NSUInteger freeMemory;
@property(nonatomic, readonly) double charge;
@property(nonatomic, readonly) bool charging;
@property(nonatomic, readonly) NSMutableArray* certificates;

-(id)initWithSlotId:(CK_SLOT_ID)slotId;

-(void)loginWithPin:(NSString*)pin successCallback:(void (^)())successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)logoutWithSuccessCallback:(void (^)())successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)signData:(NSData*)data withCertificate:(Certificate*)certificate  successCallback:(void (^)(NSData*))successCallback
        errorCallback:(void (^)(NSError*))errorCallback;

@end

