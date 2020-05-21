//
//  TokenTableViewController.m
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright © 2019 Aktiv Co. All rights reserved.
//

#import "TokenTableViewController.h"

#import "CertTableViewController.h"

#import "TokenCard.h"

#import "UIColor+RutokenColors.h"

#import "TokenManager.h"
#import "Token.h"

#import <RtPcsc/rtnfc.h>

@interface TokenTableViewController ()

@property (weak, nonatomic) TokenManager* tokenManager;

@end

@implementation TokenTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tokenManager = [TokenManager sharedInstance];
}

- (void)updateState {
    for (NSNumber* handle in [self.tokenManager tokenHandles]) {
        Token* t = [self.tokenManager tokenForHandle:handle];
        if ([t certificates] == nil && ![t isLocked]) {
            if ([t type] == TokenTypeNFC && self.navigationController.topViewController != self) {
                continue;
            }
            [t readCertificatesWithSuccessCallback:^{
                [self updateState];
                if ([t type] == TokenTypeNFC) {
                    [t closeSession];
                    stopNFC();
                }
            } errorCallback:^(NSError * e) {
                NSLog(@"Error during certificate reading");
            }];
        }
    }
    [[self tableView] reloadData];
}

- (IBAction)addNfc:(id)sender {
    startNFC(^(NSError* error) {
        NSLog(@"%@",[error localizedDescription]);
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self.tokenManager tokenCount] > 0){
        self.tableView.backgroundView = nil;
        return 1;
    } else {
        CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        UILabel * messageLabel = [[UILabel alloc] initWithFrame:rect];
        messageLabel.text = @"Подключите токен для продолжения работы";
        messageLabel.numberOfLines = 2;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        
        self.tableView.backgroundView = messageLabel;
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tokenManager tokenCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TokenCard *tokenCard = [tableView dequeueReusableCellWithIdentifier:@"TokenCard" forIndexPath:indexPath];
    Token* token = [[self tokenManager] tokenForHandle:[[self tokenManager] tokenHandles][[indexPath row]]];
    
    tokenCard.tokenLabel.text = [token label];
    tokenCard.serialValue.text = [token serialNumber];

    if ([token type] == TokenTypeNFC) {
        tokenCard.chargeLabel.text = @"";
        tokenCard.chargeValue.text = @"";
    } else {
        tokenCard.chargeLabel.text = @"Заряд: ";
        tokenCard.chargeValue.text = [NSString stringWithFormat:@"%d%%", (int)[token charge]];
    }

    if ([token isLocked]) {
        tokenCard.certCountValue.text = @"🔒";
        [[tokenCard tokenView] setBackgroundColor:[UIColor rutokenMurenaColor]];
        [tokenCard setUserInteractionEnabled:YES];
    } else if ([token certificates]) {
        tokenCard.certCountValue.text = [NSString stringWithFormat:@"%lu", (unsigned long)[[token certificates] count]];
        [[tokenCard tokenView] setBackgroundColor:[UIColor rutokenMurenaColor]];
        [tokenCard setUserInteractionEnabled:YES];
    } else {
        tokenCard.certCountValue.text = @"⏳";
        [[tokenCard tokenView] setBackgroundColor:[UIColor rutokenLightGreyColor]];
        [tokenCard setUserInteractionEnabled:NO];
    }
 
    return tokenCard;
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Token * token = [self.tokenManager tokenForHandle:[[self tokenManager] tokenHandles][[indexPath row]]];
    if ([token isLocked]){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Активация защищенного канала"
                                                                       message:@"Введите пароль активации защищенного канала"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Пароль активации";
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        }];

        UIAlertAction* activateAction = [UIAlertAction actionWithTitle:@"Активировать" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            NSString* smPassword = [alert.textFields[0] text];
            TokenCard* tokenCard = [self.tableView cellForRowAtIndexPath:indexPath];
            tokenCard.certCountValue.text = @"⏳";
            [[tokenCard tokenView] setBackgroundColor:[UIColor rutokenLightGreyColor]];
            [tokenCard setUserInteractionEnabled:NO];
            [token activateSmWithPassword:smPassword successCallback:^{
                [self updateState];
            } errorCallback:^(NSError * e) {
                [self updateState];
                NSLog(@"Error during sm activation");
            }];
        }];
        [alert addAction:activateAction];

        UIAlertAction* rejectAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:rejectAction];

        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self performSegueWithIdentifier:@"toCertList" sender:[[self tokenManager] tokenHandles][[indexPath row]]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toCertList"]) {
        CertTableViewController* vc = segue.destinationViewController;
        [vc setTokenHandle:sender];
        [vc setCertificates: [[[self tokenManager] tokenForHandle:sender] certificates]];
    }
}

@end
