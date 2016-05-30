/* Copyright (c) 02/07/2016, Ryan Dignard
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

#import <XCTest/XCTest.h>
#import "RGTestManagedObject.h"
#import "RGResponseObject.h"
#import "RGAPIClient.h"
#import <objc/runtime.h>
#import "RGSerializationDelegate.h"
#import "RGTapeDeck.h"
#import "RGXMLTestObject.h"

@interface RGAPIClient (RGForwardDecl)

- (RGResponseObject*) responseObjectFromBody:(id)body
                                     keyPath:(NSString*)keyPath
                                       class:(Class)cls
                                     context:(NSManagedObjectContext*)context
                                       error:(NSError*)error;

@end

@interface RGAPIClientSpec : XCTestCase

@end

@implementation RGAPIClientSpec

- (void) tearDown {
    [super tearDown];
    [[RGTapeDeck sharedTapeDeck] removeAllTapes];
}

- (void) testManagedObjects {
    NSEntityDescription* entity = [NSEntityDescription new];
    entity.name = NSStringFromClass([RGTestManagedObject self]);
    entity.managedObjectClassName = entity.name;
    NSManagedObjectModel* model = [NSManagedObjectModel new];
    model.entities = @[ entity ];
    NSPersistentStoreCoordinator* store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = store;
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    objc_setAssociatedObject(client, _cmd, context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGTestManagedObject self] context:context completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 2);
        RGTestManagedObject* obj1 = response.responseBody.firstObject;
        RGTestManagedObject* obj2 = response.responseBody.lastObject;
        XCTAssert([obj1.trackId isEqual:@"1065976170"]);
        XCTAssert([obj1.trackName isEqual:@"Comfortably Numb"]);
        XCTAssert([obj2.trackId isEqual:@"1065976170"]);
        XCTAssert([obj2.trackName isEqual:@"Comfortably Numb"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testGetSearch {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:Nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 2);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
    [[RGTapeDeck sharedTapeDeck] removeTapeForURL:@"https://itunes.apple.com/search"];
}

- (void) testWithoutCompletion {
    RGAPIClient* client = [RGAPIClient manager];
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    XCTAssertNoThrow([client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:nil class:Nil completion:nil]);
}

- (void) testXMLEndpoint {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    client.serializationDelegate = delegate;
    client.responseSerializer = [AFXMLParserResponseSerializer serializer];
    [[RGTapeDeck sharedTapeDeck] playTape:@"xml_data.txt" forURL:@"https://google.com/xml" withCode:200];
    objc_setAssociatedObject(client, @selector(serializationDelegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [client POST:@"https://google.com/xml" parameters:nil keyPath:@"xml.object" class:[RGXMLTestObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 1);
        XCTAssert([[(RGXMLTestObject*)response.responseBody[0] value] isEqual:@"42"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, @selector(serializationDelegate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testBadXML {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    client.serializationDelegate = delegate;
    client.responseSerializer = [AFXMLParserResponseSerializer serializer];
    [[RGTapeDeck sharedTapeDeck] playTape:nil forURL:@"https://google.com/xml" withCode:400];
    objc_setAssociatedObject(client, @selector(serializationDelegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [client POST:@"https://google.com/xml" parameters:nil keyPath:@"xml.object" class:[RGXMLTestObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.error);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, @selector(serializationDelegate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testXMLNoParsing {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    client.responseSerializer = [AFXMLParserResponseSerializer serializer];
    [[RGTapeDeck sharedTapeDeck] playTape:@"xml_data.txt" forURL:@"https://google.com/xml" withCode:200];
    objc_setAssociatedObject(client, @selector(serializationDelegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [client POST:@"https://google.com/xml" parameters:nil keyPath:@"xml.object" class:[RGXMLTestObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert([response.responseBody isKindOfClass:[NSXMLParser self]]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, @selector(serializationDelegate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testPostGoogle {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    [[RGTapeDeck sharedTapeDeck] playTape:nil forURL:@"https://google.com/logout" withCode:400];
    [client POST:@"https://google.com/logout" parameters:nil keyPath:nil class:Nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(!response.responseBody.count);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testPutGoogle {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    [[RGTapeDeck sharedTapeDeck] playTape:nil forURL:@"https://google.com/logout" withCode:400];
    [client PUT:@"https://google.com/logout" parameters:nil keyPath:nil class:Nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(!response.responseBody.count);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testDeleteGoogle {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    [[RGTapeDeck sharedTapeDeck] playTape:nil forURL:@"https://google.com/logout" withCode:400];
    [client DELETE:@"https://google.com/logout" parameters:nil keyPath:nil class:Nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(!response.responseBody.count);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testSerializationDelegate {
    RGSerializationDelegate* delegate = [RGSerializationDelegate new];
    RGAPIClient* client = [[RGAPIClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.bart.gov"] sessionConfiguration:nil];
    client.serializationDelegate = delegate;
    XCTAssert(client.serializationDelegate == delegate);
}

- (void) testInitIsValid {
    XCTAssertNoThrow([RGAPIClient new]);
}

@end
