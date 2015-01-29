//  Copyright (c) 2014 Aktiv Co. All rights reserved.

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
