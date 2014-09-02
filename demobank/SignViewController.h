//
//  SignViewController.h
//  demobank
//
//  Created by Андрей Трифонов on 02.09.14.
//  Copyright (c) 2014 Aktiv Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignViewController : UIViewController {
    
    __weak IBOutlet UILabel *_welcomeLabel;
    __weak IBOutlet UIButton *_loginButton;
    __weak IBOutlet UITextField *_pinTextInput;
    __weak IBOutlet UILabel *_successLabel;
    __weak IBOutlet UILabel *_pinIncorrect;
    __weak IBOutlet UIActivityIndicatorView *_progressIndicator;
    __weak IBOutlet UILabel *_progressLabel;
    __weak IBOutlet UILabel *_errorLabel;
    BOOL _loggedOff;

}

@property(nonatomic) NSNumber* activeTokenHandle;
@property(nonatomic) BOOL askPin;
@property(nonatomic) UINavigationController* navigation;

@end
