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

#import "RestGoatee.h"
#import "RGXMLSerializer.h"
#import <objc/runtime.h>
#import "RestGoatee-Core.h"

@interface NSObject (RGForwardDeclarations)

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
    return [[obj1 rg_stringValue] compare:[obj2 rg_stringValue]];
};

static inline NSError* errorWithStatusCodeFromTask(NSError* error, NSURLResponse* task) {
    if ([task isKindOfClass:[NSHTTPURLResponse class]]) {
        error.HTTPStatusCode = (NSUInteger)[(NSHTTPURLResponse*)task statusCode];
    }
    return error;
}

@implementation RGAPIClient

#pragma mark - Initialization
- (RG_PREFIX_NONNULL instancetype) init {
    return [self initWithBaseURL:nil sessionConfiguration:nil];
}

- (RG_PREFIX_NONNULL instancetype) initWithBaseURL:(NSURL*)baseURL {
    return [self initWithBaseURL:baseURL sessionConfiguration:nil];
}

- (RG_PREFIX_NONNULL instancetype) initWithBaseURL:(RG_PREFIX_NULLABLE NSURL*)url
                              sessionConfiguration:(RG_PREFIX_NULLABLE NSURLSessionConfiguration*)configuration {
    self = [super init];
    self->_manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url sessionConfiguration:configuration];
    return self;
}

#pragma mark - Engine Methods
- (RG_PREFIX_NULLABLE NSArray*) incomingKeysInTarget:(NSArray*)target onProperty:(NSString*)primaryKey {
    if (primaryKey) {
        NSArray* incomingKeys = [target valueForKey:primaryKey];
        NSMutableArray* parsedKeys = [NSMutableArray arrayWithCapacity:incomingKeys.count];
        for (NSUInteger i = 0; i < incomingKeys.count; i++) {
            id value = incomingKeys[i];
            [parsedKeys addObject:[value isKindOfClass:[RGXMLNode class]] ? [value innerXML] : value];
        }
    }
    return nil;
}

- (RG_PREFIX_NULLABLE NSArray RG_GENERIC(NSObject*) *) existingObjectsOfClass:(Class)cls
                                                                 matchingKeys:(NSArray RG_GENERIC(NSString*) *)keys
                                                                   onProperty:(NSString*)primaryKey
                                                                    inContext:(id)context {
    __block NSArray* objects = nil;
    if (primaryKey) {
        id fetch = [objc_getClass("NSFetchRequest") fetchRequestWithEntityName:NSStringFromClass(cls)];
        [fetch setPredicate:[NSPredicate predicateWithFormat:@"%K in %@", primaryKey, keys]];
        [fetch setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:primaryKey ascending:YES] ]];
        [context performBlockAndWait:^{
            NSError* error;
            objects = [context executeFetchRequest:fetch error:&error];
            error ? RGLogs(kRGLogSeverityWarning, @"fetch %@ failed %@", fetch, error) : RG_VOID_NOOP;
        }];
    }
    return objects;
}

- (id) provideContextForClass:(Class)cls existingContext:(inout __strong NSManagedObjectContext**)context {
    id value = *context;
    if (!value) {
        NSAssert([self.serializationDelegate respondsToSelector:@selector(contextForManagedObjectType:)],
                 @"A context was not provided and contextForManagedObjectType: was not implemented");
        *context = value = [self.serializationDelegate contextForManagedObjectType:cls];
        return value;
    }
    return value;
}

