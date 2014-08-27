//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "FirstScreenViewController.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "TokenManager.h"

@interface BluetoothDelegate : NSObject <CBCentralManagerDelegate> {
	BOOL _poweredOn;
}
@end

@implementation BluetoothDelegate

- (id)init {
	self = [super init];
	if (self) _poweredOn = NO;
	return self;
}

- (void)centralManagerDidUpdateState:(CBCentralManager*)central {
	CBCentralManagerState state = [central state];
	if (CBCentralManagerStatePoweredOn == state) {
		_poweredOn = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BluetoothWasPoweredOn" object:self];
	} else if (CBCentralManagerStatePoweredOff == state) {
		_poweredOn = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BluetoothWasPoweredOff" object:self];
	}
}

- (BOOL)poweredOn {
	return _poweredOn;
}

@end

@implementation FirstScreenViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothWasPoweredOff:)
												 name:@"BluetoothWasPoweredOff" object:_delegate];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothWasPoweredOn:)
												 name:@"BluetoothWasPoweredOn" object:_delegate];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenWasAdded:)
												 name:@"TokenWasAdded" object:_tokenManager];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenWasRemoved:)
												 name:@"TokenWasRemoved" object:_tokenManager];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenWillBeAdded:)
												 name:@"TokenWillBeAdded" object:_tokenManager];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenAddingFailed:)
												 name:@"TokenAddingFailed" object:_tokenManager];
	
	_delegate = [[BluetoothDelegate alloc] init];
	_manager = [[CBCentralManager alloc] initWithDelegate:_delegate queue:nil];
	_tokenManager = [TokenManager sharedInstance];
	[_tokenManager start];
}

- (void)bluetoothWasPoweredOn:(NSNotification*)notification {
	//handle bluetooth powering ON here
	[_textLogs setText:[NSString stringWithFormat:@"Bluetooth was powered on\n%@",[_textLogs text]]];
}

- (void)bluetoothWasPoweredOff:(NSNotification*)notification {
	//handle bluetooth powering OFF here
	[_textLogs setText:[NSString stringWithFormat:@"Bluetooth was powered off\n%@",[_textLogs text]]];
}

- (void)tokenWasAdded:(NSNotification*)notification {
	//handle token adding here
	NSDictionary* userInfo = [notification userInfo];
	NSNumber* handle = [userInfo objectForKey:@"handle"];
	Token* token = [_tokenManager tokenForId:handle];
	[_textLogs setText:[NSString stringWithFormat:@"Token info was loaded for token with handle %d:\n%@", [handle intValue],[_textLogs text]]];
	[_textLogs setText:[NSString stringWithFormat:@"Serial: %s\n%@", [[token serialNumber] UTF8String],[_textLogs text]]];
	[_textLogs setText:[NSString stringWithFormat:@"Label: %s\n%@", [[token label] UTF8String],[_textLogs text]]];
}

- (void)tokenWasRemoved:(NSNotification*)notification {
	//handle token removing here
	NSDictionary* userInfo = [notification userInfo];
	NSNumber* handle = [userInfo objectForKey:@"handle"];
	[_textLogs setText:[NSString stringWithFormat:@"Token with handle %d was removed\n%@", [handle intValue],[_textLogs text]]];
}

- (void)tokenWillBeAdded:(NSNotification*)notification {
	//be ready to adding new token here
	[_textLogs setText:[NSString stringWithFormat:@"New token detected\n%@",[_textLogs text]]];
}

- (void)tokenAddingFailed:(NSNotification*)notification {
	//handle slot error here
	[_textLogs setText:[NSString stringWithFormat:@"Something went wrong\n%@",[_textLogs text]]];
}

@end
