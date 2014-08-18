//
//  NSObject+RG_KeyedSubscripting.m
//  RestGoatee
//
//  Created by Ryan Dignard on 8/17/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//
#import "RestGoatee.h"

@implementation NSObject (RG_KeyedSubscripting)

- (id) objectForKeyedSubscript:(id<NSCopying, NSObject>)key {
    @try {
        return [self valueForKey:[key description]];
    }
    @catch (NSException* e) {
        return nil;
    }
}

- (void) setObject:(id)obj forKeyedSubscript:(id<NSCopying, NSObject>)key {
    @try {
        [self setValue:obj forKey:[key description]]; /* This is _intentionally_ not -setObject, -setValue is smarter; see the docs */
    }
    @catch (NSException* e) {}
}

@end
