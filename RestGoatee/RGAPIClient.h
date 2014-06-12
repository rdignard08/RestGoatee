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

@interface RGAPIClient : AFHTTPSessionManager

+ (void) setDefaultBaseURL:(NSURL*)url;
+ (instancetype) manager;

/**
 Explicitly specify the destination class and request parameters.
 */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls  completion:(void(^)(id, NSError*))completion; /* This is the full variant */
- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion;
- (void) GET:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion;
- (void) GET:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion;

/**
 Explicitly specify the destination class and request parameters.
 */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion; /* This is the full variant */
- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(void(^)(id, NSError*))completion;
- (void) POST:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(void(^)(id, NSError*))completion;
- (void) POST:(NSString*)url class:(Class)cls completion:(void(^)(id, NSError*))completion;

@end