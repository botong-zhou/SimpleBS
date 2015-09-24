//
//  BDHost.h
//  TraceRoute
//
//  Created by Christophe Janot on 06/06/13.
//  Copyright (c) 2013 Christophe Janot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BDHost : NSObject

+ (NSString *)addressForHostname:(NSString *)hostname;
+ (NSString *)addressesForHostname:(NSString *)hostname;
+ (NSString *)hostnameForAddress:(NSString *)address;
+ (NSArray *)hostnamesForAddress:(NSString *)address;
+ (NSArray *)ipAddresses;
+ (NSArray *)ethernetAddresses;

@end
