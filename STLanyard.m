//
//  STLanyard.m
//
//  Created by Shawn Throop on 2014-05-19.
//  Copyright (c) 2014 Silent H Design. All rights reserved.
//

#import "STLanyard.h"


NSString * const kAuthTokenString = @"kAuthToken";
NSString * const kUsernameString = @"kUsername";
NSString * const kKeyDescriptionString = @"kKeyDescription";
NSString * const kObjectString = @"kObject";


#pragma mark - STLanyardObject -

@interface STLanyardKey ()
{
    NSString *serviceID_;
    NSString *accountID_;
    NSDictionary *meta_;
}

@end

@implementation STLanyardKey

- (id)initWithServiceID:(NSString *)serviceID accountID:(NSString *)accountID authToken:(NSString *)authToken username:(NSString *)username keyDescription:(NSString *)keyDescription object:(id<NSCoding>)object
{
    self = [super init];
    if (self) {
        NSAssert(serviceID, @"Must provide a serviceID for lookup");
        
        serviceID_ = [serviceID copy];
        accountID_ = [accountID copy];
        
        NSMutableDictionary *meta = [NSMutableDictionary new];
        if (authToken) {
            [meta setObject:[authToken copy] forKey:kAuthTokenString];
        }
        
        if (username) {
            [meta setObject:[username copy] forKey:kUsernameString];
        }
        
        if (keyDescription) {
            [meta setObject:[keyDescription copy] forKey:kKeyDescriptionString];
        }
        
        if (object) {
            [meta setObject:object forKey:kObjectString];
        }
        
        meta_ = meta;
    }
    return self;
}

- (id)initWithServiceID:(NSString *)serviceID accountID:(NSString *)accountID authToken:(NSString *)authToken username:(NSString *)username keyDescription:(NSString *)keyDescription
{
    return [self initWithServiceID:serviceID accountID:accountID authToken:authToken username:username keyDescription:keyDescription object:nil];
}

- (id)initWithServiceID:(NSString *)serviceID accountID:(NSString *)accountID meta:(NSDictionary *)meta
{
    return [self initWithServiceID:serviceID
                         accountID:accountID
                         authToken:meta[kAuthTokenString]
                          username:meta[kUsernameString]
                    keyDescription:meta[kKeyDescriptionString]
                            object:meta[kObjectString]];
}

- (id)initWithServiceID:(NSString *)serviceID accountID:(NSString *)accountID
{
    return [self initWithServiceID:serviceID accountID:accountID authToken:nil username:nil keyDescription:nil object:nil];
}




- (NSString *)description
{
    NSString *string = [NSString stringWithFormat:@"<%@> - %@", [self class], self.serviceID];
    if (self.accountID) {
        string = [string stringByAppendingFormat:@" accountID: %@", self.accountID];
    }
    
    if (self.username) {
        string  = [string stringByAppendingFormat:@" - %@", self.username];
    }
    
    return string;
}




- (NSUInteger)hash
{
    return [self.serviceID hash] ^ [self.accountID hash] ^ [self.meta hash];
}




- (BOOL)isEqual:(id)obj
{
    if(![obj isKindOfClass:[STLanyardKey class]]) {
        return NO;
    }
    
    STLanyardKey *key = (STLanyardKey *)obj;
    
    BOOL serviceIsEqual = (!self.serviceID && !key.serviceID) || [self.serviceID isEqualToString:key.serviceID];
    BOOL accountIsEqual = (!self.accountID && !key.accountID) || [self.accountID isEqualToString:key.accountID];
    return serviceIsEqual && accountIsEqual;
}




#pragma mark - Properties


- (NSString *)serviceID
{
    return [serviceID_ copy];
}

- (NSString *)accountID
{
    return [accountID_ copy];
}

- (NSString *)authToken
{
    return [[meta_ objectForKey:kAuthTokenString] copy];
}

- (NSString *)username
{
    return [[meta_ objectForKey:kUsernameString] copy];
}

- (NSString *)keyDescription
{
    return [[meta_ objectForKey:kKeyDescriptionString] copy];
}

- (id<NSCoding>)object
{
    return [meta_ objectForKey:kObjectString];
}

- (NSDictionary *)meta
{
    return [meta_ copy];
}

