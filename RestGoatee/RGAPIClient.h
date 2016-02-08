/* Copyright (c) 06/10/2014, Ryan Dignard
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
typedef void(^RGResponseBlock)(RGResponseObject* RG_SUFFIX_NONNULL);

@protocol RGSerializationDelegate;
@class NSManagedObjectContext, NSURLSessionConfiguration;

/**
 The RGAPIClient is a subclass of `AFHTTPSessionManager`.  Method calls through this class (specifically those declared at the RGAPIClient level) will attempt to automatically deserialize objects from a raw information type into a type specified by the user.
 */
@interface RGAPIClient : AFHTTPSessionManager

/**
 You must provide a `serializationDelegate` if you intend to use your API client to unique check, parse XML, or create NSManagedObjects.  All others may safely ignore this property.
 */
@property RG_NULLABLE_PROPERTY(nonatomic, weak) id<RGSerializationDelegate> serializationDelegate;

/**
 This is the primitive method that underlies all requests made by this class.  It is agnostic of the super class.
 
 @param method a string of value @"GET", @"POST", @"PUT", @"DELETE", or anything supported by AFNetworking.
 
 @param url The url request; it may be implicitly relative to `baseURL`.  May not be `nil` pass @"" to request `baseURL` implicitly.
 
 @param parameters A dictionary of parameters to pass with the request.  With GET requests they are serialized to the query string.
 
 @param path A key path indicating where in the response body to find the desired response.  Pass `nil` for the full response.
 
 @param cls The type of the object or array of objects to be found at the specified key path `path`.  Pass `nil` to the raw `NSArray` or `NSDictionary` response.  Must pass a context if `cls` is a subclass of `NSManagedObject`.
 
 @param completion The response block to be executed (either success or failure).  Pass `nil` if the response is not used.
 
 @param context The context used to insert or update existing `NSManagedObject` instances.  May be `nil` when the response class `cls` is not a subclass of `NSManagedObject`.  Raises an exception if `nil` and a subclass of `NSManagedObject` is desired.
 
 @param count The number of times this request has been made.  Should always pass 0.
 
 @throw `NSGenericException` when `cls` is a subclass of `NSMangagedObject` and `context` is `nil`.
 */
- (void) request:(RG_PREFIX_NONNULL NSString*)method
             url:(RG_PREFIX_NONNULL NSString*)url
      parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
         keyPath:(RG_PREFIX_NULLABLE NSString*)path
           class:(RG_PREFIX_NULLABLE Class)cls
      completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion
         context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
           count:(NSUInteger)count;

/**
 @abstract GET the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) GET:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @abstract GET the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) GET:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @abstract POST to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) POST:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @abstract POST the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) POST:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @abstract PUT to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) PUT:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @abstract PUT to the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) PUT:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @abstract DELETE the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) DELETE:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @abstract DELETE the specified relative endpoint.
 
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/`NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error condition.
 */
- (void) DELETE:(RG_PREFIX_NONNULL NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

@end

/**
 Certain requests to the API require additional information that might not be available in a standard request.
 
 An `NSManagedObjectContext` is required for use with classes which are subclasses of `NSManagedObject`.
 
 Unique checking can be performed here as well.
 
 Finally you may enable XML parsing by implementing `-shouldSerializeXML` and returning `YES`.
 */
@protocol RGSerializationDelegate <NSObject>

@optional
/**
 Implement this method if you wish to provide a context for response objects which are subclasses of `NSManagedObject`.  Types other than `NSManagedObject` are not queried.
 */
- (RG_PREFIX_NULLABLE NSManagedObjectContext*) contextForManagedObjectType:(RG_PREFIX_NONNULL Class)cls;

/**
 Implement this method to retry requests as determined by you.  Return `YES` to retry; `NO` otherwise.  Default is `NO` for all requests.
 
 @param request The request being retried. Contains the method, URL, and body as resolved by redirects.
 @param response The response that indicated failure.  Should be of type `NSHTTPURLResponse`, but you should type check anyway.
 @param error The error that failed the request.
 @param count The number of times this request has been retried before.
 */
- (BOOL) shouldRetryRequest:(RG_PREFIX_NONNULL NSURLRequest*)request response:(RG_PREFIX_NULLABLE NSURLResponse*)response error:(RG_PREFIX_NONNULL NSError*)error retryCount:(NSUInteger)count;

/**
 Return a non-`nil` key to have `NSManagedObject`s be reconciled to an existing object if the value of this key matches.
 */
- (RG_PREFIX_NULLABLE NSString*) keyForReconciliationOfType:(RG_PREFIX_NONNULL Class)cls;

/**
 Enable basic XML to JSON parsing. If you want the `NSXMLParser` it will be passed back as the `responseBody` when `NO`.  Defaults to `NO`.
 */
- (BOOL) shouldSerializeXML;

@end
