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

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
@interface RGAPIClient : AFHTTPSessionManager
#else
@interface RGAPIClient : AFHTTPRequestOperationManager
#endif

@property (nonatomic, weak) id<RGSerializationDelegate> serializationDelegate;

/**
 @abstract GET the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract POST to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract PUT to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract DELETE the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion; /* This is the full variant */

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (NSArray/NSDictionary); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

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


/* No frills methods... */

- (void) GET:(NSString*)url completion:(RGResponseBlock)completion;
- (void) GET:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;
- (void) POST:(NSString*)url completion:(RGResponseBlock)completion;
- (void) POST:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;
- (void) PUT:(NSString*)url completion:(RGResponseBlock)completion;
- (void) PUT:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;
- (void) DELETE:(NSString*)url completion:(RGResponseBlock)completion;
- (void) DELETE:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;

@end

@protocol RGResponseDelegate <NSObject>

@required

/**
 Called as part of the success procedure after all deserialization has taken place.

 @param task For deployment targets at iOS 7 and above, the type is `NSURLSessionDataTask*`.  For earlier versions the type is `AFHTTPRequestOperation*`.
 */
- (void) response:(RGResponseObject*)response receivedForRequest:(id)task;

/**
 Called when an error occurs, and will attempt to include as much information as possible in `response`.

 @param task For deployment targets at iOS 7 and above, the type is `NSURLSessionDataTask*`.  For earlier versions the type is `AFHTTPRequestOperation*`.
 */
- (void) response:(RGResponseObject*)response failedForRequest:(id)task;

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
