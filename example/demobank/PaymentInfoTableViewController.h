// Copyright (c) 2015, CJSC Aktiv-Soft. See https://download.rutoken.ru/License_Agreement.pdf
// All Rights Reserved.

#import <UIKit/UIKit.h>

@interface PaymentInfoTableViewController : UITableViewController{
    
    __weak IBOutlet UILabel *_costLabel;
}

@property(nonatomic) NSNumber* activeTokenHandle;

@end
