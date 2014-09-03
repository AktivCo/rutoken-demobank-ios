//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "TokenManager.h"

#import "TokenInfoLoader.h"
#import "Pkcs11Error.h"
#import "Pkcs11EventHandler.h"

#import <RtPcsc/winscard.h>

@interface TokenManager ()

@property (nonatomic, readwrite) Pkcs11EventHandler* pkcs11EventHandler;
@property (nonatomic, readwrite) TokenInfoLoader* tokenInfoLoader;
@property (nonatomic, readwrite) NSInteger currentHandle;
@property (nonatomic, readwrite) NSMutableDictionary* tokens;
@property (nonatomic, readwrite) NSMutableDictionary* handles;
@property (nonatomic, readwrite) NSMutableDictionary* slotStates;

typedef NS_ENUM(NSInteger, InnerState) {
	InnerStateReadyAfterRemoved,
	InnerStateWaitingAfterAdded,
	InnerStateCancelingAfterRemoved,
	InnerStateReadyAfterLoaded,
	InnerStateReadyAfterFailed,
	InnerStateCancelingAfterAdded
};

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
		CK_FUNCTION_LIST_PTR functions;
		CK_FUNCTION_LIST_EXTENDED_PTR extendedFunctions;
		
		CK_ULONG rv = C_GetFunctionList(&functions);
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		
		rv = C_EX_GetFunctionListExtended(&extendedFunctions);
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		
		self.pkcs11EventHandler = [[Pkcs11EventHandler alloc] initWithFunctions:functions extendedFunctions:extendedFunctions
								   tokenAddedCallback:^(CK_SLOT_ID slotId){
									   NSNumber* state = [self.slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
									   InnerState currentState = InnerStateReadyAfterRemoved;
									   if(nil == state) {
										   [self.slotStates setObject:[NSNumber numberWithInteger:InnerStateReadyAfterRemoved] forKey:[NSNumber numberWithUnsignedLong:slotId]];
									   } else {
										   currentState = [state integerValue];
									   }

									   InnerState nextState;
									   switch (currentState) {
										   case InnerStateReadyAfterRemoved:{
											   nextState = InnerStateWaitingAfterAdded;
											   [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
											   [self.tokenInfoLoader loadTokenInfoFromSlot:slotId];
										   }
											   break;
										   case InnerStateCancelingAfterRemoved:
											   nextState = InnerStateCancelingAfterAdded;
											   [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
											   break;
										   case InnerStateReadyAfterLoaded:{
											   nextState = InnerStateWaitingAfterAdded;
											   [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
											   [self.tokenInfoLoader loadTokenInfoFromSlot:slotId];
										   }
											   break;
										   case InnerStateReadyAfterFailed:{
											   nextState = InnerStateWaitingAfterAdded;
											   [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
											   [self.tokenInfoLoader loadTokenInfoFromSlot:slotId];
										   }
											   break;
										 
										   default:
											   nextState = currentState;
											   break;
									   }
									   [self.slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
								   }tokenRemovedCallback:^(CK_SLOT_ID slotId){

									   NSNumber* state = [self.slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
									   if(nil == state) {
									  	   return; //Dont handle this situation
									   }
									 
									   InnerState currentState = [state integerValue];
									   InnerState nextState;
									 
									   switch (currentState) {
										   case InnerStateWaitingAfterAdded:
											   nextState = InnerStateCancelingAfterRemoved;
											   [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self];
											   break;
										   case InnerStateReadyAfterLoaded:
										   {
											   NSNumber* handleToRemove = [self.handles objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
											   if(handleToRemove) {
												   [self.tokens removeObjectForKey:handleToRemove];
												   [self.handles removeObjectForKey:[NSNumber numberWithUnsignedLong:slotId]];
												 
												   NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
												   [notificationInfo setObject:handleToRemove forKey:@"handle"];
												 
												   [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWasRemoved" object:self userInfo:notificationInfo];
												   nextState = InnerStateReadyAfterRemoved;
											   }
										   }
											   break;
										   case InnerStateReadyAfterFailed:
											   nextState = InnerStateReadyAfterRemoved;
											   break;
										   case InnerStateCancelingAfterAdded:
											   nextState = InnerStateCancelingAfterRemoved;
											   [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self];
											   break;
											 
										   default:
											   nextState = currentState;
											   break;
									   }
									   [self.slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
								   }];
		
        self.tokenInfoLoader = [[TokenInfoLoader alloc] initWithFunctions:functions extendedFunctions:extendedFunctions tokenInfoLoadedCallback:^(CK_SLOT_ID slotId, Token* token){
            NSNumber* state = [self.slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
            if(nil == state) {
                return; //Dont handle this situation
            }
            
            InnerState currentState = [state integerValue];
            InnerState nextState;
            
            switch (currentState) {
                case InnerStateWaitingAfterAdded:
                {
                    nextState = InnerStateReadyAfterLoaded;
                    [self.handles setObject:[NSNumber numberWithInteger:self.currentHandle] forKey:[NSNumber numberWithUnsignedLong:slotId]];
                    [self.tokens setObject:token forKey:[NSNumber numberWithInteger:self.currentHandle]];
                    NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
                    [notificationInfo setObject:[NSNumber numberWithInteger:self.currentHandle] forKey:@"handle"];
                    self.currentHandle++;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWasAdded" object:self userInfo:notificationInfo];
                }
                    break;
                case InnerStateCancelingAfterRemoved:
                    nextState = InnerStateReadyAfterLoaded;
                    break;
                case InnerStateCancelingAfterAdded:
                {
                    [self.tokenInfoLoader loadTokenInfoFromSlot:slotId];
                }
                    break;
                    
                default:
                    nextState = currentState;
                    break;
            }
            [self.slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
            
        } tokenInfoLoadingFailedCallback:^(CK_SLOT_ID slotId) {
            NSNumber* state = [self.slotStates objectForKey:[NSNumber numberWithUnsignedLong:slotId]];
            if(nil == state) {
                return; //Dont handle this situation
            }
            
            InnerState currentState = [state integerValue];
            InnerState nextState;
            
            switch (currentState) {
                case InnerStateWaitingAfterAdded:
                    nextState = InnerStateReadyAfterFailed;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenAddingFailed" object:self];
                    break;
                case InnerStateCancelingAfterRemoved:
                    nextState = InnerStateReadyAfterFailed;
                    break;
                case InnerStateCancelingAfterAdded:
                {
                    [self.tokenInfoLoader loadTokenInfoFromSlot:slotId];
                    nextState = InnerStateWaitingAfterAdded;
                }
                    break;
                    
                default:
                    nextState = currentState;
                    break;
            }
            [self.slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
            
        }];
	}
	self.slotStates = [NSMutableDictionary dictionary];
	self.tokens = [NSMutableDictionary dictionary];
    self.handles = [NSMutableDictionary dictionary];
    self.currentHandle = 0;
	
	return self;
}

-(void)start{
	[self.pkcs11EventHandler start];
}

-(void)stop{
	//Stop all activities for monitoring tokens' events
}

-(NSArray*)tokenHandles{
	return[self.tokens allKeys];
}

-(Token*)tokenForHandle:(NSNumber*)tokenId{
	return [self.tokens objectForKey:tokenId];
}

@end
