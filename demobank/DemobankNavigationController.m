//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import "DemobankNavigationController.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "TokenManager.h"
#import "FirstScreenViewController.h"

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

@implementation DemobankNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary* navBarTitleTextAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [UIColor whiteColor],UITextAttributeTextColor,
                                         [UIColor blackColor], UITextAttributeTextShadowColor,
                                         [NSValue valueWithUIOffset:UIOffsetMake(-1, 0)], UITextAttributeTextShadowOffset, nil];
    [[UINavigationBar appearance] setBarTintColor:[UIColor redColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:navBarTitleTextAttr];
    
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
    
    _delegate = [[BluetoothDelegate alloc] init];
	_manager = [[CBCentralManager alloc] initWithDelegate:_delegate queue:nil];
	_tokenManager = [TokenManager sharedInstance];
    
    [self setStatewithBluetooth:[_delegate poweredOn]  tokenState:_tokenState];
    
	[_tokenManager start];
}

-(void)setStatewithBluetooth:(bool)bluetoothPoweredOn tokenState:(TokenState)tokenState{
    FirstScreenViewController* rootVC = [[self viewControllers] objectAtIndex:0];
    if(false == bluetoothPoweredOn){
        [rootVC bluetoothWasPoweredOff];
    } else if (kTokenDisconnected == tokenState){
        [rootVC removeActiveToken];
    } else if (kTokenConnecting == tokenState) {
        [rootVC prepareForSettingAktiveToken];
    } else if (kTokenConnected == tokenState) {
        [rootVC setActiveTokenWithHandle:_activeTokenHandle];
    }
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
        [self popToRootViewControllerAnimated:YES];
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
