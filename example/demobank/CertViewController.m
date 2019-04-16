//
//  CertViewController.m
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright © 2019 Aktiv Co. All rights reserved.
//

#import "CertViewController.h"

#import "PinEnterViewController.h"

#import "Certificate.h"
#import "TokenManager.h"
#import "Token.h"

@interface CertViewController ()

@end

@implementation CertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray* certs = [[[TokenManager sharedInstance] tokenForHandle:self.tokenHandle] certificates];
    if(0 != [certs count]){
        Certificate* cert = [certs objectAtIndex:0];
        [self.certButton setTitle:cert.cn forState:UIControlStateNormal];
    }
}

#pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 PinEnterViewController* vc = [segue destinationViewController];
     [vc setActiveTokenHandle:self.tokenHandle];
 }

@end
