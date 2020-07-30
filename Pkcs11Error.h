// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

@interface Pkcs11Error : NSError

+ (Pkcs11Error*)errorWithCode:(NSUInteger)code;

@end
