// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import "ApplicationError.h"

@implementation ApplicationError

- (NSString*)localizedDescription {
    switch ([self code]) {
        //Put errors' decription here
        default:
            return @"Unknown error";
    }
}

+ (ApplicationError*)errorWithCode:(enum ApplicationErrorCode)code {
    return [[ApplicationError alloc] initWithDomain:gApplicationErrorDomain code:code userInfo:nil];
}

@end
