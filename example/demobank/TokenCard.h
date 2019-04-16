//
//  TokenCard.h
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright © 2019 Aktiv Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TokenCard : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *tokenLabel;
@property (weak, nonatomic) IBOutlet UILabel *certCountValue;
@property (weak, nonatomic) IBOutlet UILabel *serialValue;
@property (weak, nonatomic) IBOutlet UILabel *chargeValue;

@end
