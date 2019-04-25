//
//  UIColor+RutokenColors.h
//  demobank
//
//  Created by Андрей Трифонов on 25/04/2019.
//  Copyright © 2019 Aktiv Co. All rights reserved.
//

#ifndef UIColor_RutokenColors_h
#define UIColor_RutokenColors_h

#import <UIKit/UIKit.h>

//Define rutoken colors
@implementation UIColor (RutokenColors)

+ (UIColor *)rutokenRedColor {
    return [UIColor colorWithRed:221/255.0 green:34/255.0 blue:51/255.0 alpha:1.0];
}

+ (UIColor *)rutokenMurenaColor {
    return [UIColor colorWithRed:17/255.0 green:119/255.0 blue:136/255.0 alpha:1.0];
}

+ (UIColor *)rutokenLightGreyColor {
    return [UIColor colorWithRed:136/255.0 green:136/255.0 blue:136/255.0 alpha:1.0];
}

+ (UIColor *)rutokenGreyColor {
    return [UIColor colorWithRed:68/255.0 green:68/255.0 blue:68/255.0 alpha:1.0];
}

+ (UIColor *)rutokenWhiteColor {
    return [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
}

@end


#endif /* UIColor_RutokenColors_h */
