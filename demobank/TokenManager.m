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
	if(nil == lastEvent){
		lastEvent = [NSNumber numberWithInteger:TR];
	}
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
		[_lastSlotEvent setObject:[NSNumber numberWithInteger:TA] forKey:[NSNumber numberWithUnsignedLong:slotId]];
	} else  if (TA == [lastEvent integerValue]){
		dispatch_async(dispatch_get_main_queue(), ^{
			[tokenManager proccessEventTokenRemovedAtSlot:slotId];
		});
		[_lastSlotEvent setObject:[NSNumber numberWithInteger:TR] forKey:[NSNumber numberWithUnsignedLong:slotId]];
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

- (id)init {
	self = [super init];
	
	if (self) {
		CK_ULONG rv = C_GetFunctionList(&_functions);
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		
		rv = C_EX_GetFunctionListExtended(&_extendedFunctions);
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		
		_pkcs11EventHandler = [[Pkcs11EventHandler alloc] initWithFunctions:_functions
		                                      extendedFunctions:_extendedFunctions];
	}
	_slotStates = [NSMutableDictionary dictionary];
	_tokens = [NSMutableDictionary dictionary];
	_slotWorkers = [NSMutableDictionary dictionary];
	
	return self;
}

-(void)start{
	[_pkcs11EventHandler start];
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
	NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[notificationInfo setObject:[NSNumber numberWithUnsignedLong:slotId] forKey:@"slotId"];
	
	NSNumber* state = [_slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	InnerState currentState = kState1;
	if(nil == state) {
		[_slotStates setObject:[NSNumber numberWithInteger:kState1] forKey:[NSNumber numberWithUnsignedLong:slotId]];
	} else {
		currentState = [state integerValue];
	}
	
	InnerState nextState;
	switch (currentState) {
		case kState1:
		{
			nextState = kState2;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self userInfo:notificationInfo];
			TokenInfoLoader* loader = [[TokenInfoLoader alloc] initWithFunctions:_functions
															   extendedFunctions:_extendedFunctions slotId:slotId];
			[loader start];
			[_slotWorkers setObject:loader forKey:[NSNumber numberWithUnsignedLong:slotId]];
		}
			break;
		case kState3:
			nextState = kState6;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self userInfo:notificationInfo];
			break;
		case kState4:
			nextState = kState2;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self userInfo:notificationInfo];
			break;
		case kState5:
			nextState = kState2;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self userInfo:notificationInfo];
			break;
			
		default:
			nextState = currentState;
			break;
	}
	[_slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
}
-(void)proccessEventTokenRemovedAtSlot:(CK_SLOT_ID)slotId{
	NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[notificationInfo setObject:[NSNumber numberWithUnsignedLong:slotId] forKey:@"slotId"];
	
	NSNumber* state = [_slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	if(nil == state) {
		return; //Dont handle this situation
	}
	
	InnerState currentState = [state integerValue];
	InnerState nextState;
	
	switch (currentState) {
		case kState2:
			nextState = kState3;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self userInfo:notificationInfo];
			break;
		case kState4:
			nextState = kState1;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWasRemoved" object:self userInfo:notificationInfo];
			break;
		case kState5:
			nextState = kState1;
			break;
		case kState6:
			nextState = kState3;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self userInfo:notificationInfo];
			break;
			
		default:
			nextState = currentState;
			break;
	}
	[_slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
}

-(void)proccessEventTokenInfoLoadedAtSlot:(CK_SLOT_ID)slotId withToken:(Token*)token{
	NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[notificationInfo setObject:[NSNumber numberWithUnsignedLong:slotId] forKey:@"slotId"];
	
	NSNumber* state = [_slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	if(nil == state) {
		return; //Dont handle this situation
	}
	
	InnerState currentState = [state integerValue];
	InnerState nextState;
	
	switch (currentState) {
		case kState2:
			nextState = kState4;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWasAdded" object:self userInfo:notificationInfo];
			break;
		case kState3:
			nextState = kState4;
			break;
		case kState6:
		{
			TokenInfoLoader* loader = [[TokenInfoLoader alloc] initWithFunctions:_functions
															   extendedFunctions:_extendedFunctions slotId:slotId];
			[loader start];
			[_slotWorkers setObject:loader forKey:[NSNumber numberWithUnsignedLong:slotId]];
			nextState = kState2;
		}
			break;
			
		default:
			nextState = currentState;
			break;
	}
	[_slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
}
-(void)proccessEventTokenInfoLoadingFailedAtSlot:(CK_SLOT_ID)slotId{
	NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[notificationInfo setObject:[NSNumber numberWithUnsignedLong:slotId] forKey:@"slotId"];
	
	NSNumber* state = [_slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	if(nil == state) {
		return; //Dont handle this situation
	}
	
	InnerState currentState = [state integerValue];
	InnerState nextState;
	
	switch (currentState) {
		case kState2:
			nextState = kState5;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self userInfo:notificationInfo];
			break;
		case kState3:
			nextState = kState5;
			break;
		case kState6:
		{
			TokenInfoLoader* loader = [[TokenInfoLoader alloc] initWithFunctions:_functions
															   extendedFunctions:_extendedFunctions slotId:slotId];
			[loader start];
			[_slotWorkers setObject:loader forKey:[NSNumber numberWithUnsignedLong:slotId]];
			nextState = kState2;
		}
			break;
			
		default:
			nextState = currentState;
			break;
	}
	[_slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
}

@end
