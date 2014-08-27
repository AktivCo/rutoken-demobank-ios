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
	
    _activeTokenHandle = nil;
    [_tokenModelLabel setText:@""];
    [_tokenSerialNumberLabel setText:@""];
    [_statusInfoLabel setText:@""];
    
	_delegate = [[BluetoothDelegate alloc] init];
	_manager = [[CBCentralManager alloc] initWithDelegate:_delegate queue:nil];
	_tokenManager = [TokenManager sharedInstance];

	[_tokenManager start];
}

- (void)bluetoothWasPoweredOn:(NSNotification*)notification {
	//handle bluetooth powering ON here
    [_statusInfoLabel setText:@"Для работы с демобанком подключите токен"];
	NSLog(@"Bluetooth was powered on");
}

- (void)bluetoothWasPoweredOff:(NSNotification*)notification {
	//handle bluetooth powering OFF here
    [_statusInfoLabel setText:@"Для работы с демобанком включите bluetooth"];
    NSLog(@"Bluetooth was powered off");
}

- (void)tokenWasAdded:(NSNotification*)notification {
	//handle token adding here
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* handle = [userInfo objectForKey:@"handle"];
    Token* token = [_tokenManager tokenForId:handle];
    
    if(nil == _activeTokenHandle) {
        _activeTokenHandle = handle;
        [_tokenModelLabel setText:[token model]];
        NSUInteger decSerial;
        [[NSScanner scannerWithString:[token serialNumber]] scanHexInt:&decSerial];
        NSString* decSerialString = [NSString stringWithFormat:@"0%u", decSerial];
        [_tokenSerialNumberLabel setText:[decSerialString substringFromIndex:[decSerialString length]-5]];
        [_statusInfoLabel setText:@""];
    }
    
    NSLog(@"Info for token with handle %d was loaded: \"Model: %@, Serial: %@, Label: %@\"", [handle intValue], [token model], [token serialNumber], [token label]);
}

- (void)tokenWasRemoved:(NSNotification*)notification {
	//handle token removing here
	NSDictionary* userInfo = [notification userInfo];
	NSNumber* handle = [userInfo objectForKey:@"handle"];
    if(handle == _activeTokenHandle){
        _activeTokenHandle = nil;
        [_statusInfoLabel setText:@"Для работы с демобанком подключите токен"];
        [_tokenModelLabel setText:@""];
        [_tokenSerialNumberLabel setText:@""];
    }
    
    NSLog(@"Token with handle %d was removed", [handle intValue]);
}

- (void)tokenWillBeAdded:(NSNotification*)notification {
	//be ready to adding new token here
    NSLog(@"New token detected");
}

- (void)tokenAddingFailed:(NSNotification*)notification {
	//handle slot error here
    NSLog(@"Error while loading token info");
}

@end
