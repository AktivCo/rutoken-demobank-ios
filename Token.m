// Copyright (c) 2015, CJSC Aktiv-Soft. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import <openssl/x509.h>
#import <openssl/cms.h>

#import <rtengine/engine.h>

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

- (void)readCertificates {
    NSMutableArray * certs = [NSMutableArray array];
    
    CK_CERTIFICATE_TYPE certificateType = CKC_X_509;
    CK_OBJECT_CLASS certificateClass = CKO_CERTIFICATE;
    CK_ATTRIBUTE certificateTemplate[] = {
        {CKA_CLASS, &certificateClass, sizeof(certificateClass)},
        {CKA_CERTIFICATE_TYPE, &certificateType, sizeof(certificateType)},
    };
    CK_OBJECT_HANDLE certificates[32];
    CK_ULONG certificateCount;
    CK_RV rv, rv2;

    // Find all certificates on token
    rv = [self functions]->C_FindObjectsInit(_session, certificateTemplate, ARRAY_LENGTH(certificateTemplate));
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

    rv = [self functions]->C_FindObjects(_session, certificates, ARRAY_LENGTH(certificates), &certificateCount);

    rv2 = [self functions]->C_FindObjectsFinal(_session);
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
    if (CKR_OK != rv2) @throw [Pkcs11Error errorWithCode:rv2];

    for (int i = 0; i < certificateCount; ++i) {
        NSMutableData* value;
        NSMutableData* id;

        const unsigned char* certificateValue;

        EVP_PKEY* key;
        X509* x509;

        CK_ATTRIBUTE certificateAttributes[] = {
            {CKA_VALUE, NULL_PTR, 0},
            {CKA_ID, NULL_PTR, 0},
        };
        CK_OBJECT_CLASS publicKeyClass = CKO_PUBLIC_KEY;
        CK_ATTRIBUTE publicKeyTemplate[] = {
            {CKA_CLASS, &publicKeyClass, sizeof(publicKeyClass)},
            {CKA_ID, NULL_PTR, 0},
        };
        CK_OBJECT_HANDLE publicKeys[16];
        CK_ULONG publicKeyCount;

        // Get certificate value and id
        rv = [self functions]->C_GetAttributeValue(_session, certificates[i], certificateAttributes, ARRAY_LENGTH(certificateAttributes));
        if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

        value = [NSMutableData dataWithLength:certificateAttributes[0].ulValueLen];
        certificateAttributes[0].pValue = [value mutableBytes];
        id = [NSMutableData dataWithLength:certificateAttributes[1].ulValueLen];
        certificateAttributes[1].pValue = [id mutableBytes];

        rv = [self functions]->C_GetAttributeValue(_session, certificates[i], certificateAttributes, ARRAY_LENGTH(certificateAttributes));
        if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

        // Filter non-GOST certificates
        certificateValue = [value mutableBytes];
        x509 = d2i_X509(NULL, &certificateValue, [value length]);
        if (!x509) continue;

        key = X509_get0_pubkey(x509);
        if (!key) {
            X509_free(x509);
            continue;
        }

        switch (EVP_PKEY_base_id(key)) {
            case NID_id_GostR3410_2001:
            case NID_id_GostR3410_2012_256:
            case NID_id_GostR3410_2012_512:
                break;
            default:
                X509_free(x509);
                continue;
        }

        // Find public keys by certificate id
        publicKeyTemplate[1].pValue = certificateAttributes[1].pValue;
        publicKeyTemplate[1].ulValueLen = certificateAttributes[1].ulValueLen;

        rv = [self functions]->C_FindObjectsInit(_session, publicKeyTemplate, ARRAY_LENGTH(publicKeyTemplate));
        if (CKR_OK != rv) {
            X509_free(x509);
            @throw [Pkcs11Error errorWithCode:rv];
        }

        rv = [self functions]->C_FindObjects(_session, publicKeys, ARRAY_LENGTH(publicKeys), &publicKeyCount);

        rv2 = [self functions]->C_FindObjectsFinal(_session);
        if (CKR_OK != rv) {
            X509_free(x509);
            @throw [Pkcs11Error errorWithCode:rv];
        }
        if (CKR_OK != rv2) {
            X509_free(x509);
            @throw [Pkcs11Error errorWithCode:rv2];
        }

        switch (publicKeyCount) {
            case 0:
                // Nothing has been found.
                X509_free(x509);
                continue;
            case 1:
                [certs addObject:[[Certificate alloc] initWithSession:_session withObjectId:certificates[i] withId:id withX509:x509]];
                break;
            default:
                // There are several public keys with certificate ID. We dont know which to choose so skip.
                X509_free(x509);
                continue;
        }
    }
    _certificates = certs;
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
        _certificates = nil;

        @try {
            CK_RV rv = C_GetFunctionList(&_functions);
            if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
            
            rv = C_EX_GetFunctionListExtended(&_extendedFunctions);
            if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
            
            [self updateTokenInfoFromSlot:slotId];

            rv = _functions->C_OpenSession(_slotId, CKF_SERIAL_SESSION, nil, nil, &_session);
            _isLocked = NO;
            if (CKR_FUNCTION_NOT_SUPPORTED == rv) _isLocked = YES;
            else if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
        } @catch (NSError* e) {
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

- (void)readCertificatesWithSuccessCallback:(void (^)())successCallback errorCallback:(void (^)(NSError *))errorCallback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        @try{
            [self readCertificates];
            dispatch_async(dispatch_get_main_queue(), ^() {
                successCallback();
            });
        } @catch (NSError* e) {
            [self onError:[Pkcs11Error errorWithCode:e.code] callback:errorCallback];
        }
    });
}

