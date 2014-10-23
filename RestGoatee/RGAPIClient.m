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
#import "RestGoatee.h"
#import "NSObject+RG_SharedImpl.h"
#import <objc/runtime.h>

const NSString* const kRGHTTPStatusCode = @"HTTPStatusCode";

static NSComparisonResult(^comparator)(id, id) = ^NSComparisonResult (id obj1, id obj2) {
    return [[obj1 description] compare:[obj2 description]];
};

static NSError* errorWithStatusCodeFromTask(NSError* error, id task) {
    if (error && [[task response] respondsToSelector:@selector(statusCode)]) {
        NSMutableDictionary* userInfo = [error.userInfo mutableCopy];
        userInfo[kRGHTTPStatusCode] = @([(id)[task response] statusCode]);
        error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
    }
    return error;
}

@implementation RGAPIClient

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
- (id) parseResponse:(id)response atPath:(NSString*)path intoClass:(Class)cls context:(out NSManagedObjectContext**)outContext {
    /* cls* | NSArray<cls*>* */ id target;
    /* NSManagedObjectContext* */ id context;
    NSString* primaryKey;
    NSUInteger index;
    NSArray* allObjects;
    if ([cls isSubclassOfClass:rg_sNSManagedObject]) {
        if ([self.serializationDelegate respondsToSelector:@selector(keyForReconciliationOfType:)]) {
            primaryKey = [self.serializationDelegate keyForReconciliationOfType:cls];
        }
        if ([self.serializationDelegate respondsToSelector:@selector(contextForManagedObjectType:)]) {
            *outContext = context = [self.serializationDelegate contextForManagedObjectType:cls];
        }
        NSAssert(context, @"Subclasses of NSManagedObject must be created within an NSManagedObjectContext");
    }
    target = path ? [response valueForKeyPath:path] : response;
    if (primaryKey && cls) {
        id fetch = [rg_sNSFetchRequest performSelector:@selector(fetchRequestWithEntityName:) withObject:NSStringFromClass(cls)];
        [fetch setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:primaryKey ascending:YES] ]];
        allObjects = [context performSelector:@selector(executeFetchRequest:error:) withObject:fetch withObject:nil];
    }
    if ([target isKindOfClass:[NSArray class]]) {
        NSMutableArray* ret = [NSMutableArray array];
        for (id entry in target) {
            if (primaryKey && allObjects && entry[primaryKey]) {
                index = [allObjects[primaryKey] indexOfObject:entry[primaryKey] inSortedRange:NSMakeRange(0, allObjects.count) options:NSBinarySearchingFirstEqual usingComparator:comparator];
                if (index != NSNotFound) {
                    [ret addObject:[allObjects[index] extendWith:entry inContext:context]]; /* Existing Object */
                } else {
                    [ret addObject:[cls objectFromJSON:entry inContext:context]]; /* New Object */
                }
            } else {
                [ret addObject:(cls ? [cls objectFromJSON:entry inContext:context] : entry)]; /* Nothing to lookup so it may be new or the raw is desired. */
            }
        }
        response = ret;
    } else if ([target isKindOfClass:[NSDictionary class]]) {
        if (primaryKey && allObjects && target[primaryKey]) {
            index = [allObjects[primaryKey] indexOfObject:target[primaryKey] inSortedRange:NSMakeRange(0, allObjects.count) options:NSBinarySearchingFirstEqual usingComparator:comparator];
            if (index != NSNotFound) {
                response = [allObjects[index] extendWith:target inContext:context]; /* Existing Object */
            } else {
                response = cls ? [cls objectFromJSON:target inContext:context] : target; /* New Object */
            }
        } else {
            response = cls ? [cls objectFromJSON:target inContext:context] : target; /* New Object */
        }
    }
    @try {
        [context performSelector:@selector(save:) withObject:nil];
    }
    @catch (NSException* e) {}
    return response;
}
#pragma clang diagnostic pop

- (RGResponseObject*) responseObjectFromBody:(id)body keypath:(NSString*)keypath class:(Class)cls error:(NSError*)error {
    RGResponseObject* ret = [[RGResponseObject alloc] init];
    NSManagedObjectContext* context;
    if (!error && body) {
        ret.responseBody = [self parseResponse:body atPath:keypath intoClass:cls context:&context];
    } else {
        ret.responseBody = body;
    }
    ret.error = error;
    ret.context = context;
    return ret;
}

- (void) request:(NSString*)method url:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion delegate:(id<RGResponseDelegate>)delegate {
    static SEL key;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        key = _cmd;
    });
    __block __strong id task;
    NSMutableURLRequest* request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:url relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse* __unused response, id body, NSError* error) {
        RGResponseObject* responseObject = [self responseObjectFromBody:body keypath:path class:cls error:errorWithStatusCodeFromTask(error, task)];
        id<RGResponseDelegate> del = objc_getAssociatedObject(task, key);
        if (del) {
            if (error) {
                [del response:responseObject failedForRequest:task];
            } else {
                [del response:responseObject receivedForRequest:task];
            }
        } else if (completion) {
            completion(responseObject);
        }
    }];
