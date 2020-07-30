//
//  TokenCard.h
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright (c) 2020, Aktiv-Soft JSC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TokenCard : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *tokenLabel;
@property (weak, nonatomic) IBOutlet UILabel *certCountValue;
@property (weak, nonatomic) IBOutlet UILabel *serialValue;
@property (weak, nonatomic) IBOutlet UILabel *chargeLabel;
@property (weak, nonatomic) IBOutlet UILabel *chargeValue;
@property (weak, nonatomic) IBOutlet UIView *tokenView;

@end