-(void)activateSmWithPassword:(NSString*)password successCallback:(void (^)())successCallback errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {

        CK_RV rv = [self extendedFunctions]->C_EX_SetActivationPassword(_slotId, [password cStringUsingEncoding:NSUTF8StringEncoding]);
        if (CKR_OK != rv) {
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }
        rv = _functions->C_OpenSession(_slotId, CKF_SERIAL_SESSION, nil, nil, &_session);
        if (CKR_OK != rv) {
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }
        _isLocked = NO;       
        dispatch_async(dispatch_get_main_queue(), ^() {
            successCallback();
        });
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

-(void)signData:(NSData*)data withCertificate:(Certificate*)certificate  successCallback:(void (^)(NSValue*))successCallback
  errorCallback:(void (^)(NSError*))errorCallback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        BIO* bio;
        CMS_ContentInfo* cms;
        EVP_PKEY* evpPKey;

        rt_eng_p11_session wrappedSession;

        CK_OBJECT_HANDLE privateKey, publicKey;
        CK_ULONG count;
        CK_RV rv, rv2;

        // Looking for private key by cert id
        CK_OBJECT_CLASS keyClass = CKO_PRIVATE_KEY;
        CK_ATTRIBUTE template[] = {
                {CKA_CLASS, &keyClass, sizeof(keyClass)},
                {CKA_ID, (void*)[[certificate id] bytes], [[certificate id] length]}
        };

        rv = [self functions]->C_FindObjectsInit(_session, template, ARRAY_LENGTH(template));
        if (CKR_OK != rv) {
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }

        rv = [self functions]->C_FindObjects(_session, &privateKey, 1, &count);

        rv2 = [self functions]->C_FindObjectsFinal(_session);
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

        // Now looking for public key by cert id using the same template
        keyClass = CKO_PUBLIC_KEY;

        rv = [self functions]->C_FindObjectsInit(_session, template, ARRAY_LENGTH(template));
        if (CKR_OK != rv) {
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }

        rv = [self functions]->C_FindObjects(_session, &publicKey, 1, &count);

        rv2 = [self functions]->C_FindObjectsFinal(_session);
        if (CKR_OK != rv){
            [self onError:[Pkcs11Error errorWithCode:rv] callback:errorCallback];
            return;
        }
        if (CKR_OK != rv2) {
            [self onError:[Pkcs11Error errorWithCode:rv2] callback:errorCallback];
            return;
        }
        if (count != 1) {
            [self onError:[ApplicationError errorWithCode:CertNotFoundError] callback:errorCallback];
            return;
        }

        // Creating an EVP_PKEY
        wrappedSession = rt_eng_p11_session_new([self functions], _session, 0, NULL);
        if (!wrappedSession.self) {
            [self onError:[ApplicationError errorWithCode:OpensslError] callback:errorCallback];
            return;
        }

        evpPKey = rt_eng_new_p11_ossl_evp_pkey(wrappedSession, privateKey, publicKey);
        RT_ENG_CALL(wrappedSession, free);
        if (!evpPKey) {
            [self onError:[ApplicationError errorWithCode:OpensslError] callback:errorCallback];
            return;
        }

        // Creating an input buffer
        bio = BIO_new(BIO_s_mem());
        if (!bio) {
            EVP_PKEY_free(evpPKey);
            [self onError:[ApplicationError errorWithCode:OpensslError] callback:errorCallback];
            return;
        }

        rv = BIO_write(bio, [data bytes], (int)[data length]);
        if (rv != [data length]) {
            BIO_free(bio);
            EVP_PKEY_free(evpPKey);
            [self onError:[ApplicationError errorWithCode:OpensslError] callback:errorCallback];
            return;
        }

        // Creating a CMS
        cms = CMS_sign([certificate x509], evpPKey, NULL, bio, CMS_BINARY | CMS_NOSMIMECAP);

        BIO_free(bio);
        EVP_PKEY_free(evpPKey);

        if (cms) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                // Don't forget to free the CMS
                successCallback([NSValue valueWithPointer:cms]);
            });
            return;
        } else {
            [self onError:[ApplicationError errorWithCode:OpensslError] callback:errorCallback];
            return;
        }
    });
}

@end
