//
//  CertCard.h
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright (c) 2020, Aktiv-Soft JSC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CertCard : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *commonName;
@property (weak, nonatomic) IBOutlet UIView *certView;

@end
