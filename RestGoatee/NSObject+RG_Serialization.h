//
//  NSObject+RG_Serialization.h
//  RestGoatee
//
//  Created by Ryan Dignard on 8/17/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

@interface NSObject (RG_Serialization)

/**
 @abstract returns the receiver represented as a dictionary with its property names as keys and the values are the values of that property.
 */
- (NSDictionary*) dictionaryRepresentation;

/**
 @abstract returns the recevier serialized to JSON.
 */
- (NSData*) JsonRepresentation;

@end
