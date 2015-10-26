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
#import "RGXMLSerializer.h"
#import <objc/runtime.h>
#import <RestGoatee-Core.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Forward Declarations
/**
 Garbage used that may not be present in the super class (since the super class is variable).
 */
@interface NSObject (_RGForwardDeclarations)

#pragma mark - AFNetworking
- (nullable id) initWithBaseURL:(nullable id)url sessionConfiguration:(nullable id)configuration;
- (nullable id) initWithBaseURL:(nullable id)url;
- (nonnull id) requestWithMethod:(nonnull id)method URLString:(id)url parameters:(id)parameters; /* deprecated version of below */
- (nonnull id) requestWithMethod:(nonnull id)method URLString:(id)url parameters:(id)parameters error:(__autoreleasing id* __nullable)error;
- (nonnull id) requestWithMethod:(nonnull id)method path:(id)path parameters:(id)parameters; /* old style */
@property (nonatomic, strong, nonnull) id requestSerializer;

#pragma mark - NSFetchRequest
+ (id) fetchRequestWithEntityName:(NSString*)entityName;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSArray *sortDescriptors;

#pragma mark - NSManagedObjectContext
@property (nonatomic, readonly) BOOL hasChanges;
- (NSArray*) executeFetchRequest:(id)request error:(NSError**)error;
- (BOOL) save:(NSError**)error;
- (void) performBlockAndWait:(void(^)())block;

@end

#pragma mark - Constants
static NSComparisonResult(^comparator)(id, id) = ^NSComparisonResult (id obj1, id obj2) {
    return [[obj1 description] compare:[obj2 description]];
};

static inline NSError* errorWithStatusCodeFromTask(NSError* error, NSURLResponse* task) {
    if ([task isKindOfClass:[NSHTTPURLResponse class]]) {
        error.HTTPStatusCode = [(NSHTTPURLResponse*)task statusCode];
    }
    return error;
}

@implementation RGAPIClient

#pragma mark - Initialization
- (instancetype) init {
    return [self initWithBaseURL:nil sessionConfiguration:nil];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype) initWithBaseURL:(NSURL*)baseURL {
    return [self initWithBaseURL:baseURL sessionConfiguration:nil];
}
#pragma clang diagnostic pop

- (nullable instancetype) initWithBaseURL:(nullable NSURL*)url sessionConfiguration:(nullable NSURLSessionConfiguration*)configuration {
#if IOS_7_PLUS
    Class super_class = NSClassFromString(@"AFHTTPSessionManager");
#else
    Class super_class = NSClassFromString(@"AFHTTPRequestOperationManager");
#endif
    if ([super_class instancesRespondToSelector:@selector(initWithBaseURL:sessionConfiguration:)]) {
        self = [super initWithBaseURL:url sessionConfiguration:configuration];
    } else if ([super_class instancesRespondToSelector:@selector(initWithBaseURL:)]) {
        self = [super initWithBaseURL:url];
    } else {
        self = [super init];
    }
    if (self && configuration) {
        self->_sessionConfiguration = configuration;
    }
    return self;
}

#pragma mark - Engine Methods
- (NSArray*) parseResponse:(id)response atPath:(NSString*)path intoClass:(Class)cls context:(inout __strong NSManagedObjectContext**)outContext {
    /* NSManagedObjectContext* */ id context = *outContext;
    NSString* primaryKey;
    __block NSArray* allObjects;
    if ([cls isSubclassOfClass:rg_sNSManagedObject]) {
        if ([self.serializationDelegate respondsToSelector:@selector(keyForReconciliationOfType:)]) {
            primaryKey = [self.serializationDelegate keyForReconciliationOfType:cls];
        }
        if (!context && [self.serializationDelegate respondsToSelector:@selector(contextForManagedObjectType:)]) {
            *outContext = context = [self.serializationDelegate contextForManagedObjectType:cls];
        }
        context ?: [NSException raise:NSGenericException format:@"Subclasses of NSManagedObject must be created within an NSManagedObjectContext"];
    }
    NSArray* target = path ? [response valueForKeyPath:path] : response;
    target = !target || [target isKindOfClass:[NSArray class]] ? target : @[ target ];
    if (primaryKey && [cls isSubclassOfClass:rg_sNSManagedObject]) {
        NSObject* fetch = [rg_sNSFetchRequest fetchRequestWithEntityName:NSStringFromClass(cls)];
        NSArray* incomingKeys = target[primaryKey];
        NSMutableArray* parsedKeys = [NSMutableArray arrayWithCapacity:incomingKeys.count];
        for (__strong id value in incomingKeys) {
            [parsedKeys addObject:[value isKindOfClass:[RGXMLNode class]] ? [value innerXML] : value];
        }
        fetch.predicate = [NSPredicate predicateWithFormat:@"%K in %@", primaryKey, parsedKeys];
        fetch.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:primaryKey ascending:YES] ];
        [context performBlockAndWait:^{
            NSError* error;
            allObjects = [context executeFetchRequest:fetch error:&error];
            error ? RGLog(@"Warning, fetch %@ failed %@", fetch, error) : nil;
        }];
    }
    NSMutableArray* ret = [NSMutableArray arrayWithCapacity:[target count]];
    for (id entry in target) {
        if (rg_isDataSourceClass([entry class]) && primaryKey && allObjects && entry[primaryKey]) {
            id keyValue = [entry isKindOfClass:[RGXMLNode class]] ? [entry[primaryKey] innerXML] : entry[primaryKey];
            NSUInteger index = [allObjects[primaryKey] indexOfObject:keyValue inSortedRange:NSMakeRange(0, allObjects.count) options:NSBinarySearchingFirstEqual usingComparator:comparator];
            if (index != NSNotFound) {
                [ret addObject:[allObjects[index] extendWith:entry inContext:context]]; /* Existing Object */
            } else {
                [ret addObject:[cls objectFromDataSource:entry inContext:context]]; /* New Object */
            }
        } else {
            [ret addObject:cls ? [cls objectFromDataSource:entry inContext:context] : entry]; /* Nothing to lookup so it may be new or the raw is desired. */
        }
    }
    response = [ret copy];
    [context performBlockAndWait:^{
        NSError* error;
        @try {
            if ([context hasChanges]) {
                [context save:&error] ?: RGLog(@"Error, context save failed with error %@", error);
            }
        } @catch (NSException* e) {
            RGLog(@"Warning, saving context %@ failed: %@", context, e);
        }
    }];
    return response;
}

