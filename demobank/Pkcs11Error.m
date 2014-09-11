//  Copyright (c) 2014 Aktiv Co. All rights reserved.

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
