//
//  NSObject+RG_KeyedSubscripting.h
//  RestGoatee
//
//  Created by Ryan Dignard on 8/17/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

@interface NSObject (RG_KeyedSubscripting)

/**
 @abstract returns the property or instance variable of the name given by `key`.
 */
- (id) objectForKeyedSubscript:(id<NSCopying, NSObject>)key;

/**
 @abstract set the value of the particular property or instance variable specified by `key`.
 */
- (void) setObject:(id)obj forKeyedSubscript:(id<NSCopying, NSObject>)key;

@end
