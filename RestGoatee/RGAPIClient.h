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

#import "AFNetworking.h"
#import "RGResponseObject.h"
#import "RGSerializationDelegate.h"

/**
 @brief The `RGResponseBlock` type specifies the common handler type for all methods declared in `RGAPIClient`.
 */
typedef void(^RGResponseBlock)(RGResponseObject* RG_SUFFIX_NONNULL);

@class NSManagedObjectContext, NSURLSessionConfiguration;

/**
 @brief The `RGAPIClient` is a manager of an instance of `AFHTTPSessionManager`.  Method calls through this class 
  (specifically those declared at the `RGAPIClient` level) will attempt to automatically deserialize objects from a raw
  information type into a type specified by the user.
 */
@interface RGAPIClient : NSObject

/**
 @brief an initializer using a base url and default `NSURLSessionConfiguration`.
 @param baseURL the url base onto which paths are added to create the full url.
 */
- (RG_PREFIX_NONNULL instancetype) initWithBaseURL:(RG_PREFIX_NULLABLE NSURL*)baseURL;

/**
 @brief an initializer using a base url and the provided configuration.
 @param baseURL the url base onto which paths are added to create the full url.
 @param configuration the configuration to be used to create the session.
 */
- (RG_PREFIX_NONNULL instancetype) initWithBaseURL:(RG_PREFIX_NULLABLE NSURL*)baseURL
                              sessionConfiguration:(RG_PREFIX_NULLABLE NSURLSessionConfiguration*)configuration;

/**
 @brief You must provide a `serializationDelegate` if you intend to use your API client to unique check, parse XML, or
  create `NSManagedObject`s.  All others may safely ignore this property.
 */
@property RG_NULLABLE_PROPERTY(nonatomic, weak) id<RGSerializationDelegate> serializationDelegate;

/**
 @brief The backing `AFHTTPSessionManager` which handles the raw requests.
 */
@property RG_NONNULL_PROPERTY(nonatomic, strong, readonly) AFHTTPSessionManager* manager;

/**
 @brief GET the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) GET:(RG_PREFIX_NONNULL NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @brief GET the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which GET is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to append to the url.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are
  `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) GET:(RG_PREFIX_NONNULL NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
     context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @brief POST to the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) POST:(RG_PREFIX_NONNULL NSString*)url
   parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
      keyPath:(RG_PREFIX_NULLABLE NSString*)path
        class:(RG_PREFIX_NULLABLE Class)cls
   completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @brief POST the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which POST is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are
  `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) POST:(RG_PREFIX_NONNULL NSString*)url
   parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
      keyPath:(RG_PREFIX_NULLABLE NSString*)path
        class:(RG_PREFIX_NULLABLE Class)cls
      context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
   completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @brief PUT to the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) PUT:(RG_PREFIX_NONNULL NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @brief PUT to the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which PUT is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are
  `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) PUT:(RG_PREFIX_NONNULL NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
     context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @brief DELETE the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) DELETE:(RG_PREFIX_NONNULL NSString*)url
     parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
        keyPath:(RG_PREFIX_NULLABLE NSString*)path
          class:(RG_PREFIX_NULLABLE Class)cls
     completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

/**
 @brief DELETE the specified relative endpoint.
 @param url a string relative to the base url which specifies the desired endpoint on which DELETE is to be performed.
 @param parameters a dictionary of key-value pairs (the values need not be strings) to place in the request body.
 @param path specify where in the response JSON to find the desired objects to be deserialized.  Unspecified will try to
  use the entire JSON response.
 @param cls the class into which the response should be deserialized.  Do not specify a foundation class (`NSArray`/
  `NSDictionary`); omit this argument if this is the desired behavior.
 @param context the `NSManagedObjectContext` to insert any `NSManagedObject`(s), use this for `cls` which are
  `NSManagedObjects`.
 @param completion This block will be called when the request complete either by succeeding or encountering some error
  condition.
 */
- (void) DELETE:(RG_PREFIX_NONNULL NSString*)url
     parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
        keyPath:(RG_PREFIX_NULLABLE NSString*)path
          class:(RG_PREFIX_NULLABLE Class)cls
        context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
     completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion;

@end
