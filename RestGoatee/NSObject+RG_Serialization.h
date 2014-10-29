//
//  NSObject+RG_Serialization.h
//  RestGoatee
//
//  Created by Ryan Dignard on 8/17/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

@interface NSObject (RG_SerializationPublic)

/**
 @abstract returns the receiver represented as a dictionary with its property names as keys and the values are the values of that property.  By default the parser will follow weak references.
 */
- (NSDictionary*) dictionaryRepresentation;

/**
 @abstract returns the recevier serialized to JSON.
 */
- (NSData*) JsonRepresentation;

/**
 @abstract equivalent to `-dictionaryRepresentation` but the parser will not parse into objects which are `weak`, `assign`, or `unsafe_unretained` if the parameter `weakReferences` is `NO`.  The default is `YES`.
 */
- (NSDictionary*) dictionaryRepresentationShouldFollowWeakReferences:(BOOL)weakReferences;

@end
