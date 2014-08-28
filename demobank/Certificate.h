//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@interface Certificate : NSObject

@property(nonatomic, readonly) NSData* id;

-(id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
     extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
               session:(CK_SESSION_HANDLE)session object:(CK_OBJECT_HANDLE)object;

@end
