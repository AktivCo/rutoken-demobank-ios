// Copyright (c) 2015, CJSC Aktiv-Soft. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@interface Certificate : NSObject

@property(nonatomic, readonly) NSString* cn;
@property(nonatomic, readonly) NSData* id;

-(id)initWithSession:(CK_SESSION_HANDLE)session object:(CK_OBJECT_HANDLE)object;

@end
