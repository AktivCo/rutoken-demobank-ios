//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@interface PinEnterViewController : UIViewController {
    
    __weak IBOutlet UITextField *_pinTextInput;
    __weak IBOutlet UILabel *_pinErrorLabel;
    __weak IBOutlet UIButton *_loginButton;
}

@property(nonatomic) NSNumber* activeTokenHandle;

@end
