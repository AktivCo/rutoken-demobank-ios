//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@class Certificate;

@interface Token : NSObject {
	CK_FUNCTION_LIST_PTR _functions;
	CK_FUNCTION_LIST_EXTENDED_PTR _extendedFunctions;
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

-(id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
	 extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
				slotId:(CK_SLOT_ID)slotId;

-(void)login:(NSString*)pin successCallback:(void (^)())successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)logoutWithSuccessCallback:(void (^)())successCallback errorCallback:(void (^)(NSError*))errorCallback;

-(void)sign:(Certificate*)certificate data:(NSData*)data successCallback:(void (^)(NSData*))successCallback
        errorCallback:(void (^)(NSError*))errorCallback;

@end

