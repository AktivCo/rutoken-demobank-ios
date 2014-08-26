//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "Pkcs11Error.h"

@implementation Pkcs11Error

- (NSString*)localizedDescription {
	switch ([self code]) {
			//Put errors' decription here
		default:
			return @"Unknown error";
	}
}

+ (Pkcs11Error*)errorWithCode:(NSUInteger)code {
	return [[Pkcs11Error alloc] initWithDomain:gPkcs11ErrorDomain code:code userInfo:nil];
}

@end
