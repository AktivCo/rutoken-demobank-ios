// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import "TokenManager.h"

#import "ApplicationError.h"

#import "TokenInfoLoader.h"
#import "Token.h"
#import "Pkcs11Error.h"
#import "Pkcs11EventHandler.h"

#import <RtPcsc/winscard.h>
#import <RtPcsc/rtnfc.h>

#import <rtengine/engine.h>

@interface TokenManager ()

@property (nonatomic) ENGINE* rtEngine;

@property (nonatomic) Pkcs11EventHandler* pkcs11EventHandler;
@property (nonatomic) TokenInfoLoader* tokenInfoLoader;

@property (nonatomic) NSInteger currentHandle;
@property (nonatomic) NSMutableDictionary* tokens;
@property (nonatomic) NSMutableDictionary* handles;
@property (nonatomic) NSMutableDictionary* slotStates;
@property (nonatomic) NSConditionLock* NFCCondition;

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
    _NFCCondition = [[NSConditionLock alloc] init];

    int r = rt_eng_load_engine();
    if (r != 1) {
        NSLog(@"RtEngine initialization failed!");
        @throw [ApplicationError errorWithCode:UnrecoverableError];
    }

    _rtEngine = rt_eng_get0_engine();
    if (!_rtEngine) {
        NSLog(@"RtEngine retreiving failed!");
        @throw [ApplicationError errorWithCode:UnrecoverableError];
    }

    ENGINE_init(_rtEngine);
    ENGINE_set_default(_rtEngine, ENGINE_METHOD_ALL - ENGINE_METHOD_RAND);

	if (self) {
		_pkcs11EventHandler = [[Pkcs11EventHandler alloc] init];
        _tokenInfoLoader = [[TokenInfoLoader alloc] init];
		
		_slotStates = [NSMutableDictionary dictionary];
		_tokens = [NSMutableDictionary dictionary];
		_handles = [NSMutableDictionary dictionary];
		_currentHandle = 0;
	}
	return self;
}

-(void)dealloc {
    ENGINE_unregister_pkey_asn1_meths(_rtEngine);
    ENGINE_unregister_pkey_meths(_rtEngine);
    ENGINE_unregister_digests(_rtEngine);
    ENGINE_unregister_ciphers(_rtEngine);
    ENGINE_finish(rt_eng_get0_engine());

    rt_eng_unload_engine();
}

-(void)startMonitoring{
	[self.pkcs11EventHandler startMonitoringWithTokenAddedCallback: ^(CK_SLOT_ID slotId){
		[self processTokenWasAddedAtSlotId:slotId];
	} tokenRemovedCallback:^(CK_SLOT_ID slotId){
		[self processTokenWasRemovedAtSlotId:slotId];
	} errorCallback:^(NSError * e) {
		NSLog(@"Error in pkcs11EventHandler, reason: %ld (%@)", (long)[e code], [e localizedDescription]);
		@throw [ApplicationError errorWithCode:UnrecoverableError];
			  }];
}

-(void)stopMonitoring{
	@try{
		self.currentHandle = 0;
		[self.slotStates removeAllObjects];
		[self.tokens removeAllObjects];
		[self.handles removeAllObjects];
		
		[self.pkcs11EventHandler stopMonitoring];
	} @catch(NSError* e){
		NSLog(@"Failed to stop pkcs11EventHandler, reason: %ld (%@)", (long)[e code], [e localizedDescription]);
		@throw [ApplicationError errorWithCode:UnrecoverableError];
	}
}

-(NSArray*)tokenHandles {
	return [self.tokens allKeys];
}

-(NSInteger)tokenCount {
    return [self.tokens count];
}

-(Token*)tokenForHandle:(NSNumber*)tokenId {
	return [self.tokens objectForKey:tokenId];
}

-(void)processTokenWasAddedAtSlotId: (CK_SLOT_ID) slotId {
    @try {
        
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
                [self.tokenInfoLoader loadTokenInfoFromSlot:slotId withTokenInfoLoadedCallback:^(CK_SLOT_ID slotId, Token* token){
                    [self processTokenInfoLoadedAtSlotId:slotId withToken:token];
                } tokenInfoLoadingFailedCallback:^(CK_SLOT_ID slotId) {
                    [self processTokenInfoLoadingFailedAtSlotId: slotId];
                }];
            }
                break;
            case InnerStateCancelingAfterRemoved:
                nextState = InnerStateCancelingAfterAdded;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
                break;
            case InnerStateReadyAfterLoaded:{
                nextState = InnerStateWaitingAfterAdded;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
                [self.tokenInfoLoader loadTokenInfoFromSlot:slotId withTokenInfoLoadedCallback:^(CK_SLOT_ID slotId, Token* token){
                    [self processTokenInfoLoadedAtSlotId:slotId withToken:token];
                } tokenInfoLoadingFailedCallback:^(CK_SLOT_ID slotId) {
                    [self processTokenInfoLoadingFailedAtSlotId: slotId];
                }];
            }
                break;
            case InnerStateReadyAfterFailed:{
                nextState = InnerStateWaitingAfterAdded;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWillBeAdded" object:self];
                [self.tokenInfoLoader loadTokenInfoFromSlot:slotId withTokenInfoLoadedCallback:^(CK_SLOT_ID slotId, Token* token){
                    [self processTokenInfoLoadedAtSlotId:slotId withToken:token];
                } tokenInfoLoadingFailedCallback:^(CK_SLOT_ID slotId) {
                    [self processTokenInfoLoadingFailedAtSlotId: slotId];
                }];
            }
                break;
                
            default:
                nextState = currentState;
                break;
        }
        [self.slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
    } @catch(NSError* e){
        NSLog(@"Token Manager iternal error occured, reason: %ld (%@)", (long)[e code], [e localizedDescription]);
        @throw [ApplicationError errorWithCode:UnrecoverableError];
    }
}

