//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "TokenInfoLoader.h"

#import "Pkcs11Error.h"
#import "Token.h"

@implementation TokenInfoLoader

-(void)loadTokenInfoFromSlot:(CK_SLOT_ID)slotId withTokenInfoLoadedCallback:(void(^)(CK_SLOT_ID, Token*)) tokenInfoLoadedCallback
tokenInfoLoadingFailedCallback:(void(^)(CK_SLOT_ID)) tokenInfoLoadingFailedCallback {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
			Token* token = [[Token alloc] initWithSlotId:slotId];
		
				dispatch_async(dispatch_get_main_queue(), ^{
					if(nil != token) tokenInfoLoadedCallback(slotId, token);
					else tokenInfoLoadingFailedCallback(slotId);
				});
	});
}

@end

