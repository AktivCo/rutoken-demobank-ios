//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@interface PaymentInfoTableViewController : UITableViewController{
    
    __weak IBOutlet UILabel *_costLabel;
}

@property(nonatomic) NSNumber* activeTokenHandle;

@end
