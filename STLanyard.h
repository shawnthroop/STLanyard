//
//  STLanyard.h
//
//  Created by Shawn Throop on 2014-05-19.
//  Copyright (c) 2014 Silent H Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STLanyardKey : NSObject

@property (nonatomic, readonly) NSString *serviceID;
@property (nonatomic, readonly) NSString *accountID;
@property (nonatomic, readonly) NSString *keyDescription;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) id<NSCoding> object;

@property (nonatomic, readonly) NSDictionary *meta;

- (id)initWithServiceID:(NSString *)serviceID accountID:(NSString *)accountID authToken:(NSString *)authToken username:(NSString *)username keyDescription:(NSString *)keyDescription object:(id<NSCoding>)object;

- (id)initWithServiceID:(NSString *)serviceID accountID:(NSString *)accountID authToken:(NSString *)authToken username:(NSString *)username keyDescription:(NSString *)keyDescription;
- (id)initWithServiceID:(NSString *)serviceID accountID:(NSString *)accountID;

@end


@interface STLanyard : NSObject

+ (void)saveKey:(STLanyardKey *)key;
+ (STLanyardKey *)keyForService:(NSString *)serviceID accountID:(NSString *)accountID;
+ (void)deleteKeyForService:(NSString *)serviceID accountID:(NSString *)accountID;
+ (NSArray *)keysForService:(NSString *)serviceID;


@end
