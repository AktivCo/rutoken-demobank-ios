//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

static NSString* const gPkcs11ErrorDomain = @"ru.rutoken.demobank.pkcs11error";

@interface Pkcs11Error : NSError

+ (Pkcs11Error*)errorWithCode:(NSUInteger)code;

@end
