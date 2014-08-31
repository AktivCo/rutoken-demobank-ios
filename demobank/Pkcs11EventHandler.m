//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "Pkcs11EventHandler.h"

#import "Pkcs11Error.h"

@implementation Pkcs11EventHandler

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
     tokenAddedCallback:(void (^)(CK_SLOT_ID))tokenAddedCallback
   tokenRemovedCallback:(void (^)(CK_SLOT_ID))tokenRemovedCallback {
	self = [super init];
	if (self) {
		_functions = functions;
		_extendedFunctions = extendedFunctions;
        _tokenAddedCallback = tokenAddedCallback;
        _tokenRemovedCallback = tokenRemovedCallback;
	}
	return self;
}

- (void)handleEventWithSlotId:(CK_SLOT_ID)slotId {
	CK_SLOT_INFO slotInfo;
	CK_RV rv = _functions->C_GetSlotInfo(slotId, &slotInfo);
	if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
    
	NSNumber* lastEvent = [_lastSlotEvent objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	if(nil == lastEvent){
		lastEvent = [NSNumber numberWithInteger:EventTypeTokenRemoved];
	}
	
	if (CKF_TOKEN_PRESENT & slotInfo.flags) {
		if (EventTypeTokenAdded == [lastEvent integerValue]){
			dispatch_async(dispatch_get_main_queue(), ^(){
                _tokenRemovedCallback(slotId);
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^(){
			_tokenAddedCallback(slotId);
		});
		[_lastSlotEvent setObject:[NSNumber numberWithInteger:EventTypeTokenAdded] forKey:[NSNumber numberWithUnsignedLong:slotId]];
	} else  if (EventTypeTokenAdded == [lastEvent integerValue]){
		dispatch_async(dispatch_get_main_queue(), ^(){
			_tokenRemovedCallback(slotId);
		});
		[_lastSlotEvent setObject:[NSNumber numberWithInteger:EventTypeTokenRemoved] forKey:[NSNumber numberWithUnsignedLong:slotId]];
	}
}

- (void)main {
	@autoreleasepool {
		@try {
			CK_RV rv = _functions->C_Initialize(NULL_PTR);
			if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
			
			CK_ULONG slotCount;
			rv = _functions->C_GetSlotList(CK_FALSE, NULL_PTR, &slotCount);
			if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
			
			NSMutableData* slotIdData = [NSMutableData dataWithLength:slotCount * sizeof(CK_SLOT_ID)];
			const CK_SLOT_ID* slotIds = [slotIdData bytes];
			rv = _functions->C_GetSlotList(CK_TRUE, [slotIdData mutableBytes], &slotCount);
			if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
			
			_lastSlotEvent = [NSMutableDictionary dictionary];
			
			for (size_t i = 0; i != slotCount; ++i) {
				[self handleEventWithSlotId:slotIds[i]];
			}
			
		} @catch (NSError* e) {
			//handle error
		}
	}
	
	while (TRUE) {
		CK_SLOT_ID slotId;
		CK_ULONG rv = _functions->C_WaitForSlotEvent(0, &slotId, NULL_PTR);
		if (CKR_CRYPTOKI_NOT_INITIALIZED == rv) return;
		@autoreleasepool {
			@try {
				if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
				[self handleEventWithSlotId:slotId];
			} @catch (NSError* e) {
				//handle error
				return;
			}
		}
	}
}

@end