- (RGResponseObject*) responseObjectFromBody:(id)body keypath:(NSString*)keyPath class:(Class)cls context:(NSManagedObjectContext*)context error:(NSError*)error {
    RGResponseObject* ret = [RGResponseObject new];
    NSManagedObjectContext* localContext = context;
    if (!error) {
        if ([body isKindOfClass:[NSXMLParser class]]) {
            BOOL shouldSerializeXML = [self.serializationDelegate respondsToSelector:@selector(shouldSerializeXML)] && [self.serializationDelegate shouldSerializeXML];
            if (shouldSerializeXML) {
                ret.responseBody = [self parseResponse:[[RGXMLSerializer alloc] initWithParser:body].rootNode atPath:keyPath intoClass:cls context:&localContext];
            } else {
                ret.responseBody = body;
            }
        } else {
            ret.responseBody = [self parseResponse:body atPath:keyPath intoClass:cls context:&context];
        }
    } else {
        error.extraData = body;
    }
    ret.error = error;
    ret.context = localContext;
    return ret;
}

- (void) request:(NSString*)method url:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls completion:(nullable RGResponseBlock)completion context:(nullable NSManagedObjectContext*)context count:(NSUInteger)count {
    __block __strong id task;
    NSMutableURLRequest* request;
    NSString* fullPath = [[NSURL URLWithString:url relativeToURL:self.baseURL] absoluteString];
    if ([self respondsToSelector:@selector(requestSerializer)]) { /* "Modern" style */
        request = [self.requestSerializer requestWithMethod:method URLString:fullPath parameters:parameters];
    } else {
        request = [(id)self requestWithMethod:method path:fullPath parameters:parameters];
    }
#if IOS_7_PLUS
    task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse* response, id body, NSError* error) {
        if (error &&
            [self.serializationDelegate respondsToSelector:@selector(shouldRetryRequest:response:error:retryCount:)] &&
            [self.serializationDelegate shouldRetryRequest:[task currentRequest] response:response error:error retryCount:count]) {
            [self request:method url:url parameters:parameters keyPath:path class:cls completion:completion context:context count:count + 1];
        } else if (completion) {
            completion([self responseObjectFromBody:body keypath:path class:cls context:context error:errorWithStatusCodeFromTask(error, response)]);
        }
    }];
#else
    void(^callback)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation* op, id response) {
        id body, /* NSError* */ error;
        [response isKindOfClass:[NSError class]] ? (error = response) : (body = response);
        if (error &&
            [self.serializationDelegate respondsToSelector:@selector(shouldRetryRequest:response:error:retryCount:)] &&
            [self.serializationDelegate shouldRetryRequest:op.request response:op.response error:error retryCount:count]) {
            [self request:method url:url parameters:parameters keyPath:path class:cls completion:completion context:context count:count + 1];
        } else if (completion) {
            completion([self responseObjectFromBody:body keypath:path class:cls context:context error:errorWithStatusCodeFromTask(error, op.response)]);
        }
    };
    task = [self HTTPRequestOperationWithRequest:request success:callback failure:callback];
#endif
    
#if IOS_7_PLUS
    [task resume];
#else
    [self.operationQueue addOperation:task];
#endif
}


#pragma mark - VERB Methods
- (void) GET:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls completion:(nullable RGResponseBlock)completion {
    [self GET:url parameters:parameters keyPath:path class:cls context:nil completion:completion];
}

- (void) GET:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls context:(nullable NSManagedObjectContext*)context completion:(nullable RGResponseBlock)completion {
    [self request:@"GET" url:url parameters:parameters keyPath:path class:cls completion:completion context:context count:0];
}

- (void) POST:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls completion:(nullable RGResponseBlock)completion {
    [self POST:url parameters:parameters keyPath:path class:cls context:nil completion:completion];
}

- (void) POST:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls context:(nullable NSManagedObjectContext*)context completion:(nullable RGResponseBlock)completion {
    [self request:@"POST" url:url parameters:parameters keyPath:path class:cls completion:completion context:context count:0];
}

- (void) PUT:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls completion:(nullable RGResponseBlock)completion {
    [self PUT:url parameters:parameters keyPath:path class:cls context:nil completion:completion];
}

- (void) PUT:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls context:(nullable NSManagedObjectContext*)context completion:(nullable RGResponseBlock)completion {
    [self request:@"PUT" url:url parameters:parameters keyPath:path class:cls completion:completion context:context count:0];
}

- (void) DELETE:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls completion:(nullable RGResponseBlock)completion {
    [self DELETE:url parameters:parameters keyPath:path class:cls context:nil completion:completion];
}

- (void) DELETE:(NSString*)url parameters:(nullable NSDictionary*)parameters keyPath:(nullable NSString*)path class:(nullable Class)cls context:(nullable NSManagedObjectContext*)context completion:(nullable RGResponseBlock)completion {
    [self request:@"DELETE" url:url parameters:parameters keyPath:path class:cls completion:completion context:context count:0];
}

@end

NS_ASSUME_NONNULL_END
