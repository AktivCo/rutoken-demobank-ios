//
//  TokenTableViewController.m
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright © 2019 Aktiv Co. All rights reserved.
//

#import "TokenTableViewController.h"

#import "CertViewController.h"

#import "TokenCard.h"

#import "TokenManager.h"
#import "Token.h"

@interface TokenTableViewController ()

@property (weak, nonatomic) TokenManager* tokenManager;

@end

@implementation TokenTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tokenManager = [TokenManager sharedInstance];
}

- (void)updateState {
    
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
        // messageLabel.sizeToFit();
        
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
    tokenCard.chargeValue.text = [NSString stringWithFormat:@"%d%", (int)[token charge]];
    tokenCard.certCountValue.text = [NSString stringWithFormat:@"%d", [[token certificates] count]];
 
    return tokenCard;
}
#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"toCertList" sender:[[self tokenManager] tokenHandles][[indexPath row]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toCertList"]) {
        CertViewController* vc = segue.destinationViewController;
        vc.tokenHandle = sender;
    }
}

@end
