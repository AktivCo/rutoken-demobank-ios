// Copyright (c) 2015, CJSC Aktiv-Soft. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import "Token.h"

#import "Pkcs11Error.h"
#import "Certificate.h"
#import "ApplicationError.h"
#import "Util.h"

static const double kVoltageMin = 3500;
static const double kVoltageMax = 4200;
static const double kChargingVoltage = 4800;

typedef NS_ENUM(CK_ULONG, CertificateCategory) {
    CertificateCategoryUnspecified = 0,
    CertificateCategoryUser = 1,
};

@interface Token ()

@property(nonatomic) CK_FUNCTION_LIST_PTR functions;
@property(nonatomic) CK_FUNCTION_LIST_EXTENDED_PTR extendedFunctions;

@end

@implementation Token

- (NSString*)removeTrailingSpaceFromCString:(const char*) string length:(size_t) length {
	size_t i;
	for (i = length; i != 0; --i) {
		if (' ' != string[i - 1]) break;
	}
	
	return [[NSString alloc] initWithBytes:string length:i encoding:NSUTF8StringEncoding];
}

- (void)readCertificatesWithCategory:(CK_ULONG) category {
    CK_OBJECT_CLASS certClass = CKO_CERTIFICATE;
    CK_ATTRIBUTE template[] = {
            {CKA_CLASS, &certClass, sizeof(certClass)},
            {CKA_CERTIFICATE_CATEGORY, &category, sizeof(category)}
    };

    CK_RV rv = [self functions]->C_FindObjectsInit(_session, template, ARRAY_LENGTH(template));
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

    while (TRUE) {
        CK_OBJECT_HANDLE objects[30];
        CK_ULONG count;
        rv = [self functions]->C_FindObjects(_session, objects, ARRAY_LENGTH(objects), &count);
        if (CKR_OK != rv) break;

        for (int i = 0; i < count; ++i) {
            Certificate* c = [[Certificate alloc] initWithSession:_session object:objects[i]];
            if (nil != c) [_certificates addObject:c];
        }

        if (count < ARRAY_LENGTH(objects)) break;
    }

    CK_RV rv2 = [self functions]->C_FindObjectsFinal(_session); // we should always call C_FindObjectsFinal, even after an error (see pkcs11 standart for more info...)
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
    if (CKR_OK != rv2) @throw [Pkcs11Error errorWithCode:rv2];
    
    //This code only for thoose who hasn't read pkcs11 standart
    //and set different CKA_ID for key and cert
    //You should delete it, unless you know, that key's and cert's CKA_IDs are different
    for (Certificate* cert in _certificates) {
        CK_OBJECT_CLASS keyClass = CKO_PUBLIC_KEY;
        
        CK_ATTRIBUTE keyTemplatebyValue[] = {
            {CKA_CLASS, &keyClass, sizeof(keyClass)},
            {CKA_VALUE, (void*)[[cert value] bytes], [[cert value] length]}
        };
        
        rv = [self functions]->C_FindObjectsInit(_session, keyTemplatebyValue, ARRAY_LENGTH(keyTemplatebyValue));
        if (CKR_OK != rv) continue;
        
        CK_OBJECT_HANDLE objects[2];
        CK_ULONG count;
        rv = [self functions]->C_FindObjects(_session, objects, ARRAY_LENGTH(objects), &count);
        
        rv2 = [self functions]->C_FindObjectsFinal(_session); // we should always call C_FindObjectsFinal, even after an error (see pkcs11 standart for more info...)
        if (CKR_OK != rv) [Pkcs11Error errorWithCode:rv];
        if (CKR_OK != rv2) [Pkcs11Error errorWithCode:rv2];
        
        if (count == 1) { //we found exactly one key, so it's cert's public key, now we have to check CKA_ID to avoid pkcs11 violation.
            CK_ATTRIBUTE attributes[] = {
                {CKA_ID, nil, 0}
            };
            
            rv = [self functions]->C_GetAttributeValue(_session, objects[0], attributes, ARRAY_LENGTH(attributes));
            if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
            
            NSMutableData* idData = [NSMutableData dataWithLength:attributes[0].ulValueLen];
            attributes[0].pValue = [idData mutableBytes];
            
            rv = [self functions]->C_GetAttributeValue(_session, objects[0], attributes, ARRAY_LENGTH(attributes));
            if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
            
            [cert setId:[NSData dataWithData:idData]];
        }
    }
}

