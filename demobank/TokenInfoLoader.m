//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "TokenInfoLoader.h"

#import "Pkcs11Error.h"
#import "Token.h"


@interface TokenInfoLoader ()

@property(nonatomic, readwrite) CK_FUNCTION_LIST_PTR functions;
@property(nonatomic, readwrite) CK_FUNCTION_LIST_EXTENDED_PTR extendedFunctions;
@property(nonatomic, readwrite, strong) void (^ tokenInfoLoaded)(CK_SLOT_ID, Token*);
@property(nonatomic, readwrite, strong) void (^ tokenInfoLoadingFailed)(CK_SLOT_ID);

@end

@implementation TokenInfoLoader

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
tokenInfoLoadedCallback:(void(^)(CK_SLOT_ID, Token*)) tokenInfoLoadedCallback
tokenInfoLoadingFailedCallback:(void(^)(CK_SLOT_ID)) tokenInfoLoadingFailedCallback{
	self = [super init];
	if (self) {
		self.functions = functions;
		self.extendedFunctions = extendedFunctions;
        self.tokenInfoLoadingFailed = tokenInfoLoadingFailedCallback;
        self.tokenInfoLoaded = tokenInfoLoadedCallback;
	}
	return self;
}

-(void)loadTokenInfoFromSlot:(CK_SLOT_ID)slotId{
    @autoreleasepool {
        NSString* queueName = @"ru.rutoken.demobank.tokenLoading";
        dispatch_queue_t queue = dispatch_queue_create([[queueName stringByAppendingString:[NSString stringWithFormat:@"_%lu", slotId]] UTF8String], nil);
        dispatch_async(queue, ^() {
            @try {
                Token* token = [[Token alloc] initWithFunctions:self.functions extendedFunctions:self.extendedFunctions slotId:slotId];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.tokenInfoLoaded(slotId, token);
                });
                
            }@catch (Pkcs11Error* e) {
				NSLog(@"Error in pkcs11 while loading token with rv = %d (%@)", [e code], [e localizedDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.tokenInfoLoadingFailed(slotId);
                });
            }@catch (NSError* e) {
				NSLog(@"General error during loading token with code = %d", [e code]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.tokenInfoLoadingFailed(slotId);
                });
            }
        });
	}
}

@end

