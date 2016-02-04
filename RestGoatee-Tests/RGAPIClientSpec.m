//
//  RestGoatee_Tests.m
//  RestGoatee-Tests
//
//  Created by Ryan Dignard on 1/21/16.
//  Copyright © 2016 Ryan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RGResponseObject.h"
#import "RGAPIClient.h"
#import <objc/runtime.h>

static NSString* data = @"{"
                            @"\"resultCount\":50,"
                            @"\"results\": ["
                                @"{"
                                    @"\"wrapperType\":\"track\","
                                    @"\"kind\":\"song\","
                                    @"\"artistId\":487143,"
                                    @"\"collectionId\":1065975633,"
                                    @"\"trackId\":1065976170,"
                                    @"\"artistName\":\"Pink Floyd\","
                                    @"\"collectionName\":\"The Wall\","
                                    @"\"trackName\":\"Comfortably Numb\","
                                    @"\"collectionCensoredName\":\"The Wall\","
                                    @"\"trackCensoredName\":\"Comfortably Numb\","
                                    @"\"collectionPrice\":16.99,"
                                    @"\"trackPrice\":1.29,"
                                    @"\"releaseDate\":\"1979-11-30T08:00:00Z\","
                                    @"\"collectionExplicitness\":\"notExplicit\","
                                    @"\"trackExplicitness\":\"notExplicit\","
                                    @"\"discCount\":2,"
                                    @"\"discNumber\":2,"
                                    @"\"trackCount\":13,"
                                    @"\"trackNumber\":6,"
                                    @"\"trackTimeMillis\":382297,"
                                    @"\"country\":\"USA\","
                                    @"\"currency\":\"USD\","
                                    @"\"primaryGenreName\":\"Rock\","
                                    @"\"radioStationUrl\":\"https://itunes.apple.com/station/idra.1065976170\","
                                    @"\"isStreamable\":true"
                                @"}"
                            @"]"
                        @"}";

@interface RGAPIClient (TestOverride)

@property (nonatomic, strong) NSMutableDictionary* recordedResponses;

@end

@interface RGAPIClient (RGForwardDecl)

- (RGResponseObject*) responseObjectFromBody:(id)body keypath:(NSString*)keyPath class:(Class)cls context:(NSManagedObjectContext*)context error:(NSError*)error;

@end

@implementation RGAPIClient (TestOverride)

- (NSMutableDictionary*) recordedResponses {
    id ret = objc_getAssociatedObject(self, @selector(recordedResponses));
    if (!ret) {
        ret = [NSMutableDictionary new];
        objc_setAssociatedObject(self, @selector(recordedResponses), ret, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ret;
}

- (void) setRecordedResponses:(NSMutableDictionary*)recordedResponses {
    objc_setAssociatedObject(self, @selector(recordedResponses), recordedResponses, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void) load {
    rg_swizzle(self, @selector(request:url:parameters:keyPath:class:completion:context:count:), @selector(override_request:url:parameters:keyPath:class:completion:context:count:));
}

- (void) override_request:(NSString*)method url:(NSString*)url parameters:(RG_PREFIX_NULLABLE NSDictionary*)parameters keyPath:(RG_PREFIX_NULLABLE NSString*)path class:(RG_PREFIX_NULLABLE Class)cls completion:(RG_PREFIX_NULLABLE RGResponseBlock)completion context:(RG_PREFIX_NULLABLE NSManagedObjectContext*)context count:(NSUInteger)count {
    NSString* recordedResponse = self.recordedResponses[url];
    if (recordedResponse) {
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[recordedResponse dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion([self responseObjectFromBody:response keypath:path class:cls context:context error:nil]);
            }
        });
    } else {
        [self override_request:method url:url parameters:parameters keyPath:path class:cls completion:completion context:context count:count];
    }
}

@end

@interface RGAPIClientSpec : XCTestCase

@end

@implementation RGAPIClientSpec

- (void) testGetSearch {
    XCTestExpectation* expectation = [self expectationWithDescription:@""];
    RGAPIClient* client = [RGAPIClient manager];
    client.recordedResponses[@"https://itunes.apple.com/search"] = data;
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:nil class:nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        
    }];
}

@end
