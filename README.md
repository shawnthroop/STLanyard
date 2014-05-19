STLanyard
=========

A simple wrapper for the iOS keychain.


I was about to start building a sharing service into an app but dealing with `(__bridge id)kSecAttrService` and `CFTypeRef` was getting the best of me. So, I created this to hide all that ugly confusing stuff. [JNKeychain](https://github.com/jeremangnr/JNKeychain) helped me understand how the keychain worked but was too basic for my needs. 

## Basic use

All of the examples below are taken from a current project of mine being built for App.net. Below I explain how to store user credentials (an accessToken) recieved after authenticating an account with [ADNKit](https://github.com/joeldev/ADNKit).


### Adding an Item

To add a keychain entry simply create a STLanyardObject:

    STLanyardObject *key = [[STLanyardObject alloc] initWithServiceID:@"App.net"
                                                            accountID:@"5253"
                                                            authToken:@"jsdf99sdfnnsdf8sdf"
                                                             username:@"shawnthroop"
                                                       keyDescription:@"Shawn Throop"
                                                               object:user];
Then add it to the keychain:

    [STLanyard saveLanyardObject:key];

**Note:** a serviceID and accountID are required when adding to an item to the keychain. These values are stored as item attributes and are used to access the item once it's been saved to the keychain. All other attributes are shuffled into a dictionary and archived as the keychain item's data attribute.



### Retrieving an Item

Retrieving an accessToken previously stored in the keychain under a user's userID (5253) is simple:

    STLanyardObject *key = [STLanyard lanyardObjectForService:@"App.net" accountID:userID];
    NSLog(@"accessToken: %@", key.authToken);

Simple.



### Retrieving Items for a Service

Accessing all keychain items associated with a specific service is easy:

    NSArray *keys = [STLanyard lanyardObjectsForService:@"App.net"];

This returns an immutable array of STLanyardObjects.



### Deleting an Item

Say I want to remove all authentication data from the keychain, but only for a certain service. 

    NSArray *keys = [STLanyard lanyardObjectsForService:@"App.net"];
    
    for (STLanyardObject *key in keys) {
        [STLanyard deleteLanyardObjectForService:@"App.net" accountID:key.accountID];
    }


---

*This is my first foray into the land of open source. Please let me know what I'm doing wrong.*



