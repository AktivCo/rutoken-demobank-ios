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
        Token* token = [_tokenManager tokenForHandle:_activeTokenHandle];
        NSString* tokenLabel;
        if([[token model] isEqualToString:@"Rutoken ECP BT"]) tokenLabel = @"Рутокен ЭЦП Bluetooth";
        else tokenLabel = @"Рутокен";
        
        NSUInteger decSerial;
        [[NSScanner scannerWithString:[token serialNumber]] scanHexInt:&decSerial];
        NSString* decSerialString = [NSString stringWithFormat:@"0%u", decSerial];
        tokenLabel = [NSString stringWithFormat:@"%@ %@", tokenLabel, [decSerialString substringFromIndex:[decSerialString length] -5]];
        [_tokenModelLabel setText:tokenLabel];
        [_commonNameLabel setText:@"Иванов Иван Иванович"];
        [_loginButton setHidden:NO];
        [_loginButton setTitle:@"Войти" forState:UIControlStateNormal];
        [_pinTextInput setHidden:NO];
        
        if(YES == [token charging]) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_charge.png"]];
        else if ([token charge] > 80) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_4_sec.png"]];
        else if ([token charge] <= 80 && [token charge] > 60 ) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_3_sec.png"]];
        else if ([token charge] <= 60 && [token charge] > 40) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_2_sec.png"]];
        else if ([token charge] <= 40 && [token charge] > 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_1_sec.png"]];
        else if ([token charge] <= 20) [_batteryChargeImage setImage: [UIImage imageNamed:@"battery_empty.png"]];

    }
}

- (IBAction)loginToken:(id)sender {
    [_loginButton setEnabled:NO];
    Token* token =[_tokenManager tokenForHandle:_activeTokenHandle];
    Certificate* cert = [[token certificates] objectAtIndex:0];
    
    NSString* authString = @"Auth Me";
    NSData* authData = [NSData dataWithBytes:[authString UTF8String] length:[authString length]];
    
    if(nil != token && nil != cert){
        [token login:[_pinTextInput text] successCallback:^(void){
            [token sign:cert data:authData successCallback:^(NSData * result) {
                [_loginButton setEnabled:YES];
                [_pinIncorrectLabel setHidden:YES];
                [_pinTextInput setText:@""];
            } errorCallback:^(NSError * e) {
                [_pinTextInput setText:@""];
                [_pinIncorrectLabel setHidden:NO];
                [_pinIncorrectLabel setText:@"Что-то не так с сертификатом"];
                [_loginButton setEnabled:YES];
            }];
        } errorCallback:^(NSError * e) {
            [_pinTextInput setText:@""];
            [_pinIncorrectLabel setHidden:NO];
            [_pinIncorrectLabel setText:@"ПИН введен неверно"];
            [_loginButton setEnabled:YES];
        }];
    }
}

-(void)wipeAllLabels{
    [_tokenModelLabel setText:@""];
    [_statusInfoLabel setText:@""];
    [_commonNameLabel setText:@""];
    [_batteryChargeImage setImage:nil];
    [_loginButton setHidden:YES];
    [_loginButton setTitle:@"" forState:UIControlStateNormal];
    [_pinTextInput setHidden:YES];
    [_pinIncorrectLabel setHidden:YES];
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
    Token* token = [_tokenManager tokenForHandle:handle];
    
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
        NSArray* ids = [_tokenManager tokenHandles];
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
