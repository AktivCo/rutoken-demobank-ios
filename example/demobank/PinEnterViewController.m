// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import "PinEnterViewController.h"

#import "TokenManager.h"
#import "Token.h"
#import "PaymentsViewController.h"

#import "MBProgressHUD.h"

@interface PinEnterViewController ()

@property (nonatomic)  MBProgressHUD * hud;

@end

@implementation PinEnterViewController

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
    [_pinErrorLabel setHidden:YES];
    
    TokenManager* tokenManager = [TokenManager sharedInstance];
    
    Token* token =[tokenManager tokenForHandle:_activeTokenHandle];
    NSArray* certs = [token certificates];
    if(0 == [certs count]){
        [_pinErrorLabel setHidden:NO];
        [_pinErrorLabel setText:@"На токене нет сертификатов"];
        [_loginButton setHidden:YES];
        [_pinTextInput setHidden:YES];
    } else {
        CFTypeRef item = NULL;
        NSDictionary* query = @{ (id)kSecClass: (id)kSecClassGenericPassword,
                                 (id)kSecAttrAccount: [token serialNumber],
                                 (id)kSecAttrService: @"demobank.rutoken.ru",
                                 (id)kSecReturnData: @YES,
                                 (id)kSecUseOperationPrompt: @"Доступ к сохраненному ПИН-коду",
                                 };
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &item);
        switch (status) {
            case errSecSuccess:
                [_pinTextInput setText:[NSString stringWithUTF8String:[(__bridge NSData *)item bytes]]];
                break;
            case errSecItemNotFound:
                break;
            default:
                NSLog(@"%@", CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
        }
    }
    
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
    self.hud.animationType = MBProgressHUDAnimationZoomIn;
    self.hud.dimBackground = YES;
    self.hud.minSize = CGSizeMake(150.f, 150.f);
    [self.view addSubview:self.hud];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard
{
    [_pinTextInput resignFirstResponder];
}

- (IBAction)_loginToken:(id)sender {
    [_loginButton setEnabled:NO];
    [self dismissKeyboard];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    TokenManager* tokenManager = [TokenManager sharedInstance];
    
    Token* token =[tokenManager tokenForHandle:_activeTokenHandle];
    Certificate* cert = [[token certificates] objectAtIndex:0];
    
    NSString* authString = @"Auth Me";
    NSData* authData = [NSData dataWithBytes:[authString UTF8String] length:[authString length]];
    
    self.hud.labelText = @"Проверяю PIN-код токена...";
    self.hud.mode = MBProgressHUDModeIndeterminate;
    [self.hud show:YES];
    
    if(nil != token && nil != cert){
        [token loginWithPin:[_pinTextInput text] successCallback:^(void){
            self.hud.labelText = @"Выполняю вход в ЛК...";
            [token signData:authData withCertificate:cert successCallback:^(NSData * result) {
                
                self.hud.labelText = @"Вход выполнен";
                self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-checkmark.png"]];
                self.hud.mode = MBProgressHUDModeCustomView;
                [self.hud hide:YES afterDelay:1.5];
                
                SecAccessControlRef access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, nil);
                
                NSDictionary* query = @{ (id)kSecClass: (id)kSecClassGenericPassword,
                                         (id)kSecValueData:[[_pinTextInput text] dataUsingEncoding:NSUTF8StringEncoding],
                                         (id)kSecAttrAccount: [token serialNumber],
                                         (id)kSecAttrService: @"demobank.rutoken.ru",
                                         (id)kSecAttrAccessControl: (__bridge id)access,
                                         };
                OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
                if (status == errSecDuplicateItem){
                    status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)query);
                    if (status != errSecSuccess)
                        NSLog(@"%@", CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
                } else if (status != errSecSuccess) {
                    NSLog(@"%@", CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
                }
                
                [_loginButton setEnabled:YES];
                [_pinErrorLabel setHidden:YES];
                [_pinErrorLabel setText:@""];
                [_pinTextInput setText:@""];
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                PaymentsViewController* vc =[[UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil] instantiateViewControllerWithIdentifier:@"PaymentsVC"];
                [vc setActiveTokenHandle:_activeTokenHandle];
                NSMutableArray *vcs = [[self.navigationController viewControllers] mutableCopy];
                NSUInteger lastVcIndex = [vcs count] - 1;
                if (lastVcIndex > 0) {
                    [vcs replaceObjectAtIndex:lastVcIndex withObject:vc];
                    [self.navigationController setViewControllers:vcs animated:YES];
                }
                //[self performSegueWithIdentifier:@"segueToPayments" sender:self];
            } errorCallback:^(NSError * e) {
                self.hud.labelText = @"Произошла ошибка";
                self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
                self.hud.mode = MBProgressHUDModeCustomView;
                [self.hud hide:YES afterDelay:1.5];
                
                [_pinTextInput setText:@""];
                [_pinErrorLabel setHidden:NO];
                [_pinErrorLabel setText:@"Что-то не так с сертификатом"];
                [_loginButton setEnabled:YES];
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }];
        } errorCallback:^(NSError * e) {
            self.hud.labelText = @"Произошла ошибка";
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-error.png"]];
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1.5];
            
            [_pinTextInput setText:@""];
            [_pinErrorLabel setHidden:NO];
            [_pinErrorLabel setText:@"ПИН введен неверно"];
            [_loginButton setEnabled:YES];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }];
    }    
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
