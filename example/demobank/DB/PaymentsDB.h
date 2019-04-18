#import <Foundation/Foundation.h>

@interface PaymentsDB : NSObject

+(PaymentsDB*)sharedInstance;

-(NSArray*)getPayments;

-(NSString*)getDateByIndex:(NSUInteger)index;
-(NSString*)getRecipientByIndex:(NSUInteger)index;
-(NSString*)getSumByIndex:(NSUInteger)index;

@end
