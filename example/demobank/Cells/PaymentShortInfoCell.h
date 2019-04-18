#import <UIKit/UIKit.h>

@interface PaymentShortInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *recipient;
@property (weak, nonatomic) IBOutlet UILabel *sum;

+(NSInteger)getCellHeight;

-(void)fillPaymentCellWithDate:(NSString*)date recipient:(NSString*)recipient sum:(NSString*)sum;

@end
