//
//  CertTableViewController.m
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright © 2019 Aktiv Co. All rights reserved.
//

#import "CertTableViewController.h"

#import "PinEnterViewController.h"

#import "UIColor+RutokenColors.h"

#import "CertCard.h"
#import "Certificate.h"
#import "TokenManager.h"
#import "Token.h"

@interface CertTableViewController ()

@property (weak, nonatomic) TokenManager* tokenManager;

@end

@implementation CertTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tokenManager = [TokenManager sharedInstance];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([[[[self tokenManager] tokenForHandle:self.tokenHandle] certificates] count] > 0){
        self.tableView.backgroundView = nil;
        return 1;
    } else {
        CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        UILabel * messageLabel = [[UILabel alloc] initWithFrame:rect];
        messageLabel.text = @"На токене нет сертификатов";
        messageLabel.numberOfLines = 2;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        
        self.tableView.backgroundView = messageLabel;
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray* certs = [[[self tokenManager] tokenForHandle:self.tokenHandle] certificates];
    return [certs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CertCard *certCard = [tableView dequeueReusableCellWithIdentifier:@"CertCard" forIndexPath:indexPath];
    [[certCard certView] setBackgroundColor:[UIColor rutokenMurenaColor]];
    Certificate* cert = [[[self tokenManager] tokenForHandle:self.tokenHandle] certificates][[indexPath row]];
    
    certCard.commonName.text = [cert cn];
    
    return certCard;
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"toLogin" sender:[[[self tokenManager] tokenForHandle:self.tokenHandle] certificates][[indexPath row]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PinEnterViewController* vc = [segue destinationViewController];
    [vc setActiveTokenHandle:self.tokenHandle];
    [vc setChoosenCert:sender];
}

@end
