// Copyright (c) 2020, Aktiv-Soft JSC. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import "PaymentsTableViewController.h"

#import "PaymentInfoTableViewController.h"

#import "PaymentShortInfoCell.h"

#import "PaymentsDB.h"

#include "Token.h"
#include "TokenManager.h"

@implementation PaymentsTableViewController

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PaymentsDB* paymentsDB = [PaymentsDB sharedInstance];

    return [[paymentsDB getPayments] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (CGFloat)[PaymentShortInfoCell getCellHeight];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = @"PaymentShortInfoCell";
    PaymentShortInfoCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        [tableView registerNib:[UINib nibWithNibName:cellIdentifier bundle:nil] forCellReuseIdentifier:cellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }

    NSInteger index = [indexPath row];
    PaymentsDB* paymentsDB = [PaymentsDB sharedInstance];

    [cell fillPaymentCellWithDate:[paymentsDB getDateByIndex:index] recipient:[paymentsDB getRecipientByIndex:index] sum:[paymentsDB getSumByIndex:index]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"toPaymentInfo" sender:[NSNumber numberWithInteger:[indexPath row]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"toPaymentInfo"]){
        PaymentInfoTableViewController* vc = [segue destinationViewController];
        [vc setActiveTokenHandle:_activeTokenHandle];
        [vc setPaymentNumber:sender];
        [vc setChoosenCert:_choosenCert];
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [[[TokenManager sharedInstance] tokenForHandle:_activeTokenHandle] logoutWithSuccessCallback:^(void){}
                                                                                       errorCallback:^(NSError* e){ NSLog(@"%@", e.description); }];
    }

    [super viewWillDisappear:animated];
}


@end
