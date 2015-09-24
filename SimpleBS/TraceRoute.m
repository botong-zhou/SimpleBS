//
//  TraceRoute.m
//  Traceroute
//
//  Created by Christophe Janot on 06/06/13.
//  Copyright (c) 2013 Christophe Janot. All rights reserved.
//

#import "TraceRoute.h"
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/time.h>
#import "BDHost.h"

@implementation TraceRoute

- (TraceRoute *)initWithMaxTTL:(int)ttl timeout:(int)timeout maxAttempts:(int)attempts port:(int)port
{
    [Hop HopsManager];
    maxTTL = ttl;
    udpPort = port;
    readTimeout = timeout;
    maxAttempts = attempts;
    
    return self;
}

/**
 * Exécution totalement paramétrée du traceroute.
 */
- (Boolean)doTraceRouteToHost:(NSString *)host maxTTL:(int)ttl timeout:(int)timeout maxAttempts:(int)attempts port:(int)port
{
    maxTTL = ttl;
    udpPort = port;
    readTimeout = timeout;
    maxAttempts = attempts;
    return [self doTraceRoute:host];
}

/**
 * Exécution du traceroute.
 */
- (Boolean)doTraceRoute:(NSString *)host
{
    struct hostent *host_entry = gethostbyname(host.UTF8String);
    char *ip_addr;
    ip_addr = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
    struct sockaddr_in destination,fromAddr;
    int recv_sock;
    int send_sock;
    Boolean error = false;
    
    isrunning = true;
    // On vide le cache des hops du précédente recherche
    [Hop clear];
    
    // Création de la socket destinée à traiter l'ICMP renvoyée.
    if ((recv_sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)) < 0) {
        if(_delegate != nil) {
            [_delegate error:@"Could not create recv socket"];
        }
        return false;
    }
    // Création de la socket destinée à l'émission des trames HTTP.
    if((send_sock = socket(AF_INET , SOCK_DGRAM,0))<0){
        if(_delegate != nil) {
            [_delegate error:@"Could not create xmit socket"];
        }
        return false;
    }
    memset(&destination, 0, sizeof(destination));
    destination.sin_family = AF_INET;
    destination.sin_addr.s_addr = inet_addr(ip_addr);
    destination.sin_port = htons(udpPort);
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = readTimeout;
    setsockopt(recv_sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,sizeof(struct timeval));
    char *cmsg = "GET / HTTP/1.1\r\n\r\n";
    socklen_t n= sizeof(fromAddr);
    char buf[100];
    
    // index sur le TTL en cours de traitement.
    int ttl = 1;
    
    bool icmp = false;  // Positionné à true lorsqu'on reçoit la trame ICMP en retour.
    Hop *routeHop;
    long startTime;     // Timestamp lors de l'émission du GET HTTP
    int delta;          // Durée de l'aller-retour jusqu'au hop.
    
    // On progresse jusqu'à un nombre de TTLs max.
    while(ttl <= maxTTL) {
        memset(&fromAddr, 0, sizeof(fromAddr));
        if(setsockopt(send_sock, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl)) < 0) {
            error = true;
            if(_delegate != nil) {
                [_delegate error:@"setsockopt failled"];
            }
        }
        
        icmp = false;
        
        // On effectue plusieurs tentatives si on n'obtient pas de réponse avant le timeout.
        for(int try = 0;try < maxAttempts;try++) {
            delta = -1;
            startTime = [TraceRoute getMicroSeconds];
            if (sendto(send_sock,cmsg,sizeof(cmsg),0,(struct sockaddr *) &destination,sizeof(destination)) != sizeof(cmsg) ) {
                error = true;
                NSLog (@"WARN in send to...\n@");
            }
            int res = 0;
            
            if( (res = recvfrom(recv_sock, buf, 100, 0, (struct sockaddr *)&fromAddr,&n))<0) {
                // Erreur réseau ou timeout
                error = true;
                NSLog(@"WARN [%d/%d] %s; recvfrom returned %d\n", try, maxAttempts, strerror(errno), res);
            } else {
                // On a reçu une trame ICMP. on calcule le temps total entre l'envoi et la réception.
                delta = [TraceRoute computeDurationSince:startTime];
                char display[16]={0};
                // On flag pour spécifier qu'une trame ICMP a bien été reçue.
                icmp = true;
                
                // On décode l'adresse du hop ayant répondu.
                inet_ntop(AF_INET, &fromAddr.sin_addr.s_addr, display, sizeof (display));
                NSString *hostAddress = [NSString stringWithFormat:@"%s",display];
                NSString *hostName = [BDHost hostnameForAddress:hostAddress];
                
                routeHop = [[Hop alloc] initWithHostAddress:hostAddress hostName:hostName ttl:ttl time:delta];
                [Hop addHop:routeHop];
                
                break;
            }
            // On teste si l'utilisateur a demandé l'arrêt du traceroute
            @synchronized(running) {
                if(!isrunning) {
                    ttl = maxTTL;
                    // On force le statut d'icmp pour ne pas générer un Hop en sortie de boucle;
                    icmp = true;
                    break;
                }
            }
        }
        // Détection d'un timeout sur non réponse
        if(!icmp) {
            routeHop = [[Hop alloc] initWithHostAddress:@"*" hostName:@"*" ttl:ttl time:-1];
            [Hop addHop:routeHop];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_delegate != nil) {
                [_delegate newHop:routeHop];
            }
        });
        ttl++;
    }
    isrunning = false;
    // On averti le delegate que le traceroute est terminé.
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate end];
    });
    return error;
}

/**
 * Méthode demandant l'arrêt du traceroute.
 */
- (void)stopTrace
{
    @synchronized(running) {
        isrunning = false;
    }
}

/**
 * Retourne le nombre de hops couramment trouvés
 */
+ (int)hopsCount
{
    return [Hop hopsCount];
}

/**
 * Retourne un boolean indiquant si le traceroute est toujours actif.
 */
- (bool)isRunning
{
    return isrunning;
}

/**
 * Retourne un timestamp en microsecondes.
 */
+ (long)getMicroSeconds
{
    struct timeval time;
    gettimeofday(&time, NULL);
    return time.tv_usec;
}

/**
 * Calcule une durée en millisecondes par rapport au timestamp passé en paramètre.
 */
+ (long)computeDurationSince:(long)uTime
{
    long now = [TraceRoute getMicroSeconds];
    if(now < uTime) {
        return 1000000 - uTime + now;
    }
    return now - uTime;
}

@end
