//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "Token.h"

#import "Pkcs11Error.h"
#import "Certificate.h"
#import "ApplicationError.h"
#import "Util.h"

static const double kVoltageMin = 3500;
static const double kVoltageMax = 4800;

static NSString* removeTrailingSpaces(const char* string, size_t length) {
	size_t i;
	for (i = length; i != 0; --i) {
		if (' ' != string[i - 1]) break;
	}
	
	return [[NSString alloc] initWithBytes:string length:i encoding:NSUTF8StringEncoding];
}

@implementation Token

- (void)readCertificates {
    CK_OBJECT_CLASS certClass = CKO_CERTIFICATE;
    // token user category
    CK_ULONG certCategory = 1;
    CK_ATTRIBUTE template[] = {
            {CKA_CLASS, &certClass, sizeof(certClass)},
            {CKA_CERTIFICATE_CATEGORY, &certCategory, sizeof(certCategory)}
    };

    CK_RV rv = _functions->C_FindObjectsInit(_session, template, ARRAY_LENGTH(template));
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

    while (TRUE) {
        CK_OBJECT_HANDLE objects[30];
        CK_ULONG count;
        rv = _functions->C_FindObjects(_session, objects, ARRAY_LENGTH(objects), &count);
        if (CKR_OK != rv) break;

        for (int i = 0; i < count; ++i) {
            [_certificates addObject:[[Certificate alloc] initWithFunctions:_functions
                                                          extendedFunctions:_extendedFunctions
                                                                    session:_session object:objects[i]]];
        }

        if (count < ARRAY_LENGTH(objects)) break;
    }

    CK_RV rv2 = _functions->C_FindObjectsFinal(_session);
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
    if (CKR_OK != rv2) @throw [Pkcs11Error errorWithCode:rv2];
}

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
				 slotId:(CK_SLOT_ID)slotId{
	self = [super init];
	if (self) {
		_functions = functions;
		_extendedFunctions = extendedFunctions;
		_slotId = slotId;
        
        NSMutableData* tokenInfo = nil;
        NSMutableData* extendedTokenInfo = nil;
        CK_TOKEN_INFO_EXTENDED_PTR extendedInfo = nil;
        CK_TOKEN_INFO_PTR info = nil;
        
        tokenInfo = [NSMutableData dataWithLength:sizeof(CK_TOKEN_INFO)];
        info = [tokenInfo mutableBytes];
        CK_RV rv = _functions->C_GetTokenInfo(slotId, info);
        if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
        
        extendedTokenInfo = [NSMutableData dataWithLength:sizeof(CK_TOKEN_INFO_EXTENDED)];
        extendedInfo = [extendedTokenInfo mutableBytes];
        extendedInfo->ulSizeofThisStructure = sizeof(CK_TOKEN_INFO_EXTENDED);
        
        rv = _extendedFunctions->C_EX_GetTokenInfoExtended(slotId, extendedInfo);
        if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
        
        _label = removeTrailingSpaces((const char*) info->label, sizeof(info->label));
        _serialNumber = removeTrailingSpaces((const char*) info->serialNumber, sizeof(info->serialNumber));
        _model = removeTrailingSpaces((const char*) info->model, sizeof(info->model));
        _totalMemory = info->ulTotalPublicMemory;
        _freeMemory = info->ulFreePublicMemory;
        
        double batteryVoltage = extendedInfo->ulBatteryVoltage;
        _charge = ((batteryVoltage - kVoltageMin) / (kVoltageMax - kVoltageMin)) * 100;
        _charging = NO;
        if(_charge > 100) {
            _charging = YES;
            _charge = 100;
        }
        if(_charge < 1) _charge = 1;
	}
        _charge = extendedInfo->ulBatteryVoltage;

        rv = _functions->C_OpenSession(_slotId, CKF_SERIAL_SESSION, nil, nil, &_session);
        if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

        _certificates = [NSMutableArray array];
        
        @try {
            [self readCertificates];
        } @catch (NSError* e) {
            _functions->C_CloseSession(_session);
            @throw e;
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

- (void)login:(NSString*)pin successCallback:(void (^)())successCallback
errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_queue_t queue = dispatch_queue_create("Login queue", nil);
    dispatch_async(queue, ^() {
        NSData* pinData = [pin dataUsingEncoding:NSUTF8StringEncoding];

        CK_RV rv = _functions->C_Login(_session, CKU_USER, (unsigned char*)[pinData bytes], [pinData length]);
        dispatch_async(dispatch_get_main_queue(), ^() {
            if (CKR_OK != rv) errorCallback([Pkcs11Error errorWithCode:rv]);
            else successCallback();
        });
    });
}

- (void)logoutWithSuccessCallback:(void (^)())successCallback errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_queue_t queue = dispatch_queue_create("Logout queue", nil);
    dispatch_async(queue, ^() {
        CK_RV rv = _functions->C_Logout(_session);
        dispatch_async(dispatch_get_main_queue(), ^() {
            if (CKR_OK != rv) errorCallback([Pkcs11Error errorWithCode:rv]);
            else successCallback();
        });
    });
}

- (void)sign:(Certificate*)certificate data:(NSData*)data successCallback:(void (^)(NSData*))successCallback
        errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_queue_t queue = dispatch_queue_create("Logout queue", nil);
    dispatch_async(queue, ^() {
        CK_OBJECT_CLASS keyClass = CKO_PRIVATE_KEY;
        CK_ATTRIBUTE template[] = {
                {CKA_CLASS, &keyClass, sizeof(keyClass)},
                {CKA_ID, (void*)[[certificate id] bytes], [[certificate id] length]}
        };

        CK_RV rv = _functions->C_FindObjectsInit(_session, template, ARRAY_LENGTH(template));
        if (CKR_OK != rv) [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];

        CK_OBJECT_HANDLE objects[2];
        CK_ULONG count;
        rv = _functions->C_FindObjects(_session, objects, ARRAY_LENGTH(objects), &count);

        CK_RV rv2 = _functions->C_FindObjectsFinal(_session);
        if (CKR_OK != rv) [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
        else if (CKR_OK != rv2) [self onError:[Pkcs11Error errorWithCode:rv2] callback:errorCallback];
        else if (count != 1) [self onError:[ApplicationError errorWithCode:CertNotFoundError] callback:errorCallback];

        unsigned char oid[] = {0x06, 0x07, 0x2a, 0x85, 0x03, 0x02, 0x02, 0x1e, 0x01};
        CK_MECHANISM mechanism = {CKM_GOSTR3410_WITH_GOSTR3411, oid, ARRAY_LENGTH(oid)};
        rv = _functions->C_SignInit(_session, &mechanism, objects[0]);
        if (CKR_OK != rv) [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];

        rv = _functions->C_Sign(_session, (unsigned char*)[data bytes], [data length], nil, &count);
        if (CKR_OK != rv) [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];

        NSMutableData* signature = [NSMutableData dataWithLength:count];
        rv = _functions->C_Sign(_session, (unsigned char*)[data bytes], [data length],
                [signature mutableBytes], &count);
        if (CKR_OK != rv) [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];

        dispatch_async(dispatch_get_main_queue(), ^() {
            successCallback(signature);
        });
    });
}

@end
