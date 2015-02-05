/* Copyright (c) 6/10/14, Ryan Dignard
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

@class NSManagedObjectContext;

@protocol RestGoateeSerialization <NSObject>

@optional
/**
 @abstract Provide any overrides for default mapping behavior here.  The returned dictionary should have keys and values of type NSString and should be read left-to-right JSON source to target key.  Any unspecified key(s) will use the default behavior for mapping.
 
  Instance mappings will override class mappings if both are implemented.
 */
+ (NSDictionary*) overrideKeysForMapping;

/**
 @abstract Provide any overrides for default mapping behavior here.  The returned dictionary should have keys and values of type NSString and should be read left-to-right JSON source to target key.  Any unspecified key(s) will use the default behavior for mapping.  You are highly encouraged to implement this with a `dispatch_once()` block.
 
 Instance mappings will override class mappings if both are implemented.
 */
- (NSDictionary*) overrideKeysForMapping;

/**
 @abstract Provide a custom date format for use with the given property `key`.  See documentation for NSDate for proper formats.
 
 Instance mappings will override class mappings if both are implemented.
 */
+ (NSString*) dateFormatForKey:(NSString*)key;

/**
 @abstract Provide a custom date format for use with the given property `key`.  See documentation for NSDate for proper formats.
 
 Instance mappings will override class mappings if both are implemented.
 */
- (NSString*) dateFormatForKey:(NSString*)key;

@end

@interface NSObject (RG_Deserialization)

/**
 @deprecated use `+[NSObject objectFromDataSource:inContext]` instead
 @abstract subclasses of `NSManagedObject` must use this method since they cannot be initialized without a context.
 */
+ (instancetype) objectFromJSON:(NSDictionary*)json inContext:(NSManagedObjectContext*)context __attribute__((deprecated));

/**
 @abstract subclasses of `NSManagedObject` must use this method since they cannot be initialized without a context.
 */
+ (instancetype) objectFromDataSource:(id<RGDataSourceProtocol>)source inContext:(NSManagedObjectContext*)context;

/**
 @deprecated use `+[NSObject objectFromDataSource:]` instead
 @abstract the receiver (the Class object) which receives this method will attempt to initialize an instance of this class with properties assigned from json.
 */
+ (instancetype) objectFromJSON:(NSDictionary*)json __attribute__((deprecated));

/**
 @abstract the receiver (the Class object) which receives this method will attempt to initialize an instance of this class with properties assigned from a data source.
 */
+ (instancetype) objectFromDataSource:(id<RGDataSourceProtocol>)source;

/**
 @abstract merges two objects into a single object.  The return value is not a new object, but rather is the receiver augmented with the values in `object`.
 @param object Can be of type NSDictionary or the receiving type.
 @return the receiving object extended with `object`; any conflicts will take `object`'s value as precedent.
 */
- (instancetype) extendWith:(id)object;

- (instancetype) extendWith:(id)object inContext:(NSManagedObjectContext*)context;

@end
