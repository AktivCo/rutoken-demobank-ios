//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <Foundation/Foundation.h>

#import <RtPKCS11ECP/rtpkcs11.h>

typedef NS_ENUM(NSInteger, EventType) {
	EventTypeTokenAdded,
	EventTypeTokenRemoved
};

@interface Pkcs11EventHandler : NSThread {
	CK_FUNCTION_LIST_PTR _functions;
	CK_FUNCTION_LIST_EXTENDED_PTR _extendedFunctions;
    void (^ _tokenAddedCallback)(CK_SLOT_ID);
    void (^ _tokenRemovedCallback)(CK_SLOT_ID);
	NSMutableDictionary* _lastSlotEvent;
}

- (id)initWithFunctions:(CK_FUNCTION_LIST_PTR)functions
      extendedFunctions:(CK_FUNCTION_LIST_EXTENDED_PTR)extendedFunctions
     tokenAddedCallback:(void (^)(CK_SLOT_ID))tokenAddedCallback
   tokenRemovedCallback:(void (^)(CK_SLOT_ID))tokenRemovedCallback;

@end
