// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

#import <rtpkcs11ecp/rtpkcs11.h>

#import <openssl/x509.h>

@interface Certificate : NSObject

@property(nonatomic, readonly) NSString* cn;
@property(nonatomic, readonly) NSData* id;
@property(nonatomic, readonly) X509* x509;

-(id)initWithSession:(CK_SESSION_HANDLE)session withObjectId:(CK_OBJECT_HANDLE)object withId:(NSData*)id withX509:(X509*)x509;

@end
