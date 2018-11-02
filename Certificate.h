// Copyright (c) 2015, CJSC Aktiv-Soft. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <rtpkcs11ecp/rtpkcs11.h>

@interface Certificate : NSObject

@property(nonatomic, readonly) NSString* cn;
@property(nonatomic, readwrite) NSData* id;
@property(nonatomic, readonly) NSData* value;

-(id)initWithSession:(CK_SESSION_HANDLE)session object:(CK_OBJECT_HANDLE)object;

@end
