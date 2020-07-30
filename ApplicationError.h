// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <Foundation/Foundation.h>

static NSString* const gApplicationErrorDomain = @"ru.rutoken.demobank.applicationerror";

enum ApplicationErrorCode {
	UnrecoverableError,
    CertNotFoundError,
    RtEngineError,
    OpensslError,
};

@interface ApplicationError : NSError

+ (ApplicationError*)errorWithCode:(enum ApplicationErrorCode)code;

@end
