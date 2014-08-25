//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "Token.h"

static NSString* removeTrailingSpaces(const char* string, size_t length) {
	size_t i;
	for (i = length; i != 0; --i) {
		if (' ' != string[i - 1]) break;
	}
	
	return [[NSString alloc] initWithBytes:string length:i encoding:NSUTF8StringEncoding];
}

@implementation Token

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
				 slotId:(CK_SLOT_ID)slotId{
	self = [super init];
	if (self) {
		_functions = functions;
		_extendedFunctions = extendedFunctions;
		_slotId = slotId;
	}
	
	NSMutableData* tokenInfo = nil;
	NSMutableData* extendedTokenInfo = nil;
	CK_TOKEN_INFO_EXTENDED_PTR extendedInfo = nil;
	CK_TOKEN_INFO_PTR info = nil;
	
	tokenInfo = [NSMutableData dataWithLength:sizeof(CK_TOKEN_INFO)];
	info = [tokenInfo mutableBytes];
	CK_RV rv = _functions->C_GetTokenInfo(slotId, info);
	if (CKR_OK != rv) @throw @"ololo";
	
	extendedTokenInfo = [NSMutableData dataWithLength:sizeof(CK_TOKEN_INFO_EXTENDED)];
	extendedInfo = [extendedTokenInfo mutableBytes];
	extendedInfo->ulSizeofThisStructure = sizeof(CK_TOKEN_INFO_EXTENDED);
	
	rv = _extendedFunctions->C_EX_GetTokenInfoExtended(slotId, extendedInfo);
	if (CKR_OK != rv) @throw @"ololo";
	
	_label = removeTrailingSpaces((const char*) info->label, sizeof(info->label));
	_serialNumber = removeTrailingSpaces((const char*) info->serialNumber, sizeof(info->serialNumber));
	_totalMemory = info->ulTotalPublicMemory;
	_freeMemory = info->ulFreePublicMemory;
	_charge = extendedInfo->ulBatteryVoltage;
	
	return self;
}

@end
