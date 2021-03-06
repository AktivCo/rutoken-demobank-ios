#import "NavigationController.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "TokenManager.h"
#import "Token.h"

#import "TokenTableViewController.h"

#import "MBProgressHUD.h"

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
    CBCentralManagerState state = (CBCentralManagerState)[central state];
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

@interface NavigationController ()

@property (nonatomic)  MBProgressHUD * hud;

@end

@implementation NavigationController

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
    
    _hud = nil;
    
    _delegate = [[BluetoothDelegate alloc] init];
    _manager = [[CBCentralManager alloc] initWithDelegate:_delegate queue:nil];
    _tokenManager = [TokenManager sharedInstance];
    
    [self updateRootViewController];
    
    [_tokenManager startMonitoring];
}

-(void)updateRootViewController {
    TokenTableViewController* rootVC = [[self viewControllers] objectAtIndex:0];
    [rootVC updateState];
}

- (void)bluetoothWasPoweredOn:(NSNotification*)notification {
    [self updateRootViewController];
    NSLog(@"Bluetooth was powered on");
}

- (void)bluetoothWasPoweredOff:(NSNotification*)notification {
    [self updateRootViewController];
    NSLog(@"Bluetooth was powered off");
}

- (void)tokenWasAdded:(NSNotification*)notification {
    _connectingTokens--;
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* handle = [userInfo objectForKey:@"handle"];
    Token* token = [_tokenManager tokenForHandle:handle];
    
    if([_tokenManager tokenCount] == 1) {
        if(nil != self.hud) {
            self.hud.labelText = @"Токен подключен";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-checkmark.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];
            self.hud = nil;
        }
    }
    [self updateRootViewController];
    
    NSLog(@"Info for token with handle %d was loaded: \"Model: %@, Serial: %@, Label: %@\"", [handle intValue], [token model], [token serialNumber], [token label]);
}

- (void)tokenWasRemoved:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* handle = [userInfo objectForKey:@"handle"];
    [self updateRootViewController];
    [self popToRootViewControllerAnimated:YES];
    NSLog(@"Token with handle %d was removed", [handle intValue]);
}

- (void)tokenWillBeAdded:(NSNotification*)notification {
    _connectingTokens++;
    if([_tokenManager tokenCount] == 0 && _connectingTokens == 1) {
        self.hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.hud];

        self.hud.labelText = @"Подключение токена...";
        self.hud.dimBackground = YES;
        self.hud.mode = MBProgressHUDModeIndeterminate;
        self.hud.animationType = MBProgressHUDAnimationZoomIn;
        self.hud.minSize = CGSizeMake(150.f, 150.f);

        [self.hud show:YES];
    }
    NSLog(@"New token detected");
}

- (void)tokenAddingFailed:(NSNotification*)notification {
    _connectingTokens--;
    if([_tokenManager tokenCount] == 0 && _connectingTokens == 0) {
        if(nil != self.hud) {
            self.hud.labelText = @"Произошла ошибка";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];
            self.hud = nil;
        }
    }
    NSLog(@"Error while loading token info");
}

@end
