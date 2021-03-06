// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import "Pkcs11Error.h"

static NSString* const gPkcs11ErrorDomain = @"ru.rutoken.demobank.pkcs11error";

@implementation Pkcs11Error

- (NSString*)localizedDescription {
	switch ([self code]) {
			//Put errors' decription here
		case 0x06:
			return @"Function failed";
		case 0x30:
			return @"Device error";
		default:
			return @"Unknown error";
	}
}

+ (Pkcs11Error*)errorWithCode:(NSUInteger)code {
	return [[Pkcs11Error alloc] initWithDomain:gPkcs11ErrorDomain code:code userInfo:nil];
}

@end
