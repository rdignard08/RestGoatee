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
#import <AFNetworking/AFNetworking.h>
#import "RGResponseObject.h"

typedef void(^RGResponseBlock)(RGResponseObject*);

@protocol RGSerializationDelegate, RGResponseDelegate;
@class NSManagedObjectContext;

@interface RGAPIClient : AFHTTPSessionManager

@property (nonatomic, weak) id<RGSerializationDelegate> serializationDelegate;
@property (nonatomic, weak) id<RGResponseDelegate> responseDelegate;

/**
 Explicitly specify the destination class and request parameters.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

/**
 Explicitly specify the destination class and request parameters.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

/**
 Explicitly specify the destination class and request parameters.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

/**
 Explicitly specify the destination class and request parameters.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

@end

@interface RGAPIClient (RGConvenience)
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;
- (void) GET:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;
- (void) GET:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;
- (void) POST:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;
- (void) POST:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;

- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;
- (void) PUT:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;
- (void) PUT:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;

- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;
- (void) DELETE:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;
- (void) DELETE:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;
@end

@protocol RGResponseDelegate <NSObject>

/**
 Called as part of the success procedure after all deserialization has taken place.
 */
- (void) response:(RGResponseObject*)response receivedForRequest:(NSURLSessionDataTask*)task;

/**
 Called when an error occurs, and will attempt to include as much information as possible in `response`.
 */
- (void) response:(RGResponseObject*)response failedForRequest:(NSURLSessionDataTask*)task;

@end

@protocol RGSerializationDelegate <NSObject>

/**
 Implement this method if you wish to provide a context for response objects which are subclasses of NSManagedObject.  Types other than NSManagedObject are not queried.
 */
- (NSManagedObjectContext*) contextForManagedObjectType:(Class)cls;

/**
 Return a non-`nil` key to have managed objects be reconciled to an existing object if the value of this key matches.
 */
- (NSString*) keyForReconciliationOfType:(Class)cls;

@end