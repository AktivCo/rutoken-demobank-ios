// Copyright (c) 2015, CJSC Aktiv-Soft. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@interface Pkcs11EventHandler : NSObject

- (void)startMonitoringWithTokenAddedCallback:(void (^)(CK_SLOT_ID))tokenAddedCallback
						 tokenRemovedCallback:(void (^)(CK_SLOT_ID))tokenRemovedCallback
								errorCallback:(void(^)(NSError*))errorCallback;
- (void)stopMonitoring;

@end
