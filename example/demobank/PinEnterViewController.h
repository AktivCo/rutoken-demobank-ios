// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <UIKit/UIKit.h>

@interface PinEnterViewController : UIViewController {
    
    __weak IBOutlet UITextField *_pinTextInput;
    __weak IBOutlet UILabel *_pinErrorLabel;
    __weak IBOutlet UIButton *_loginButton;
}

@property(nonatomic) NSNumber* activeTokenHandle;

@end
