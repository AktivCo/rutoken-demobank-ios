//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "Certificate.h"

#import "Util.h"
#import "Pkcs11Error.h"

@implementation Certificate

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
                session:(CK_SESSION_HANDLE)session object:(CK_OBJECT_HANDLE)object {
    self = [super init];
    if (nil == self) return self;

    CK_ATTRIBUTE attributes[] = {
            {CKA_SUBJECT, nil, 0},
            {CKA_ID, nil, 0}
    };

    CK_RV rv = functions->C_GetAttributeValue(session, object, attributes, ARRAY_LENGTH(attributes));
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

    NSMutableData* subjectData = [NSMutableData dataWithLength:attributes[0].ulValueLen];
    attributes[0].pValue = [subjectData mutableBytes];
    NSMutableData* idData = [NSMutableData dataWithLength:attributes[1].ulValueLen];
    attributes[1].pValue = [idData mutableBytes];

    rv = functions->C_GetAttributeValue(session, object, attributes, ARRAY_LENGTH(attributes));
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];

    _id = [NSData dataWithData:idData];

    return self;
}

@end
