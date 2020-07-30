// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.
#import "Pkcs11EventHandler.h"

#import "Pkcs11Error.h"

typedef NS_ENUM(NSInteger, EventType) {
	EventTypeTokenAdded,
	EventTypeTokenRemoved
};

@interface Pkcs11EventHandler ()

@property(nonatomic) NSMutableDictionary* lastSlotEvent;
@property(nonatomic) CK_FUNCTION_LIST_PTR functions;

@end

@implementation Pkcs11EventHandler

-(id)init{
	self = [super init];
	if(self){
        @try{
            _lastSlotEvent = [NSMutableDictionary dictionary];
            CK_RV rv =  C_GetFunctionList(&_functions);
            if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
        } @catch (NSError* e) {
            return nil;
        }
	}
    

	return self;
}

- (void)handleEventWithSlotId:(CK_SLOT_ID)slotId
		   tokenAddedCallback:(void (^)(CK_SLOT_ID))tokenAddedCallback
		 tokenRemovedCallback:(void (^)(CK_SLOT_ID))tokenRemovedCallback
                errorCallback:(void (^)(NSError *))errorCallback {
    @try{
        CK_SLOT_INFO slotInfo;
        CK_RV rv = [self functions]->C_GetSlotInfo(slotId, &slotInfo);
        if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
        
        NSNumber* lastEvent = [self.lastSlotEvent objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
        if(nil == lastEvent){
            lastEvent = [NSNumber numberWithInteger:EventTypeTokenRemoved];
        }
        
        if (CKF_TOKEN_PRESENT & slotInfo.flags) {
            if (EventTypeTokenAdded == [lastEvent integerValue]){
                dispatch_async(dispatch_get_main_queue(), ^(){
                    tokenRemovedCallback(slotId);
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^(){
                tokenAddedCallback(slotId);
            });
            [self.lastSlotEvent setObject:[NSNumber numberWithInteger:EventTypeTokenAdded] forKey:[NSNumber numberWithUnsignedLong:slotId]];
        } else  if (EventTypeTokenAdded == [lastEvent integerValue]){
            dispatch_async(dispatch_get_main_queue(), ^(){
                tokenRemovedCallback(slotId);
            });
            [self.lastSlotEvent setObject:[NSNumber numberWithInteger:EventTypeTokenRemoved] forKey:[NSNumber numberWithUnsignedLong:slotId]];
        }
    } @catch (NSError* e) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            errorCallback(e);
        });
    }
}

- (void)startMonitoringWithTokenAddedCallback:(void (^)(CK_SLOT_ID))tokenAddedCallback
						 tokenRemovedCallback:(void (^)(CK_SLOT_ID))tokenRemovedCallback
								errorCallback:(void (^)(NSError *))errorCallback{

	dispatch_queue_t queue = dispatch_queue_create("ru.rutoken.demobank.pkcs11eventhandler", nil);
	dispatch_async(queue, ^() {
		@try {
			CK_C_INITIALIZE_ARGS args = {};
			args.flags = CKF_OS_LOCKING_OK;

			CK_RV rv = [self functions]->C_Initialize(&args);
			if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
			
			CK_ULONG slotCount;
			rv = [self functions]->C_GetSlotList(CK_FALSE, NULL_PTR, &slotCount);
			if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
			
			NSMutableData* slotIdData = [NSMutableData dataWithLength:slotCount * sizeof(CK_SLOT_ID)];
			const CK_SLOT_ID* slotIds = [slotIdData bytes];
			rv = [self functions]->C_GetSlotList(CK_TRUE, [slotIdData mutableBytes], &slotCount);
			if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
			
			for (size_t i = 0; i != slotCount; ++i) {
				[self handleEventWithSlotId:slotIds[i] tokenAddedCallback:tokenAddedCallback tokenRemovedCallback:tokenRemovedCallback errorCallback:errorCallback];
			}
			
			while (YES) {
				CK_SLOT_ID slotId;
				CK_ULONG rv = [self functions]->C_WaitForSlotEvent(0, &slotId, NULL_PTR);
				if (CKR_CRYPTOKI_NOT_INITIALIZED == rv) return;
				
				if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
				[self handleEventWithSlotId:slotId tokenAddedCallback:tokenAddedCallback tokenRemovedCallback:tokenRemovedCallback errorCallback:errorCallback];
			}
		} @catch (NSError* e) {
			dispatch_async(dispatch_get_main_queue(), ^(){
				errorCallback(e);
			});
		}
	});
}

- (void)stopMonitoring{
		[self.lastSlotEvent removeAllObjects];
	
		CK_RV rv = [self functions]->C_Finalize(NULL_PTR);
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
}

@end
