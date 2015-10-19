// Copyright (c) 2015, CJSC Aktiv-Soft. See the LICENSE file at the top-level directory of this distribution.
// All Rights Reserved.

#import "Certificate.h"

#import "Util.h"
#import "Pkcs11Error.h"

@interface NSString (toData)
- (NSData *)dataFromHexString;
@end

@implementation NSString (toData)

- (NSData *)dataFromHexString {
    const char *chars = [self UTF8String];
    int i = 0;
    unsigned long len = self.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

@end

@interface NSData (reversible)
- (NSData*) reversedData;
@end

@implementation NSData (reversible)

- (NSData*) reversedData
{
    NSData *myData = self;
    
    const char *bytes = [myData bytes];
    
    NSUInteger datalength = [myData length];
    
    char *reverseBytes = malloc(sizeof(char) * datalength);
    NSUInteger index = datalength - 1;
    
    for (int i = 0; i < datalength; i++)
        reverseBytes[index--] = bytes[i];
    
    NSData *reversedData = [NSData dataWithBytesNoCopy:reverseBytes length: datalength freeWhenDone:YES];
    
    return reversedData;
}

@end

@implementation Certificate

- (id)initWithSession:(CK_SESSION_HANDLE)session object:(CK_OBJECT_HANDLE)object {
	
    self = [super init];
    if (nil == self) return self;
	
	@try{
		unsigned long length = 0;
		unsigned char* data;
        
        CK_FUNCTION_LIST_PTR functions;
        CK_FUNCTION_LIST_EXTENDED_PTR extendedFunctions;
        
        C_GetFunctionList(&functions);
        C_EX_GetFunctionListExtended(&extendedFunctions);
        
		CK_RV rv = extendedFunctions->C_EX_GetCertificateInfoText(session, object, &data, &length);
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		
		NSString *cert=[[NSString alloc]initWithBytes:data length:length encoding:NSUTF8StringEncoding];
		
		rv = extendedFunctions->C_EX_FreeBuffer(data);
		
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Subject: [A-Za-z,=]*?CN=([^\n,]*)" options:NSRegularExpressionCaseInsensitive error:&error];
		NSTextCheckingResult *match = [regex firstMatchInString:cert options:0 range:NSMakeRange(0, [cert length])];
		
		if (match != nil) {
			_cn = [cert substringWithRange:[match rangeAtIndex:1]];
		} else {
			_cn = @"";
			NSLog(@"Failed to find CN");
		}
        
        NSRegularExpression *regexX = [NSRegularExpression regularExpressionWithPattern:@"X:([0-9A-F]*)\n" options:0 error:&error];
        NSRegularExpression *regexY = [NSRegularExpression regularExpressionWithPattern:@"Y:([0-9A-F]*)\n" options:0 error:&error];
        NSTextCheckingResult *matchX = [regexX firstMatchInString:cert options:0 range:NSMakeRange(0, [cert length])];
        NSTextCheckingResult *matchY = [regexY firstMatchInString:cert options:0 range:NSMakeRange(0, [cert length])];
        
        if (matchX != nil && matchY != nil) {
            NSMutableData* valueData = [NSMutableData dataWithData:[[[cert substringWithRange:[matchX rangeAtIndex:1]] dataFromHexString] reversedData]];
            [valueData appendData:[[[cert substringWithRange:[matchY rangeAtIndex:1]] dataFromHexString] reversedData]];
            _value = [NSData dataWithData:valueData];
        } else {
            _value = nil;
            NSLog(@"Failed to find value");
        }
		
		CK_ATTRIBUTE attributes[] = {
			{CKA_ID, nil, 0}
		};
		
		rv = functions->C_GetAttributeValue(session, object, attributes, ARRAY_LENGTH(attributes));
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		
		NSMutableData* idData = [NSMutableData dataWithLength:attributes[0].ulValueLen];
		attributes[0].pValue = [idData mutableBytes];
		
		rv = functions->C_GetAttributeValue(session, object, attributes, ARRAY_LENGTH(attributes));
		if (CKR_OK != rv) @throw [Pkcs11Error errorWithCode:rv];
		
        _id = [NSData dataWithData:idData];
        
		return self;
		
	} @catch (NSError* e){
		NSLog(@"Error in certificate's init, reason: %d (%@)", [e code], [e localizedDescription]);
		return nil;
	}
}

@end
