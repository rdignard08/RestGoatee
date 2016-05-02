/* Copyright (c) 05/01/2016, Ryan Dignard
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

#import <RestGoatee-Core/RestGoatee-Core.h>

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
