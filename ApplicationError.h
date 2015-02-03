// Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

static NSString* const gApplicationErrorDomain = @"ru.rutoken.demobank.applicationerror";

enum ApplicationErrorCode {
	UnrecoverableError,
    CertNotFoundError
};

@interface ApplicationError : NSError

+ (ApplicationError*)errorWithCode:(enum ApplicationErrorCode)code;

@end
