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

    unsigned long length = 0;
    unsigned char* data;
    CK_RV rv = extendedFunctions->C_EX_GetCertificateInfoText(session, object, &data, &length);
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
    
    NSString *cert=[[NSString alloc]initWithBytes:data length:length encoding:NSUTF8StringEncoding];
    
    rv = extendedFunctions->C_EX_FreeBuffer(data);
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Subject: CN=([^\n]*)\n" options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:cert options:0 range:NSMakeRange(0, [cert length])];
    
    if (match != nil) {
        _cn = [cert substringWithRange:[match rangeAtIndex:1]];
    } else {
        _cn = @"";
        NSLog(@"Failed to find CN");
    }
	
	CK_ATTRIBUTE attributes[] = {
		{CKA_ID, nil, 0}
    };
	
    rv = functions->C_GetAttributeValue(session, object, attributes, ARRAY_LENGTH(attributes));
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
	
    NSMutableData* idData = [NSMutableData dataWithLength:attributes[1].ulValueLen];
    attributes[0].pValue = [idData mutableBytes];
	
    rv = functions->C_GetAttributeValue(session, object, attributes, ARRAY_LENGTH(attributes));
    if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
	
    _id = [NSData dataWithData:idData];
    
    return self;
}

@end
