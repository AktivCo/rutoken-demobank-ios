// Copyright (c) 2015, CJSC Aktiv-Soft. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@class Token;

@interface TokenManager : NSObject

+(TokenManager*)sharedInstance;

-(void)startMonitoring;
-(void)stopMonitoring;

-(NSArray*)tokenHandles;
-(Token*)tokenForHandle:(NSNumber*)tokenId;

@end
