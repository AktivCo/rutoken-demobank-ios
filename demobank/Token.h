//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

@interface Token : NSObject {
	CK_FUNCTION_LIST_PTR _functions;
	CK_FUNCTION_LIST_EXTENDED_PTR _extendedFunctions;
	CK_SLOT_ID _slotId;
}

@property(nonatomic, readonly) NSString* label;
@property(nonatomic, readonly) NSString* serialNumber;
@property(nonatomic, readonly) NSUInteger totalMemory;
@property(nonatomic, readonly) NSUInteger freeMemory;
@property(nonatomic, readonly) NSUInteger charge;

-(id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
	 extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
				slotId:(CK_SLOT_ID)slotId;
@end