-(void)processTokenWasRemovedAtSlotId: (CK_SLOT_ID) slotId {
    @try {
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
                    Token* tokenToRemove = [self.tokens objectForKey:handleToRemove];
                    if ([tokenToRemove type] == TokenTypeNFC) {
                        _activeNFCToken = NULL;
                        nextState = InnerStateReadyAfterRemoved;
                        break;
                    }
                    
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
    } @catch(NSError* e){
        NSLog(@"Token Manager iternal error occured, reason: %ld (%@)", (long)[e code], [e localizedDescription]);
        @throw [ApplicationError errorWithCode:UnrecoverableError];
    }
	
}

-(void)processTokenInfoLoadedAtSlotId: (CK_SLOT_ID) slotId withToken: (Token*) token {
    @try {
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
                NSInteger handle = -1;
                if ([token type] == TokenTypeNFC) {
                    for(NSNumber * key in self.tokens) {
                        Token * t = [self.tokens objectForKey:key];
                        if([t serialNumber] == [token serialNumber]) {
                            handle = key.integerValue;
                            [self.tokens removeObjectForKey:key];
                            break;
                        }
                    }
                    for(NSNumber * key in self.handles) {
                        if ([[self.handles objectForKey:key] integerValue] == handle) {
                            [self.handles removeObjectForKey:key];
                            break;
                        }
                    }
                    _activeNFCToken = token;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NFC card was detected" object:self];

                }
                if (handle == -1) {
                    handle = self.currentHandle;
                    ++self.currentHandle;
                }
                
                [self.handles setObject:[NSNumber numberWithInteger:handle] forKey:[NSNumber numberWithUnsignedLong:slotId]];
                [self.tokens setObject:token forKey:[NSNumber numberWithInteger:handle]];
                NSMutableDictionary* notificationInfo = [NSMutableDictionary dictionaryWithCapacity:1];
                [notificationInfo setObject:[NSNumber numberWithInteger:handle] forKey:@"handle"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TokenWasAdded" object:self userInfo:notificationInfo];
            }
                break;
            case InnerStateCancelingAfterRemoved:
                nextState = InnerStateReadyAfterLoaded;
                break;
            case InnerStateCancelingAfterAdded:
            {
                [self.tokenInfoLoader loadTokenInfoFromSlot:slotId withTokenInfoLoadedCallback:^(CK_SLOT_ID slotId, Token* token){
                    [self processTokenInfoLoadedAtSlotId:slotId withToken:token];
                } tokenInfoLoadingFailedCallback:^(CK_SLOT_ID slotId) {
                    [self processTokenInfoLoadingFailedAtSlotId: slotId];
                }];
            }
                break;
                
            default:
                nextState = currentState;
                break;
        }
        [self.slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
    } @catch(NSError* e){
        NSLog(@"Token Manager iternal error occured, reason: %ld (%@)", (long)[e code], [e localizedDescription]);
        @throw [ApplicationError errorWithCode:UnrecoverableError];
    }
}

-(void)processTokenInfoLoadingFailedAtSlotId: (CK_SLOT_ID) slotId {
    @try {
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
                [self.tokenInfoLoader loadTokenInfoFromSlot:slotId withTokenInfoLoadedCallback:^(CK_SLOT_ID slotId, Token* token){
                    [self processTokenInfoLoadedAtSlotId:slotId withToken:token];
                } tokenInfoLoadingFailedCallback:^(CK_SLOT_ID slotId) {
                    [self processTokenInfoLoadingFailedAtSlotId: slotId];
                }];
                nextState = InnerStateWaitingAfterAdded;
            }
                break;
                
            default:
                nextState = currentState;
                break;
        }
        [self.slotStates setObject:[NSNumber numberWithInteger:nextState] forKey:[NSNumber numberWithUnsignedLong:slotId]];
    } @catch(NSError* e){
        NSLog(@"Token Manager iternal error occured, reason: %ld (%@)", (long)[e code], [e localizedDescription]);
        @throw [ApplicationError errorWithCode:UnrecoverableError];
    }
}

- (void)NFCWasDetected:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"NFC card was detected"]){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NFC card was detected" object:nil];
        
        [_NFCCondition lockWhenCondition:NO];
        [_NFCCondition unlockWithCondition:YES];
    }
}

-(void)waitForActiveNFCToken:(void (^)(NSError* err))errorCallback {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NFCWasDetected:)
                                                 name:@"NFC card was detected"
                                               object:nil];
    startNFC(^(NSError* e){
        errorCallback(e);
        [self->_NFCCondition unlockWithCondition:YES];
    });

    [_NFCCondition lockWhenCondition:YES];
    [_NFCCondition unlockWithCondition:NO];
}

@end