@end





#pragma mark - STLanyard -


@interface STLanyard ()

+ (NSMutableDictionary *)getKeychainQueryForService:(NSString *)serviceID withAccountID:(NSString *)accountID;
+ (NSMutableDictionary *)getKeychainQueryForKey:(STLanyardKey *)key;

@end


@implementation STLanyard


#pragma mark Public

+ (void)saveKey:(STLanyardKey *)key
{
    NSAssert(key.accountID, @"Must provide an accountID when saving a key to the keychain");
    
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForKey:key];

    // delete any previous value with this key
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    
    // archive and add the key's meta as the data object
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:key.meta] forKey:(__bridge id)kSecValueData];
    
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}




+ (STLanyardKey *)keyForService:(NSString *)serviceID accountID:(NSString *)accountID
{
    NSAssert(serviceID, @"Must provide an accountID when querying the keychain for a single item");

    NSMutableDictionary *keychainQuery = [self getKeychainQueryForService:serviceID withAccountID:accountID];
    CFDataRef keyData = NULL;
    
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    NSDictionary *meta = nil;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            meta = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *e) {
            NSLog(@"<STLanyard> Error: could not unarchive metadata for serivce: \"%@\" accountID: \"%@\" - %@", serviceID, accountID, e);
            meta = nil;
        }
        @finally {}
    } else {
        NSLog(@"<STLanyard> Error: keychain item for service: \"%@\" accountID: \"%@\" not found", serviceID, accountID);
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    STLanyardKey *key = [[STLanyardKey alloc] initWithServiceID:serviceID
                                                      accountID:accountID
                                                           meta:meta];
    
    // if meta is nil, there was an error
    return meta == nil ? nil : key;
}




+ (void)deleteKeyForService:(NSString *)service accountID:(NSString *)accountID
{
    NSAssert(accountID, @"Must provide an accountID when querying the keychain for a single item");

    NSMutableDictionary *keychainQuery = [self getKeychainQueryForService:service withAccountID:accountID];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}




+ (NSArray *)keysForService:(NSString *)serviceID
{
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForService:serviceID withAccountID:nil];
    CFTypeRef keyData = NULL;
    
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
    
    NSMutableArray *lanyardObjects = nil;
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        NSArray *serviceAccounts = [NSArray arrayWithArray:(__bridge id)keyData];
        
        if (serviceAccounts && serviceAccounts.count > 0) {
            lanyardObjects = [NSMutableArray new];
            
            for (NSDictionary *account in serviceAccounts) {
                
                NSDictionary *meta = nil;
                @try {
                    meta = [NSKeyedUnarchiver unarchiveObjectWithData:[account objectForKey:(__bridge id)kSecValueData]];
                }
                @catch (NSException *e) {
                    NSLog(@"<STLanyard> Error: could not unarchive metadata for serivce: \"%@\" accountID: \"%@\" - %@", serviceID, account[(__bridge id)kSecAttrAccount], e);
                }
                @finally {}
                
                if (meta) {
                    STLanyardKey *key = [[STLanyardKey alloc] initWithServiceID:account[(__bridge id)kSecAttrService]
                                                                      accountID:account[(__bridge id)kSecAttrAccount]
                                                                           meta:meta];
                    [lanyardObjects addObject:key];
                }
            }
        }
        
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    return (lanyardObjects == nil || lanyardObjects.count == 0) ? nil : [lanyardObjects copy];
}



#pragma mark Private

// see http://developer.apple.com/library/ios/#DOCUMENTATION/Security/Reference/keychainservices/Reference/reference.html

+ (NSMutableDictionary *)getKeychainQueryForKey:(STLanyardKey *)key
{
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                                          (__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
                                          key.serviceID, (__bridge id)kSecAttrService, nil];
    
    if (key.accountID) {
        [keychainQuery setObject:key.accountID forKey:(__bridge id)kSecAttrAccount];
    }
    
    return keychainQuery;
}




+ (NSMutableDictionary *)getKeychainQueryForService:(NSString *)serviceID withAccountID:(NSString *)accountID
{
    return [self getKeychainQueryForKey:[[STLanyardKey alloc] initWithServiceID:serviceID accountID:accountID]];
}


@end