- (NSArray*) parseResponse:(id)response
                    atPath:(NSString*)path
                 intoClass:(Class)cls
                   context:(inout __strong NSManagedObjectContext**)outContext {
    id context = nil;
    NSString* primaryKey = nil;
    if ([cls isSubclassOfClass:kRGNSManagedObject]) {
        context = [self provideContextForClass:cls existingContext:outContext];
        if ([self.serializationDelegate respondsToSelector:@selector(keyForReconciliationOfType:)]) {
            primaryKey = [self.serializationDelegate keyForReconciliationOfType:cls];
        }
        NSAssert(context, @"Subclasses of NSManagedObject must be created within an NSManagedObjectContext");
    }
    NSArray* target = path ? [response valueForKeyPath:path] : response;
    target = !target || [target isKindOfClass:[NSArray class]] ? target : @[ target ];
    NSArray* keys = [self incomingKeysInTarget:target onProperty:primaryKey];
    NSArray* allObjects = [self existingObjectsOfClass:cls matchingKeys:keys onProperty:primaryKey inContext:context];
    NSMutableArray* ret = [NSMutableArray arrayWithCapacity:[target count]];
    for (NSUInteger i = 0; i < target.count; i++) {
        id entry = target[i];
        BOOL dataSrc = [entry isKindOfClass:[NSDictionary self]] || [entry conformsToProtocol:@protocol(RGDataSource)];
        if (dataSrc && allObjects) {
            NSAssert([entry valueForKey:primaryKey],
                     @"entry %@ did not provide a value for primaryKey %@",
                     entry,
                     primaryKey);
            id entryKey = [entry valueForKey:primaryKey];
            id keyValue = [entryKey isKindOfClass:[RGXMLNode self]] ? [entryKey innerXML] : entryKey;
            NSArray* existingKeys = [allObjects valueForKey:primaryKey];
            NSArray* newKeys = [ret valueForKey:primaryKey];
            NSUInteger index = [existingKeys indexOfObject:keyValue
                                             inSortedRange:NSMakeRange(0, allObjects.count)
                                                   options:(NSBinarySearchingOptions)0
                                           usingComparator:comparator];
            __block NSUInteger currentIndex = NSNotFound;
            [newKeys enumerateObjectsUsingBlock:^(id obj, __unused NSUInteger idx, __unused BOOL* stop) {
                if (comparator(obj, keyValue) == NSOrderedSame) {
                    currentIndex = idx;
                    *stop = YES;
                }
            }];
            if (currentIndex != NSNotFound) {
                RGLogs(kRGLogSeverityWarning,
                       @"duplicate object present in response discarded %@ with key %@",
                       cls,
                       keyValue);
                continue;
            }
            if (index == NSNotFound) {
                [ret addObject:[cls objectFromDataSource:entry inContext:context]]; /* New Object */
            } else {
                [ret addObject:[allObjects[index] extendWith:entry inContext:context]]; /* Existing Object */
            }
        } else {
            [ret addObject:cls ? [cls objectFromDataSource:entry inContext:context] : entry]; /* Nothing to lookup */
        }
    }
    [context performBlockAndWait:^{
        NSError* error;
        @try {
            BOOL value = [(NSObject*)context save:&error]; /* TODO: add back hasChanges check */
            if (!value) {
                RGLogs(kRGLogSeverityError, @"context save failed with error %@", error);
            }
        } @catch (NSException* e) {
            RGLogs(kRGLogSeverityError, @"saving context %@ failed: %@", context, e);
        }
    }];
    return ret;
}

- (RGResponseObject*) responseObjectFromBody:(id)body
                                     keyPath:(NSString*)keyPath
                                       class:(Class)cls
                                     context:(NSManagedObjectContext*)context
                                       error:(NSError*)error {
    RGResponseObject* ret = [RGResponseObject new];
    NSManagedObjectContext* localContext = context;
    if (error) {
        error.extraData = body;
    } else {
        if ([body isKindOfClass:[NSXMLParser class]]) {
            BOOL shouldSerializeXML = NO;
            if ([self.serializationDelegate respondsToSelector:@selector(shouldSerializeXML)]) {
                shouldSerializeXML = self.serializationDelegate.shouldSerializeXML;
            }
            if (shouldSerializeXML) {
                ret.responseBody = [self parseResponse:[[RGXMLSerializer alloc] initWithParser:body].rootNode
                                                atPath:keyPath
                                             intoClass:cls
                                               context:&localContext];
            } else {
                ret.responseBody = body;
            }
        } else {
            ret.responseBody = [self parseResponse:body atPath:keyPath intoClass:cls context:&context];
        }
    }
    ret.error = error;
    ret.context = localContext;
    return ret;
}

