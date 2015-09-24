//
//  Hop.m
//  Traceroute
//
//  Created by Christophe Janot on 06/06/13.
//  Copyright (c) 2013 Christophe Janot. All rights reserved.
//

#import "Hop.h"

@implementation Hop

static Hop *HopsManager;
static NSMutableArray *hops;

@synthesize hostAddress = _hostAddress;
@synthesize hostName = _hostName;
@synthesize ttl = _ttl;
@synthesize time = _time;

- (Hop *)initWithHostAddress:(NSString *)hostAddress hostName:(NSString *)hostName ttl:(int)ttl time:(int)time
{
    _hostAddress = hostAddress;
    _hostName = hostName;
    _ttl = ttl;
    _time = time;
    
    NSLog(@"Hop[%d]=%@ %dms",ttl,hostAddress,time);
    
    return self;
}

+ (Hop *)HopsManager
{
    if(!HopsManager) {
        HopsManager = [[self allocWithZone:NULL] init];
        hops = [[NSMutableArray alloc] init];
    }
    
    return HopsManager;
}

+ (Hop *)getHopAt:(int)pos
{
    //NSLog(@"getHopAt:%d",pos);
    if(pos >= [hops count]) {
        return [hops objectAtIndex:0];
    }
    return [hops objectAtIndex:pos];
}

/**
 * Ajoute un nouveau hop retourné par le traceroute.
 */
+ (void)addHop:(Hop *)hop
{
    [hops addObject:hop];
}

/**
 * Retourne le nombre de hops couramment trouvés
 */
+ (int)hopsCount
{
    return [hops count];
}

/**
 * Réinitialise la liste des hops
 */
+ (void)clear
{
    [hops removeAllObjects];
}

@end
