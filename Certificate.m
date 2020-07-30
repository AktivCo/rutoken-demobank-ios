// Copyright (c) 2020, Aktiv-Soft JSC. See the LICENSE file at the top-level directory of this distribution.
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

- (id)initWithSession:(CK_SESSION_HANDLE)session withObjectId:(CK_OBJECT_HANDLE)object withId:(NSData*)id withX509:(X509*)x509 {
    self = [super init];
    if (nil == self) return self;

    _id = id;
    _x509 = x509;

    int cnLength = X509_NAME_get_text_by_NID(X509_get_subject_name(_x509), NID_commonName, 0, 0);
    if (cnLength <= 0) {
        NSLog(@"Failed to find CN");
        _cn = @"";
    } else {
        cnLength += 1; // zero byte
        NSMutableData* cn = [NSMutableData dataWithLength:cnLength];
        X509_NAME_get_text_by_NID(X509_get_subject_name(_x509), NID_commonName, [cn mutableBytes], cnLength);
        _cn = [[NSString alloc] initWithCString:[cn mutableBytes] encoding:NSUTF8StringEncoding];
    }

    return self;
}

- (void)dealloc {
    X509_free(_x509);
}

@end
