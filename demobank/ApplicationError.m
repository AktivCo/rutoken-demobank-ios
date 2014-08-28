// Copyright (c) 2014 Aktiv Co. All rights reserved.

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
