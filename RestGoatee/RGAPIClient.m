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

@implementation RGAPIClient

static NSURL* _sBaseURL;
+ (void) setDefaultBaseURL:(NSURL*)url {
    _sBaseURL = url;
}

+ (instancetype) manager {
    static RGAPIClient* _sManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sManager = [[RGAPIClient alloc] initWithBaseURL:_sBaseURL];
    });
    return _sManager;
}

- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls keyPath:(NSString*)path completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:parameters success:^(NSURLSessionDataTask* task, id responseObject) {
        id target;
        if (path && ![path isEqualToString:@""]) {
            target = responseObject[path];
        }
        if ([target isKindOfClass:[NSArray class]]) {
            NSMutableArray* ret = [NSMutableArray array];
            for (NSDictionary* obj in target) {
                [ret addObject:[cls objectFromJSON:obj inContext:nil]];
            }
            responseObject = [ret copy];
        } else {
            responseObject = [cls objectFromJSON:target inContext:nil];
        }
        if (completion) completion(responseObject, nil);
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        if (completion) completion(nil, error);
    }];
}

- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:parameters class:cls keyPath:nil completion:completion];
}

- (void) GET:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:nil class:cls keyPath:path completion:completion];
}

- (void) GET:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self GET:url parameters:nil class:cls keyPath:nil completion:completion];
}

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls keyPath:(NSString*)path completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:parameters success:^(NSURLSessionDataTask* task, id responseObject) {
        id target;
        if (path && ![path isEqualToString:@""]) {
            target = responseObject[path];
        }
        if ([target isKindOfClass:[NSArray class]]) {
            NSMutableArray* ret = [NSMutableArray array];
            for (NSDictionary* obj in target) {
                [ret addObject:[cls objectFromJSON:obj inContext:nil]];
            }
            responseObject = [ret copy];
        } else {
            responseObject = [cls objectFromJSON:target inContext:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(responseObject, nil);
        });
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, error);
        });
    }];
}

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:parameters class:cls keyPath:nil completion:completion];
}

- (void) POST:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:nil class:cls keyPath:path completion:completion];
}

- (void) POST:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion {
    [self POST:url parameters:nil class:cls keyPath:nil completion:completion];
}

@end