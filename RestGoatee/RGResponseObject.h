/* Copyright (c) 7/25/14, Ryan Dignard
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

/**
 Encapsulate the complete response from a request to RGAPIClient.  The presence of `error` precludes `responseBody` from having a value.
 */
@interface RGResponseObject : NSObject

/**
 In the event of a successful request, this parameter will contain an array of the specified deserialization class.  If no deserialization class was specified or one could not be constructed it will contain the raw json response (up to the json keypath if it was specified).
 
 Otherwise `nil`.
 */
@property RG_NULLABLE_PROPERTY(nonatomic, strong) NSArray RG_GENERIC(__kindof NSObject*) * responseBody;

/**
 If there was an error, this will contain the highest level error.  The HTTP status code of the response can be found at `-HTTPStatusCode` if that was the reason for the error.
 
 Any response data that was available at the time of the error will be present on the property `extraData`.
 
 Otherwise `nil`.
 */
@property RG_NULLABLE_PROPERTY(nonatomic, strong) NSError* error;

/**
 If the type of the provided deserialization class is a subclass of `NSManagedObject` then this property is the context that the response was created in.
 
 Otherwise `nil`.
 */
@property RG_NULLABLE_PROPERTY(nonatomic, strong) NSManagedObjectContext* context;

@end
