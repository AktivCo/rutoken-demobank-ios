//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@class Token;

@interface TokenInfoLoader : NSObject {
	CK_FUNCTION_LIST_PTR _functions;
	CK_FUNCTION_LIST_EXTENDED_PTR _extendedFunctions;
    void (^ _tokenInfoLoaded)(CK_SLOT_ID, Token*);
    void (^ _tokenInfoLoadingFailed)(CK_SLOT_ID);
}

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
tokenInfoLoadedCallback:(void(^)(CK_SLOT_ID, Token*)) tokenInfoLoadedCallback
tokenInfoLoadingFailedCallback:(void(^)(CK_SLOT_ID)) tokenInfoLoadingFailedCallback;

-(void)loadTokenInfoFromSlot:(CK_SLOT_ID)slotId;

@end

