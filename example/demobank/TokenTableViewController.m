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

#import "TokenManager.h"
#import "Token.h"

//define rutoken colors
@implementation UIColor (Extensions)

+ (UIColor *)rutokenRedColor {
    return [UIColor colorWithRed:221/255.0 green:34/255.0 blue:51/255.0 alpha:1.0];
}

+ (UIColor *)rutokenMurenaColor {
    return [UIColor colorWithRed:17/255.0 green:119/255.0 blue:136/255.0 alpha:1.0];
}

+ (UIColor *)rutokenLightGreyColor {
    return [UIColor colorWithRed:136/255.0 green:136/255.0 blue:136/255.0 alpha:1.0];
}

+ (UIColor *)rutokenGreyColor {
    return [UIColor colorWithRed:68/255.0 green:68/255.0 blue:68/255.0 alpha:1.0];
}

+ (UIColor *)rutokenWhiteColor {
    return [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
}

@end

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
            [t readCertificatesWithSuccessCallback:^{
                [self updateState];
            } errorCallback:^(NSError * e) {
                NSLog(@"Error during certificate reading");
            }];
        }
    }
    [[self tableView] reloadData];
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
    tokenCard.chargeValue.text = [NSString stringWithFormat:@"%d%%", (int)[token charge]];
    if ([token isLocked]) {
        tokenCard.certCountValue.text = @"🔒";
        [[tokenCard tokenView] setBackgroundColor:[UIColor rutokenMurenaColor]];
        [tokenCard setUserInteractionEnabled:YES];
    } else if ([token certificates]) {
        tokenCard.certCountValue.text = [NSString stringWithFormat:@"%d", [[token certificates] count]];
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
    }
}

@end
