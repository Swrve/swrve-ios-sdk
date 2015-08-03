//
//  ISHPermissionRequestAddressBook.m
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 02.07.14.
//  Modified by Swrve Mobile Inc.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#include <UIKit/UIKit.h>
#include <objc/runtime.h>
#import <AddressBook/AddressBook.h>
#ifdef __IPHONE_9_0
#import <Contacts/Contacts.h>
#endif
#import "ISHPermissionRequestAddressBook.h"
#import "ISHPermissionRequest+Private.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation ISHPermissionRequestAddressBook {
    ABAddressBookRef _addressBook;
#ifdef __IPHONE_9_0
    CNContactStore* _contactStore;
#endif
}

- (ISHPermissionState)permissionState {
#ifdef __IPHONE_9_0
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        // New iOS9+ framework
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        switch (status) {
            case CNAuthorizationStatusAuthorized:
                return ISHPermissionStateAuthorized;
                
            case CNAuthorizationStatusRestricted:
            case CNAuthorizationStatusDenied:
                return ISHPermissionStateDenied;
                
            case CNAuthorizationStatusNotDetermined:
                return [self internalPermissionState];
        }
    }
#endif
    
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    switch (status) {
        case kABAuthorizationStatusAuthorized:
            return ISHPermissionStateAuthorized;
            
        case kABAuthorizationStatusRestricted:
        case kABAuthorizationStatusDenied:
            return ISHPermissionStateDenied;
            
        case kABAuthorizationStatusNotDetermined:
            return [self internalPermissionState];
    }
}

- (void)requestUserPermissionWithCompletionBlock:(ISHPermissionRequestCompletionBlock)completion {
    NSAssert(completion, @"requestUserPermissionWithCompletionBlock requires a completion block", nil);
    ISHPermissionState currentState = self.permissionState;
    
    if (!ISHPermissionStateAllowsUserPrompt(currentState)) {
        completion(self, currentState, nil);
        return;
    }
    
#ifdef __IPHONE_9_0
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        // New iOS9+ framework
        if (_contactStore == nil) {
            _contactStore = [[CNContactStore alloc] init];
        }
        [_contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *__nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self, granted ? ISHPermissionStateAuthorized : ISHPermissionStateDenied, error);
            });
        }];
        return;
    }
#endif
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(self, granted ? ISHPermissionStateAuthorized : ISHPermissionStateDenied, (__bridge NSError *)(error));
        });
    });
}

- (ABAddressBookRef)addressBook {
    if (!_addressBook) {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        
        if (addressBook) {
            if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
                [self setAddressBook:CFAutorelease(addressBook)];
            } else {
                // CFAutoRelease not supported on iOS6 so we need to use this awful code!
                SEL autorelease = sel_getUid("autorelease");
                IMP imp = class_getMethodImplementation(object_getClass((__bridge id)addressBook), autorelease);
                ((CFTypeRef (*)(CFTypeRef, SEL))imp)(addressBook, autorelease);
            }
        }
    }
    
    return _addressBook;
}

- (void)setAddressBook:(ABAddressBookRef)newAddressBook {
    if (_addressBook != newAddressBook) {
        if (_addressBook) {
            CFRelease(_addressBook);
        }
        
        if (newAddressBook) {
            CFRetain(newAddressBook);
        }
        
        _addressBook = newAddressBook;
    }
}

- (void)dealloc {
    if (_addressBook) {
        CFRelease(_addressBook);
        _addressBook = NULL;
    }
}

@end