- (void) request:(NSString*)method
             url:(NSString*)url
      parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
         keyPath:(RG_PREFIX_NULLABLE NSString*)path
           class:(RG_PREFIX_NULLABLE Class)cls
      completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion
         context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
           count:(NSUInteger)count {
    __block __strong NSURLSessionDataTask* RG_SUFFIX_NONNULL task;
    NSString* fullPath = [[NSURL URLWithString:url relativeToURL:self.manager.baseURL] absoluteString];
    NSMutableURLRequest* inRequest = [self.manager.requestSerializer requestWithMethod:method
                                                                          URLString:fullPath
                                                                         parameters:parameters
                                                                              error:nil];
    task = [self.manager dataTaskWithRequest:inRequest completionHandler:^(NSURLResponse* response,
                                                                           id body,
                                                                           NSError* error) {
        NSURLRequest* request = task.currentRequest;
        if (error &&
            [self.serializationDelegate respondsToSelector:@selector(shouldRetryRequest:response:error:retryCount:)] &&
            [self.serializationDelegate shouldRetryRequest:request response:response error:error retryCount:count]) {
            [self request:method
                      url:url
               parameters:parameters
                  keyPath:path
                    class:cls
               completion:completion
                  context:context
                    count:count + 1];
        } else if (completion) {
            completion([self responseObjectFromBody:body
                                            keyPath:path
                                              class:cls
                                            context:context
                                              error:errorWithStatusCodeFromTask(error, response)]);
        }
    }];
    [task resume];
}


#pragma mark - VERB Methods
- (void) GET:(NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self GET:url
   parameters:parameters
      keyPath:path
        class:cls
      context:nil
   completion:completion];
}

- (void) GET:(NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
     context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self request:@"GET"
              url:url
       parameters:parameters
          keyPath:path
            class:cls
       completion:completion
          context:context
            count:0];
}

- (void) POST:(NSString*)url
   parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
      keyPath:(RG_PREFIX_NULLABLE NSString*)path
        class:(RG_PREFIX_NULLABLE Class)cls
   completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self POST:url
    parameters:parameters
       keyPath:path
         class:cls
       context:nil
    completion:completion];
}

- (void) POST:(NSString*)url
   parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
      keyPath:(RG_PREFIX_NULLABLE NSString*)path
        class:(RG_PREFIX_NULLABLE Class)cls
      context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
   completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self request:@"POST"
              url:url
       parameters:parameters
          keyPath:path
            class:cls
       completion:completion
          context:context
            count:0];
}

- (void) PUT:(NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self PUT:url
   parameters:parameters
      keyPath:path
        class:cls
      context:nil
   completion:completion];
}

- (void) PUT:(NSString*)url
  parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
     keyPath:(RG_PREFIX_NULLABLE NSString*)path
       class:(RG_PREFIX_NULLABLE Class)cls
     context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
  completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self request:@"PUT"
              url:url
       parameters:parameters
          keyPath:path
            class:cls
       completion:completion
          context:context
            count:0];
}

- (void) DELETE:(NSString*)url
     parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
        keyPath:(RG_PREFIX_NULLABLE NSString*)path
          class:(RG_PREFIX_NULLABLE Class)cls
     completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self DELETE:url
      parameters:parameters
         keyPath:path
           class:cls
         context:nil
      completion:completion];
}

- (void) DELETE:(NSString*)url
     parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters
        keyPath:(RG_PREFIX_NULLABLE NSString*)path
          class:(RG_PREFIX_NULLABLE Class)cls
        context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context
     completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion {
    [self request:@"DELETE"
              url:url
       parameters:parameters
          keyPath:path
            class:cls
       completion:completion
          context:context
            count:0];
}

@end
