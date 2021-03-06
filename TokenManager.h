// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <rtpkcs11ecp/rtpkcs11.h>

@class Token;

@interface TokenManager : NSObject

@property(nonatomic, readonly) Token* activeNFCToken;

+(TokenManager*)sharedInstance;

-(void)startMonitoring;
-(void)stopMonitoring;

-(NSArray*)tokenHandles;
-(Token*)tokenForHandle:(NSNumber*)tokenId;
-(NSInteger)tokenCount;

-(void)waitForActiveNFCToken:(void (^)(NSError* err))errorCallback;

@end
