//
//  CertViewController.h
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright © 2019 Aktiv Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TokenManager;

NS_ASSUME_NONNULL_BEGIN

@interface CertViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *certButton;
@property (nonatomic, readwrite) NSNumber* tokenHandle;

@end

NS_ASSUME_NONNULL_END
