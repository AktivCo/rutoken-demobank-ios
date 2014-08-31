//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "TokenInfoLoader.h"

#import "Token.h"

@implementation TokenInfoLoader

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
tokenInfoLoadedCallback:(void(^)(CK_SLOT_ID, Token*)) tokenInfoLoadedCallback
tokenInfoLoadingFailedCallback:(void(^)(CK_SLOT_ID)) tokenInfoLoadingFailedCallback{
	self = [super init];
	if (self) {
		_functions = functions;
		_extendedFunctions = extendedFunctions;
        _tokenInfoLoadingFailed = tokenInfoLoadingFailedCallback;
        _tokenInfoLoaded = tokenInfoLoadedCallback;
	}
	return self;
}

-(void)loadTokenInfoFromSlot:(CK_SLOT_ID)slotId{
    @autoreleasepool {
        NSString* queueName = @"ru.rutoken.demobank.tokenLoading";
        dispatch_queue_t queue = dispatch_queue_create([[queueName stringByAppendingString:[NSString stringWithFormat:@"_%lu", slotId]] UTF8String], nil);
        dispatch_async(queue, ^() {
            @try {
                Token* token = [[Token alloc] initWithFunctions:_functions extendedFunctions:_extendedFunctions slotId:slotId];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _tokenInfoLoaded(slotId, token);
                });
                
            } @catch (NSError* e) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _tokenInfoLoadingFailed(slotId);
                });
            }
        });
	}
}

@end

