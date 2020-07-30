// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <rtpkcs11ecp/rtpkcs11.h>

@class Token;

@interface TokenInfoLoader : NSObject

-(void)loadTokenInfoFromSlot:(CK_SLOT_ID)slotId withTokenInfoLoadedCallback:(void(^)(CK_SLOT_ID, Token*)) tokenInfoLoadedCallback
tokenInfoLoadingFailedCallback:(void(^)(CK_SLOT_ID)) tokenInfoLoadingFailedCallback;

@end