-(void)updateTokenInfoFromSlot:(CK_SLOT_ID)slotId {
	NSMutableData* tokenInfoData = [NSMutableData dataWithLength:sizeof(CK_TOKEN_INFO)];
	CK_TOKEN_INFO_PTR tokenInfo  = [tokenInfoData mutableBytes];
	
	CK_RV rv = [self functions]->C_GetTokenInfo(slotId, tokenInfo);
	if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
	
	_label = [self removeTrailingSpaceFromCString:(const char*) tokenInfo->label length: sizeof(tokenInfo->label)];
	_serialNumber = [self removeTrailingSpaceFromCString:(const char*) tokenInfo->serialNumber length: sizeof(tokenInfo->serialNumber)];
	_model = [self removeTrailingSpaceFromCString:(const char*) tokenInfo->model length: sizeof(tokenInfo->model)];
	_totalMemory = tokenInfo->ulTotalPublicMemory;
	_freeMemory = tokenInfo->ulFreePublicMemory;

	
	NSMutableData* extendedTokenInfoData = [NSMutableData dataWithLength:sizeof(CK_TOKEN_INFO_EXTENDED)];
	CK_TOKEN_INFO_EXTENDED_PTR extendedTokenInfo = [extendedTokenInfoData mutableBytes];
	extendedTokenInfo->ulSizeofThisStructure = sizeof(CK_TOKEN_INFO_EXTENDED);
	
	rv = [self extendedFunctions]->C_EX_GetTokenInfoExtended(slotId, extendedTokenInfo);
	if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
	
	double batteryVoltage = extendedTokenInfo->ulBatteryVoltage;
	_charge = ((batteryVoltage - kVoltageMin) / (kVoltageMax - kVoltageMin)) * 100;
	_charging = NO;
	if(_charge >= 100) {
		if (kChargingVoltage <= batteryVoltage) _charging = YES;
		_charge = 100;
	}
	if(_charge < 1) _charge = 1;
	
	switch (extendedTokenInfo->ulBodyColor) {
		case 0:
			_color = TokenColorBlack;
			break;
		case 1:
			_color = TokenColorWhite;
			break;
			
		default:
			break;
	}
}

- (id)initWithSlotId:(CK_SLOT_ID)slotId{
	self = [super init];
	if (self) {
		_slotId = slotId;
		
		@try {
            CK_RV rv = C_GetFunctionList(&_functions);
            if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
            
            rv = C_EX_GetFunctionListExtended(&_extendedFunctions);
            if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
            
			[self updateTokenInfoFromSlot:slotId];

			rv = _functions->C_OpenSession(_slotId, CKF_SERIAL_SESSION, nil, nil, &_session);
			if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		} @catch (NSError* e) {
            return nil;
        }
		
		@try{
			_certificates = [NSMutableArray array];
        
            [self readCertificatesWithCategory:CertificateCategoryUnspecified];
            [self readCertificatesWithCategory:CertificateCategoryUser];
        } @catch (NSError* e) {
            _functions->C_CloseSession(_session);
            return nil;
        }
    }
	
	return self;
}

- (void)dealloc {
    _functions->C_CloseSession(_session);
}

- (void)onError:(NSError*)error callback:(void (^)(NSError*))callback {
    dispatch_async(dispatch_get_main_queue(), ^() {
        callback(error);
    });
}

- (void)loginWithPin:(NSString*)pin successCallback:(void (^)())successCallback
errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        NSData* pinData = [pin dataUsingEncoding:NSUTF8StringEncoding];

        CK_RV rv = [self functions]->C_Login(_session, CKU_USER, (unsigned char*)[pinData bytes], [pinData length]);
		if (CKR_OK != rv) {
			[self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^() {
            successCallback();
        });
    });
}

- (void)logoutWithSuccessCallback:(void (^)())successCallback errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        CK_RV rv = [self functions]->C_Logout(_session);
		if (CKR_OK != rv) {
			[self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^() {
            successCallback();
        });
    });
}

-(void)signData:(NSData*)data withCertificate:(Certificate*)certificate  successCallback:(void (^)(NSData*))successCallback
  errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        //Looking for private key by cert id
        CK_OBJECT_CLASS keyClass = CKO_PRIVATE_KEY;
        CK_ATTRIBUTE template[] = {
                {CKA_CLASS, &keyClass, sizeof(keyClass)},
                {CKA_ID, (void*)[[certificate id] bytes], [[certificate id] length]}
        };

        CK_RV rv = [self functions]->C_FindObjectsInit(_session, template, ARRAY_LENGTH(template));
        if (CKR_OK != rv) {
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }

        CK_OBJECT_HANDLE objects[2];
        CK_ULONG count;
        rv = [self functions]->C_FindObjects(_session, objects, ARRAY_LENGTH(objects), &count);

        CK_RV rv2 = [self functions]->C_FindObjectsFinal(_session);
        if (CKR_OK != rv){
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }else if (CKR_OK != rv2) {
            [self onError:[Pkcs11Error errorWithCode:rv2] callback:errorCallback];
            return;
        }else if (count != 1) {
            [self onError:[ApplicationError errorWithCode:CertNotFoundError] callback:errorCallback];
            return;
        }

        unsigned char oid[] = {0x06, 0x07, 0x2a, 0x85, 0x03, 0x02, 0x02, 0x1e, 0x01};
        CK_MECHANISM mechanism = {CKM_GOSTR3410_WITH_GOSTR3411, oid, ARRAY_LENGTH(oid)};
        rv = [self functions]->C_SignInit(_session, &mechanism, objects[0]);
        if (CKR_OK != rv){
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }

        rv = [self functions]->C_Sign(_session, (unsigned char*)[data bytes], [data length], nil, &count);
        if (CKR_OK != rv){
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }

        NSMutableData* signature = [NSMutableData dataWithLength:count];
        rv = [self functions]->C_Sign(_session, (unsigned char*)[data bytes], [data length],
                [signature mutableBytes], &count);
        if (CKR_OK != rv){
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^() {
            successCallback(signature);
        });
    });
}

@end
