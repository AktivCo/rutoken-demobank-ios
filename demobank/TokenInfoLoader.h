//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@class Token;

@interface TokenInfoLoader : NSObject

- (id)initWithTokenInfoLoadedCallback:(void(^)(CK_SLOT_ID, Token*)) tokenInfoLoadedCallback
tokenInfoLoadingFailedCallback:(void(^)(CK_SLOT_ID)) tokenInfoLoadingFailedCallback;

-(void)loadTokenInfoFromSlot:(CK_SLOT_ID)slotId;

@end

