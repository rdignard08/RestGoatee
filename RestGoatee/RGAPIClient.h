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

/**
 The `RGResponseBlock` type specifies the common handler type for all methods declared in `RGAPIClient`.
 */
typedef void(^RGResponseBlock)(RGResponseObject*);

@protocol RGSerializationDelegate, RGResponseDelegate;
@class NSManagedObjectContext, NSURLSessionConfiguration;

/**
 The RGAPIClient is a subclass of either `AFHTTPSessionManager` or `AFRequestOperationManager` depending on the project's deployment target.  Method calls through this class (specifically those declared at the RGAPIClient level) will attempt to automatically deserialize objects from a raw information type into a type specified by the user.
 */
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9)
@interface RGAPIClient : AFHTTPSessionManager
#else
@interface RGAPIClient : AFHTTPRequestOperationManager
#endif

/**
 If the instance was constructed with `-initWithBaseURL:sessionConfiguration:` this will contain whatever object from provided for the `configuration` parameter.  Due to the implementation, this value cannot be modified after initialization.
 */
@property (nonatomic, strong, readonly) NSURLSessionConfiguration* sessionConfiguration;

/**
 You must provide a `serializationDelegate` if you intend to use your API client to unique check, parse XML, or create NSManagedObjects.  All others may safely ignore this property.
 */
@property (nonatomic, weak) id<RGSerializationDelegate> serializationDelegate;

/**
 designated initializer.  For deployment targets <= iOS 6, pass `nil` for `configuration` or use `-initWithBaseURL:`.
 */
- (instancetype) initWithBaseURL:(NSURL*)url sessionConfiguration:(NSURLSessionConfiguration*)configuration;

/**
 @abstract GET the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 @abstract GET the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context completion:(RGResponseBlock)completion;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract POST to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 @abstract POST the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context completion:(RGResponseBlock)completion;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract PUT to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 @abstract PUT to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context completion:(RGResponseBlock)completion;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract DELETE the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 @abstract DELETE the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context completion:(RGResponseBlock)completion;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate;

/**
 @abstract Provide a delegate object which will be called when a success or failure occured.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param delegate the object which will be called in the event of success or failure.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls context:(NSManagedObjectContext*)context delegate:(id<RGResponseDelegate>)delegate;

@end

/**
 Methods declared in this category allow the caller to not specify any parameters which would be `nil` or `Nil` in the full call.
 */
@interface RGAPIClient (RGConvenience)

/**
 Call `GET` with no `keyPath` useful if your API returns just an array of objects.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `GET` with no `parameters`.
 */
- (void) GET:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `GET` with no `keyPath` and no `parameters`.
 */
- (void) GET:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `POST` with no `keyPath` useful if your API returns just an array of objects.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `POST` with no `parameters`.
 */
- (void) POST:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `POST` with no `keyPath` and no `parameters`.
 */
- (void) POST:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `PUT` with no `keyPath` useful if your API returns just an array of objects.
 */
- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `PUT` with no `parameters`.
 */
- (void) PUT:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `PUT` with no `keyPath` and no `parameters`.
 */
- (void) PUT:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `DELETE` with no `keyPath` useful if your API returns just an array of objects.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `DELETE` with no `parameters`.
 */
- (void) DELETE:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion;

/**
 Call `DELETE` with no `keyPath` and no `parameters`.
 */
- (void) DELETE:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion;


/* No frills methods... */

/**
 Call `GET` with no response processing using a block.
 */
- (void) GET:(NSString*)url completion:(RGResponseBlock)completion;

/**
 Call `GET` with no response processing using a delegate.
 */
- (void) GET:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;

/**
 Call `POST` with no response processing using a block.
 */
- (void) POST:(NSString*)url completion:(RGResponseBlock)completion;

/**
 Call `POST` with no response processing using a delegate.
 */
- (void) POST:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;

/**
 Call `PUT` with no response processing using a block.
 */
- (void) PUT:(NSString*)url completion:(RGResponseBlock)completion;

/**
 Call `PUT` with no response processing using a delegate.
 */
- (void) PUT:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;

/**
 Call `DELETE` with no response processing using a block.
 */
- (void) DELETE:(NSString*)url completion:(RGResponseBlock)completion;

/**
 Call `DELETE` with no response processing using a delegate.
 */
- (void) DELETE:(NSString*)url delegate:(id<RGResponseDelegate>)delegate;

@end

/**
 If you prefer the delegate pattern over the block pattern you may provide a delegate implementing these methods.
 */
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

/**
 Certain requests to the API require additional information that might not be available in a standard request.
 
 `NSManagedObjectContext` is required for use with classes which are subclasses of `NSManagedObject`.
 
 Unique checking can be performed here as well.
 
 Finally you may enable XML parsing by implementing `-shouldSerializeXML` and returning `YES`.
 */
@protocol RGSerializationDelegate <NSObject>

@optional
/**
 Implement this method if you wish to provide a context for response objects which are subclasses of `NSManagedObject`.  Types other than `NSManagedObject` are not queried.
 */
- (NSManagedObjectContext*) contextForManagedObjectType:(Class)cls;

/**
 Return a non-`nil` key to have `NSManagedObject`s be reconciled to an existing object if the value of this key matches.
 */
- (NSString*) keyForReconciliationOfType:(Class)cls;

/**
 Enable basic XML to JSON parsing. If you want the `NSXMLParser` it will be passed back as the `responseBody` when `NO`.  Defaults to `NO`.
 */
- (BOOL) shouldSerializeXML;

@end
