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
    _tokenState = kTokenDisconnected;
    _connectingTokens = 0;
    [self wipeAllLabels];
    
    _delegate = [[BluetoothDelegate alloc] init];
	_manager = [[CBCentralManager alloc] initWithDelegate:_delegate queue:nil];
	_tokenManager = [TokenManager sharedInstance];
    
    [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:_tokenState];

	[_tokenManager start];
}

-(void)setStatewithBluetooth:(bool)bluetoothPoweredOn tokenState:(TokenState)tokenState{
    [self wipeAllLabels];
    if(false == bluetoothPoweredOn){
        [_statusInfoLabel setText:@"Для работы с демобанком включите bluetooth"];
    } else if (kTokenDisconnected == tokenState){
        [_statusInfoLabel setText:@"Для работы с демобанком подключите токен"];
    } else if (kTokenConnecting == tokenState) {
        [_statusInfoLabel setText:@"Токен подключается..."];
    } else if (kTokenConnected == tokenState) {
        Token* token = [_tokenManager tokenForId:_activeTokenHandle];
        [_tokenModelLabel setText:[token model]];
        NSUInteger decSerial;
        [[NSScanner scannerWithString:[token serialNumber]] scanHexInt:&decSerial];
        NSString* decSerialString = [NSString stringWithFormat:@"0%u", decSerial];
        [_tokenSerialNumberLabel setText:[decSerialString substringFromIndex:[decSerialString length]-5]];
    }
}

-(void)wipeAllLabels{
    [_tokenModelLabel setText:@""];
    [_tokenSerialNumberLabel setText:@""];
    [_statusInfoLabel setText:@""];
}

- (void)bluetoothWasPoweredOn:(NSNotification*)notification {
    [self setStatewithBluetooth:YES  tokenState:_tokenState];
	NSLog(@"Bluetooth was powered on");
}

- (void)bluetoothWasPoweredOff:(NSNotification*)notification {
    [self setStatewithBluetooth:NO  tokenState:_tokenState];
    NSLog(@"Bluetooth was powered off");
}

- (void)tokenWasAdded:(NSNotification*)notification {
    _connectingTokens--;
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* handle = [userInfo objectForKey:@"handle"];
    Token* token = [_tokenManager tokenForId:handle];
    
    if(nil == _activeTokenHandle) {
        _activeTokenHandle = handle;
        [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:kTokenConnected];
    }
    
    NSLog(@"Info for token with handle %d was loaded: \"Model: %@, Serial: %@, Label: %@\"", [handle intValue], [token model], [token serialNumber], [token label]);
}

- (void)tokenWasRemoved:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	NSNumber* handle = [userInfo objectForKey:@"handle"];
    
    if(handle == _activeTokenHandle){
        NSArray* ids = [_tokenManager tokenIds];
        if(0 != [ids count]){
            _activeTokenHandle = [ids objectAtIndex:0];
            [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:kTokenConnected];
        } else {
            _activeTokenHandle = nil;
            if(0 == _connectingTokens) [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:kTokenDisconnected];
            else [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:kTokenConnecting];
        }
    }
    
    NSLog(@"Token with handle %d was removed", [handle intValue]);
}

- (void)tokenWillBeAdded:(NSNotification*)notification {
    _connectingTokens++;
    if(nil == _activeTokenHandle) {
        [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:kTokenConnecting];
    }
    NSLog(@"New token detected");
}

- (void)tokenAddingFailed:(NSNotification*)notification {
    _connectingTokens--;
    if(nil == _activeTokenHandle && 0 == _connectingTokens){
        [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:kTokenDisconnected];
    }
    NSLog(@"Error while loading token info");
}

@end
