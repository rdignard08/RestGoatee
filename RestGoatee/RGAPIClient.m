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

#import "RGAPIClient.h"
#import "NSObject+RG_Deserialization.h"

const NSString* const kRGHTTPStatusCode = @"HTTPStatusCode";

static NSError* errorWithStatusCodeFromTask(NSError* error, NSURLSessionDataTask* task) {
    NSError* modifiedError = error;
    if ([[task response] respondsToSelector:@selector(statusCode)]) {
        NSMutableDictionary* userInfo = [error.userInfo mutableCopy];
        userInfo[kRGHTTPStatusCode] = @([(id)[task response] statusCode]);
        modifiedError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
    }
    return modifiedError;
}

@implementation RGAPIClient

+ (NSManagedObjectContext*) contextForManagedObject:(NSDictionary*)object ofType:(Class)cls {
    return nil;
}

static NSURL* _sBaseURL;
+ (void) setDefaultBaseURL:(NSURL*)url {
    _sBaseURL = url;
}

+ (instancetype) manager {
    static RGAPIClient* _sManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sManager = [[self alloc] initWithBaseURL:_sBaseURL];
    });
    return _sManager;
}

- (id) parseResponse:(id)response atPath:(NSString*)path intoClass:(Class)cls {
    id target;
    if ([response isKindOfClass:[NSData class]] && [NSJSONSerialization isValidJSONObject:response]) {
        response = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
    }
    if (![response isKindOfClass:[NSDictionary class]] && ![response isKindOfClass:[NSArray class]]) return response;
    if (path && ![path isEqualToString:@""]) {
        target = response[path];
    } else {
        target = response;
    }
    if ([target isKindOfClass:[NSArray class]]) {
        NSMutableArray* ret = [NSMutableArray array];
        for (NSDictionary* obj in target) {
            if (cls) {
                [ret addObject:[cls objectFromJSON:obj inContext:[[self class] contextForManagedObject:obj ofType:cls]]];
            } else {
                [ret addObject:obj];
            }
        }
        response = [ret copy];
    } else {
        if (cls) {
            response = [cls objectFromJSON:target inContext:[[self class] contextForManagedObject:target ofType:cls]];
        } else {
            response = target;
        }
    }
    return response;
}

- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:parameters success:^(NSURLSessionDataTask* task, id responseObject) {
        if (completion) completion([self parseResponse:responseObject atPath:path intoClass:cls], nil);
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        if (completion) completion(nil, errorWithStatusCodeFromTask(error, task));
    }];
}

- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) GET:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) GET:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:nil keyPath:nil class:cls completion:completion];
}

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:parameters success:^(NSURLSessionDataTask* task, id responseObject) {
        if (completion) completion([self parseResponse:responseObject atPath:path intoClass:cls], nil);
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        if (completion) completion(nil, errorWithStatusCodeFromTask(error, task));
    }];
}

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) POST:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) POST:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:nil keyPath:nil class:cls completion:completion];
}

- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self PUT:url parameters:parameters success:^(NSURLSessionDataTask* task, id responseObject) {
        if (completion) completion([self parseResponse:responseObject atPath:path intoClass:cls], nil);
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        if (completion) completion(nil, errorWithStatusCodeFromTask(error, task));
    }];
}

- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self PUT:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) PUT:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self PUT:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) PUT:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self PUT:url parameters:nil keyPath:nil class:cls completion:completion];
}

/**
 Explicitly specify the destination class and request parameters.
 */
- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self DELETE:url parameters:parameters success:^(NSURLSessionDataTask* task, id responseObject) {
        if (completion) completion([self parseResponse:responseObject atPath:path intoClass:cls], nil);
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        if (completion) completion(nil, errorWithStatusCodeFromTask(error, task));
    }];
}

- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self DELETE:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) DELETE:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self DELETE:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) DELETE:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self DELETE:url parameters:nil keyPath:nil class:cls completion:completion];
}

@end