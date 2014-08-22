//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "TokenManager.h"

#import <RtPcsc/winscard.h>

static NSString* const gPkcs11ErrorDomain = @"ru.rutoken.demobank.pkcs11error";

@interface Pkcs11Error : NSError

+ (Pkcs11Error*)errorWithCode:(NSUInteger)code;

@end

@implementation Pkcs11Error

- (NSString*)localizedDescription {
	switch ([self code]) {
			//Put errors' decription here
		default:
			return @"Unknown error";
	}
}

+ (Pkcs11Error*)errorWithCode:(NSUInteger)code {
	return [[Pkcs11Error alloc] initWithDomain:gPkcs11ErrorDomain code:code userInfo:nil];
}

@end

@interface Pkcs11EventHandler : NSThread {
	CK_FUNCTION_LIST_PTR _functions;
	CK_FUNCTION_LIST_EXTENDED_PTR _extendedFunctions;
	NSMutableDictionary* _lastSlotEvent;
}
@end

@implementation Pkcs11EventHandler

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions {
	self = [super init];
	if (self) {
		_functions = functions;
		_extendedFunctions = extendedFunctions;
	}
	return self;
}

- (void)handleEventWithSlotId:(CK_SLOT_ID)slotId {
	CK_SLOT_INFO slotInfo;
	CK_RV rv = _functions->C_GetSlotInfo(slotId, &slotInfo);
	if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
	
	NSNumber* lastEvent = [_lastSlotEvent objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	TokenManager* tokenManager = [TokenManager sharedInstance];
	
	if (CKF_TOKEN_PRESENT & slotInfo.flags) {
		if (TA == [lastEvent integerValue]){
			dispatch_async(dispatch_get_main_queue(), ^{
				[tokenManager proccessEventTokenRemovedAtSlot:slotId];
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[tokenManager proccessEventTokenAddedAtSlot:slotId];
		});
	} else {
		if (TR == [lastEvent integerValue]){
			dispatch_async(dispatch_get_main_queue(), ^{
				[tokenManager proccessEventTokenAddedAtSlot:slotId];
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[tokenManager proccessEventTokenRemovedAtSlot:slotId];
		});
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
			
			_lastSlotEvent = [NSMutableDictionary dictionaryWithCapacity:slotCount];
			
			for (size_t i = 0; i != slotCount; ++i) {
				[_lastSlotEvent setObject:[NSNumber numberWithInteger:TR] forKey:[NSNumber numberWithUnsignedLong:slotIds[i]]];
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

@interface TokenInfoLoader : NSThread {
	CK_FUNCTION_LIST_PTR _functions;
	CK_FUNCTION_LIST_EXTENDED_PTR _extendedFunctions;
	CK_SLOT_ID _slotId;
}
@end

@implementation TokenInfoLoader

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
				 slotId:(CK_SLOT_ID)slotId{
	self = [super init];
	if (self) {
		_functions = functions;
		_extendedFunctions = extendedFunctions;
		_slotId = slotId;
	}
	return self;
}

- (void)main {
	@autoreleasepool {
		TokenManager* tokenManager = [TokenManager sharedInstance];
		@try {
			Token* token = [[Token alloc] initWithFunctions:_functions extendedFunctions:_extendedFunctions slotId:_slotId];
			dispatch_async(dispatch_get_main_queue(), ^{
				[tokenManager proccessEventTokenInfoLoadedAtSlot:_slotId withToken:token];
			});
			
		} @catch (NSError* e) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[tokenManager proccessEventTokenInfoLoadingFailedAtSlot:_slotId];
			});
		}
	}
}

@end

@implementation TokenManager

+(TokenManager*)sharedInstance{
	static dispatch_once_t runOnce;
	static id sharedObject = nil;
	dispatch_once(&runOnce, ^{
        sharedObject = [[self alloc] init];
    });
	
	return sharedObject;
}

-(void)start{
	//Start all activities for monitoring tokens' events
}

-(void)stop{
	//Stop all activities for monitoring tokens' events
}

-(NSArray*)serials{
	//Return serials for all know tokens
	return nil;
}
-(Token*)tokenForSerial:(NSString*)serial{
	//Return token for given serial
	return nil;
}

-(void)proccessEventTokenAddedAtSlot:(CK_SLOT_ID)slotId{
	//Proccess token adding here
}
-(void)proccessEventTokenRemovedAtSlot:(CK_SLOT_ID)slotId{
	//Proccess token removing here
}

-(void)proccessEventTokenInfoLoadedAtSlot:(CK_SLOT_ID)slotId withToken:(Token*)token{
	//Proccess successful token information loading
}
-(void)proccessEventTokenInfoLoadingFailedAtSlot:(CK_SLOT_ID)slotId{
	//Proccess failing of token information loading
}

@end
