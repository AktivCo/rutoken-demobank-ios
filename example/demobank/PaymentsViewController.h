//  Copyright (c) 2014 Aktiv Co. All rights reserved.

#import <UIKit/UIKit.h>

@interface PaymentsViewController : UIViewController {
    __weak IBOutlet UILabel *_tokenModelLabel;
    __weak IBOutlet UILabel *_tokenSerial;
    __weak IBOutlet UIImageView *_batteryChargeImage;
    __weak IBOutlet UILabel *_batteryPercentageLabel;
    __weak IBOutlet UILabel *_commonName;
}

@property(nonatomic) NSNumber* activeTokenHandle;


@end
