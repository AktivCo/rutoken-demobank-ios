// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <UIKit/UIKit.h>
#import "Certificate.h"

@interface PaymentsTableViewController : UITableViewController

@property(nonatomic) NSNumber* activeTokenHandle;
@property(nonatomic) Certificate* choosenCert;

@end
