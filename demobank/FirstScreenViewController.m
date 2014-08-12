//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "FirstScreenViewController.h"

#import <CoreBluetooth/CoreBluetooth.h>

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
	_delegate = [[BluetoothDelegate alloc] init];
	_manager = [[CBCentralManager alloc] initWithDelegate:_delegate queue:nil];

}

- (void)bluetoothWasPoweredOn:(NSNotification*)notification {
	//handle bluetooth powering ON here
	[_blueToothState setText:@"BlueTooth is on"];
}

- (void)bluetoothWasPoweredOff:(NSNotification*)notification {
	//handle bluetooth powering OFF here
	[_blueToothState setText:@"BlueTooth is off"];
}

@end
