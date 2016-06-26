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
#import "NSManagedObjectContext+RGNeverHasChanges.h"

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
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    NSManagedObjectContext* context = [delegate contextForManagedObjectType:[RGTestManagedObject self]];
    for (NSManagedObject* object in context.insertedObjects) {
        [context deleteObject:object];
    }
}

- (void) testManagedObjectsWithoutDelegate {
    NSEntityDescription* entity = [NSEntityDescription new];
    NSAttributeDescription* idAttribute = [NSAttributeDescription new];
    idAttribute.attributeType = NSStringAttributeType;
    idAttribute.name = RG_STRING_SEL(trackId);
    entity.properties = @[ idAttribute ];
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

- (void) testManagedObjectsWithDelegate {
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    delegate.primaryKey = @"trackId";
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    client.serializationDelegate = delegate;
    objc_setAssociatedObject(client, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGTestManagedObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 1);
        RGTestManagedObject* obj = response.responseBody.firstObject;
        XCTAssert([obj.trackId isEqual:@"1065976170"]);
        XCTAssert([obj.trackName isEqual:@"Comfortably Numb"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testManagedObjectsDelegateNoDupe {
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    delegate.primaryKey = @"trackId";
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    client.serializationDelegate = delegate;
    objc_setAssociatedObject(client, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSManagedObjectContext* context = [delegate contextForManagedObjectType:[RGTestManagedObject self]];
    rg_swizzle([NSManagedObjectContext self], @selector(executeFetchRequest:error:), @selector(override_executeFetchRequestGOOD:error:));
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_non_dupe.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGTestManagedObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 2);
        RGTestManagedObject* obj1 = response.responseBody.firstObject;
        RGTestManagedObject* obj2 = response.responseBody.lastObject;
        XCTAssert([obj1.trackId isEqual:@"1065976170"]);
        XCTAssert([obj1.trackName isEqual:@"Comfortably Numb"]);
        XCTAssert([obj2.trackId isEqual:@"1065976122"]);
        XCTAssert([obj2.trackName isEqual:@"Hey You"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        rg_swizzle([NSManagedObjectContext self], @selector(executeFetchRequest:error:), @selector(override_executeFetchRequestGOOD:error:));
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testManagedObjectsWithDelegateNoChanges {
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    delegate.primaryKey = @"trackId";
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient new];
    client.serializationDelegate = delegate;
    objc_setAssociatedObject(client, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesNO));
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGTestManagedObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 1);
        RGTestManagedObject* obj = response.responseBody.firstObject;
        XCTAssert([obj.trackId isEqual:@"1065976170"]);
        XCTAssert([obj.trackName isEqual:@"Comfortably Numb"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesNO));
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testManagedObjectsWithDelegateFetchError { // TODO: I feel like this should have response.responseBody.count == 1
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    delegate.primaryKey = @"trackId";
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    client.serializationDelegate = delegate;
    objc_setAssociatedObject(client, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    rg_swizzle([NSManagedObjectContext self], @selector(executeFetchRequest:error:), @selector(override_executeFetchRequestBAD:error:));
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGTestManagedObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 2);
        RGTestManagedObject* obj = response.responseBody.firstObject;
        XCTAssert([obj.trackId isEqual:@"1065976170"]);
        XCTAssert([obj.trackName isEqual:@"Comfortably Numb"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        rg_swizzle([NSManagedObjectContext self], @selector(executeFetchRequest:error:), @selector(override_executeFetchRequestBAD:error:));
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testManagedObjectsDelegateNoPrimary {
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    client.serializationDelegate = delegate;
    objc_setAssociatedObject(client, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesYES));
    rg_swizzle([NSManagedObjectContext self], @selector(save:), @selector(override_saveYES:));
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:@"results" class:[RGTestManagedObject self] completion:^(RGResponseObject* response) {
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
        rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesYES));
        rg_swizzle([NSManagedObjectContext self], @selector(save:), @selector(override_saveYES:));
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testManagedObjectsNoDelegateNoPrimary {
    NSEntityDescription* entity = [NSEntityDescription new];
    NSAttributeDescription* idAttribute = [NSAttributeDescription new];
    idAttribute.attributeType = NSStringAttributeType;
    idAttribute.name = RG_STRING_SEL(trackId);
    entity.properties = @[ idAttribute ];
    entity.name = NSStringFromClass([RGTestManagedObject self]);
    entity.managedObjectClassName = entity.name;
    NSManagedObjectModel* model = [NSManagedObjectModel new];
    model.entities = @[ entity ];
    NSPersistentStoreCoordinator* store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = store;
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesNO));
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
        rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesNO));
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testManagedObjectsFromXML {
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    delegate.primaryKey = @"trackId";
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    client.serializationDelegate = delegate;
    client.responseSerializer = [AFXMLParserResponseSerializer new];
    objc_setAssociatedObject(client, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesYES));
    rg_swizzle([NSManagedObjectContext self], @selector(save:), @selector(override_saveNO:));
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_as_xml.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search"
     parameters:@{ @"term" : @"Pink Floyd" }
        keyPath:@"results.object"
          class:[RGTestManagedObject self]
     completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 2);
        RGTestManagedObject* obj1 = response.responseBody.firstObject;
        RGTestManagedObject* obj2 = response.responseBody.lastObject;
        XCTAssert([obj1.trackId isEqual:@"1"]);
        XCTAssert([obj1.trackName isEqual:@"Money"]);
        XCTAssert([obj2.trackId isEqual:@"2"]);
        XCTAssert([obj2.trackName isEqual:@"Time"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        objc_setAssociatedObject(client, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        rg_swizzle([NSManagedObjectContext self], @selector(hasChanges), @selector(override_hasChangesYES));
        rg_swizzle([NSManagedObjectContext self], @selector(save:), @selector(override_saveNO:));
        if (error) {
            XCTFail(@"Something went wrong.");
        }
    }];
}

- (void) testManagedObjectsFromXMLAttributes {
    RGXMLTestObject* delegate = [RGXMLTestObject new];
    delegate.primaryKey = @"trackId";
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    client.serializationDelegate = delegate;
    client.responseSerializer = [AFXMLParserResponseSerializer new];
    objc_setAssociatedObject(client, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_as_xml_id.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search"
     parameters:@{ @"term" : @"Pink Floyd" }
        keyPath:@"results.object"
          class:[RGTestManagedObject self]
     completion:^(RGResponseObject* response) {
         [expectation fulfill];
         XCTAssert(response.responseBody.count == 2);
         RGTestManagedObject* obj1 = response.responseBody.firstObject;
         RGTestManagedObject* obj2 = response.responseBody.lastObject;
         XCTAssert([obj1.trackId isEqual:@"1"]);
         XCTAssert([obj1.trackName isEqual:@"Money"]);
         XCTAssert([obj2.trackId isEqual:@"2"]);
         XCTAssert([obj2.trackName isEqual:@"Time"]);
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

- (void) testGetSearchNoPath {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    [[RGTapeDeck sharedTapeDeck] playTape:@"itunes_search_json.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:nil class:Nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 1);
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
    delegate.primaryKey = @"id";
    client.serializationDelegate = delegate;
    client.responseSerializer = [AFXMLParserResponseSerializer serializer];
    [[RGTapeDeck sharedTapeDeck] playTape:@"xml_data.txt" forURL:@"https://google.com/xml" withCode:200];
    objc_setAssociatedObject(client, @selector(serializationDelegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [client POST:@"https://google.com/xml" parameters:nil keyPath:@"xml.object" class:[RGXMLTestObject self] completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody.count == 2);
        RGXMLTestObject* obj1 = response.responseBody.firstObject;
        RGXMLTestObject* obj2 = response.responseBody.lastObject;
        XCTAssert([obj1.value isEqual:@"42"]);
        XCTAssert([obj2.value isEqual:@"43"]);
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

- (void) testDumbJSONResponse {
    XCTestExpectation* expectation = [self expectationWithDescription:@(sel_getName(_cmd))];
    RGAPIClient* client = [RGAPIClient manager];
    [[RGTapeDeck sharedTapeDeck] playTape:@"dumb_data.txt" forURL:@"https://itunes.apple.com/search" withCode:200];
    [client GET:@"https://itunes.apple.com/search" parameters:nil keyPath:@"results" class:Nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert([response.responseBody[0] isEqual:@2]);
        XCTAssert([response.responseBody[1] isEqual:@3]);
        XCTAssert([response.responseBody[2] isEqual:@"5"]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
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

- (void) testProperties {
    RGAPIClient* client = [[RGAPIClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://hello.com"]];
    client.attemptsToRecreateUploadTasksForBackgroundSessions = YES;
    XCTAssert(client.attemptsToRecreateUploadTasksForBackgroundSessions == YES);
    XCTAssert([client.baseURL isEqual:[NSURL URLWithString:@"https://hello.com"]]);
    client.completionGroup = dispatch_group_create();
    XCTAssert(client.completionGroup);
    client.completionQueue = dispatch_queue_create("hello", DISPATCH_QUEUE_CONCURRENT);
    XCTAssert(client.completionQueue);
    XCTAssert(client.dataTasks.count == 0);
    XCTAssert(client.downloadTasks.count == 0);
    XCTAssert(client.operationQueue);
    client.reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    XCTAssert(client.reachabilityManager == [AFNetworkReachabilityManager sharedManager]);
    id<AFURLRequestSerialization> requestSerializer = [AFPropertyListRequestSerializer serializer];
    client.requestSerializer = requestSerializer;
    XCTAssert(client.requestSerializer == requestSerializer);
    id<AFURLResponseSerialization> responseSerializer = [AFXMLParserResponseSerializer serializer];
    client.responseSerializer = responseSerializer;
    XCTAssert(client.responseSerializer == responseSerializer);
    AFSecurityPolicy* policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    client.securityPolicy = policy;
    XCTAssert(client.securityPolicy == policy);
    id delegate = [RGXMLTestObject new];
    client.serializationDelegate = delegate;
    XCTAssert(client.serializationDelegate == delegate);
    XCTAssert(client.session);
    XCTAssert(client.tasks.count == 0);
    XCTAssert(client.uploadTasks.count == 0);
}

@end
