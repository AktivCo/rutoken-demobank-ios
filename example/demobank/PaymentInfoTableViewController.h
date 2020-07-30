// Copyright (c) 2020, Aktiv-Soft JSC. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <UIKit/UIKit.h>
#import "Certificate.h"

@interface PaymentInfoTableViewController : UITableViewController

@property(nonatomic) NSNumber* activeTokenHandle;
@property (nonatomic) NSNumber* paymentNumber;
@property(nonatomic) Certificate* choosenCert;


@end
