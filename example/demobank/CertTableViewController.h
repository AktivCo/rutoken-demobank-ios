//
//  CertTableViewController.h
//  demobank
//
//  Created by Андрей Трифонов on 16/04/2019.
//  Copyright (c) 2020, Aktiv-Soft JSC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CertTableViewController : UITableViewController

@property (nonatomic, readwrite) NSNumber* tokenHandle;
@property (nonatomic, readwrite) NSMutableArray* certificates;

@end

