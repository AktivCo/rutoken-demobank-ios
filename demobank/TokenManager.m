//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "TokenManager.h"

#import "Pkcs11Error.h"
#import "Pkcs11EventHandler.h"

#import <RtPcsc/winscard.h>

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
		                                      extendedFunctions:_extendedFunctions
                                                         tokenAddedCallback:^(CK_SLOT_ID slotId){
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
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
                                                                     TokenInfoLoader* loader = [[TokenInfoLoader alloc] initWithFunctions:_functions
                                                                                                                        extendedFunctions:_extendedFunctions slotId:slotId];
                                                                     [loader start];
                                                                     [_slotWorkers setObject:loader forKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                                 }
                                                                     break;
                                                                 case kState3:
                                                                     nextState = kState6;
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
                                                                     break;
                                                                 case kState4:
                                                                 {
                                                                     nextState = kState2;
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
                                                                     TokenInfoLoader* loader = [[TokenInfoLoader alloc] initWithFunctions:_functions
                                                                                                                        extendedFunctions:_extendedFunctions slotId:slotId];
                                                                     [loader start];
                                                                     [_slotWorkers setObject:loader forKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                                 }
                                                                     break;
                                                                 case kState5:
                                                                 {
                                                                     nextState = kState2;
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
                                                                     TokenInfoLoader* loader = [[TokenInfoLoader alloc] initWithFunctions:_functions
                                                                                                                        extendedFunctions:_extendedFunctions slotId:slotId];
                                                                     [loader start];
                                                                     [_slotWorkers setObject:loader forKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                                 }
                                                                     break;
                                                                     
                                                                 default:
                                                                     nextState = currentState;
                                                                     break;
                                                             }
                                                             [_slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                         }tokenRemovedCallback:^(CK_SLOT_ID slotId) {
                                                             NSNumber* state = [_slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                             if(nil == state) {
                                                                 return; //Dont handle this situation
                                                             }
                                                             
                                                             InnerState currentState = [state integerValue];
                                                             InnerState nextState;
                                                             
                                                             switch (currentState) {
                                                                 case kState2:
                                                                     nextState = kState3;
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self];
                                                                     break;
                                                                 case kState4:
                                                                 {
                                                                     NSNumber* handleToRemove = [_handles objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                                     if(handleToRemove) {
                                                                         [_tokens removeObjectForKey:handleToRemove];
                                                                         [_handles removeObjectForKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                                         
                                                                         NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
                                                                         [notificationInfo setObject:handleToRemove forKey:@"handle"];
                                                                         
                                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWasRemoved" object:self userInfo:notificationInfo];
                                                                         nextState = kState1;
                                                                     }
                                                                 }
                                                                     break;
                                                                 case kState5:
                                                                     nextState = kState1;
                                                                     break;
                                                                 case kState6:
                                                                     nextState = kState3;
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self];
                                                                     break;
                                                                     
                                                                 default:
                                                                     nextState = currentState;
                                                                     break;
                                                             }
                                                             [_slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
                                                         }];
	}
	_slotStates = [NSMutableDictionary dictionary];
	_tokens = [NSMutableDictionary dictionary];
    _handles = [NSMutableDictionary dictionary];
	_slotWorkers = [NSMutableDictionary dictionary];
    _currentHandle = 0;
	
	return self;
}

-(void)start{
	[_pkcs11EventHandler start];
}

-(void)stop{
	//Stop all activities for monitoring tokens' events
}

-(NSArray*)tokenHandles{
	return[_tokens allKeys];
}

-(Token*)tokenForHandle:(NSNumber*)tokenId{
	return [_tokens objectForKey:tokenId];
}

-(void)proccessEventTokenInfoLoadedAtSlot:(CK_SLOT_ID)slotId withToken:(Token*)token{
	NSNumber* state = [_slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	if(nil == state) {
		return; //Dont handle this situation
	}
	
	InnerState currentState = [state integerValue];
	InnerState nextState;
	
	switch (currentState) {
		case kState2:
		{
			nextState = kState4;
            [_handles setObject:[NSNumber numberWithInteger:_currentHandle] forKey:[NSNumber numberWithUnsignedLong:slotId]];
			[_tokens setObject:token forKey:[NSNumber numberWithInteger:_currentHandle]];
            NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
            [notificationInfo setObject:[NSNumber numberWithInteger:_currentHandle] forKey:@"handle"];
            _currentHandle++;
            
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWasAdded" object:self userInfo:notificationInfo];
		}
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
	NSNumber* state = [_slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
	if(nil == state) {
		return; //Dont handle this situation
	}
	
	InnerState currentState = [state integerValue];
	InnerState nextState;
	
	switch (currentState) {
		case kState2:
			nextState = kState5;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self];
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