#else
    void(^callback)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation* op, id response) {
        NSError* error;
        id body;
        if ([response isKindOfClass:[NSError class]]) {
            error = response;
        } else {
            body = response;
        }
        RGResponseObject* responseObject = [self responseObjectFromBody:body keypath:path class:cls error:errorWithStatusCodeFromTask(error, op)];
        id<RGResponseDelegate> del = objc_getAssociatedObject(op, key);
        if (del) {
            if (error) {
                [del response:responseObject failedForRequest:op];
            } else {
                [del response:responseObject receivedForRequest:op];
            }
        } else if (completion) {
            completion(responseObject);
        }
    };
    task = [self HTTPRequestOperationWithRequest:request success:callback failure:callback];
#endif

    objc_setAssociatedObject(task, key, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    [task resume];
#else
    [self.operationQueue addOperation:task];
#endif
}

- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self request:@"GET" url:url parameters:parameters keyPath:path class:cls completion:completion delegate:nil];
}

- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate {
    [self request:@"GET" url:url parameters:parameters keyPath:path class:cls completion:NULL delegate:delegate];
}

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self request:@"POST" url:url parameters:parameters keyPath:path class:cls completion:completion delegate:nil];
}

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate {
    [self request:@"POST" url:url parameters:parameters keyPath:path class:cls completion:NULL delegate:delegate];
}

- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self request:@"PUT" url:url parameters:parameters keyPath:path class:cls completion:completion delegate:nil];
}

- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate {
    [self request:@"PUT" url:url parameters:parameters keyPath:path class:cls completion:NULL delegate:delegate];
}

- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self request:@"DELETE" url:url parameters:parameters keyPath:path class:cls completion:completion delegate:nil];
}

- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters keyPath:(NSString*)path class:(Class)cls delegate:(id<RGResponseDelegate>)delegate {
    [self request:@"DELETE" url:url parameters:parameters keyPath:path class:cls completion:NULL delegate:delegate];
}

@end

@implementation RGAPIClient (RGConvenience)

- (void) GET:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion {
    [self GET:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) GET:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self GET:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) GET:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion {
    [self GET:url parameters:nil keyPath:nil class:cls completion:completion];
}

- (void) POST:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion {
    [self POST:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) POST:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self POST:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) POST:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion {
    [self POST:url parameters:nil keyPath:nil class:cls completion:completion];
}

- (void) PUT:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion {
    [self PUT:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) PUT:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self PUT:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) PUT:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion {
    [self PUT:url parameters:nil keyPath:nil class:cls completion:completion];
}

- (void) DELETE:(NSString*)url parameters:(NSDictionary*)parameters class:(Class)cls completion:(RGResponseBlock)completion {
    [self DELETE:url parameters:parameters keyPath:nil class:cls completion:completion];
}

- (void) DELETE:(NSString*)url keyPath:(NSString*)path class:(Class)cls completion:(RGResponseBlock)completion {
    [self DELETE:url parameters:nil keyPath:path class:cls completion:completion];
}

- (void) DELETE:(NSString*)url class:(Class)cls completion:(RGResponseBlock)completion {
    [self DELETE:url parameters:nil keyPath:nil class:cls completion:completion];
}

- (void) GET:(NSString*)url completion:(RGResponseBlock)completion {
    [self GET:url parameters:nil keyPath:nil class:Nil completion:completion];
}

- (void) GET:(NSString*)url delegate:(id<RGResponseDelegate>)delegate {
    [self GET:url parameters:nil keyPath:nil class:Nil delegate:delegate];
}

- (void) POST:(NSString*)url completion:(RGResponseBlock)completion {
    [self POST:url parameters:nil keyPath:nil class:Nil completion:completion];
}

- (void) POST:(NSString*)url delegate:(id<RGResponseDelegate>)delegate {
    [self POST:url parameters:nil keyPath:nil class:Nil delegate:delegate];
}

- (void) PUT:(NSString*)url completion:(RGResponseBlock)completion {
    [self PUT:url parameters:nil keyPath:nil class:Nil completion:completion];
}

- (void) PUT:(NSString*)url delegate:(id<RGResponseDelegate>)delegate {
    [self PUT:url parameters:nil keyPath:nil class:Nil delegate:delegate];
}

- (void) DELETE:(NSString*)url completion:(RGResponseBlock)completion {
    [self DELETE:url parameters:nil keyPath:nil class:Nil completion:completion];
}

- (void) DELETE:(NSString*)url delegate:(id<RGResponseDelegate>)delegate {
    [self DELETE:url parameters:nil keyPath:nil class:Nil delegate:delegate];
}

@end
