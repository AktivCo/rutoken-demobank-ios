//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@interface Pkcs11EventHandler : NSObject

- (void)startMonitoringWithTokenAddedCallback:(void (^)(CK_SLOT_ID))tokenAddedCallback
						 tokenRemovedCallback:(void (^)(CK_SLOT_ID))tokenRemovedCallback;
- (void)stopMonitoring;

@end
