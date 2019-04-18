#import "PaymentShortInfoCell.h"

@implementation PaymentShortInfoCell

+(NSInteger)getCellHeight {
    return 55;
}

- (void)fillPaymentCellWithDate:(NSString*)date
                      recipient:(NSString*)recipient
                            sum:(NSString*)sum {
    [_date setText:date];
    [_recipient setText:recipient];
    [_sum setText:sum];
}

@end
