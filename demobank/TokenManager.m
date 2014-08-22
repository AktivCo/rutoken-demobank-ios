//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "TokenManager.h"

@implementation TokenManager

+(TokenManager*)sharedInstance{
	static dispatch_once_t runOnce;
	static id sharedObject = nil;
	dispatch_once(&runOnce, ^{
        sharedObject = [[self alloc] init];
    });
	
	return sharedObject;
}

-(void)start{
	//Start all activities for monitoring tokens' events
}

-(void)stop{
	//Stop all activities for monitoring tokens' events
}

-(NSArray*)serials{
	//Return serials for all know tokens
	return nil;
}
-(Token*)tokenForSerial:(NSString*)serial{
	//Return token for given serial
	return nil;
}

-(void)proccessEventTokenAddedAtSlot:(CK_SLOT_ID)id{
	//Proccess token adding here
}
-(void)proccessEventTokenRemovedAtSlot:(CK_SLOT_ID)id{
	//Proccess token removing here
}

@end
