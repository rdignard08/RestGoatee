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

@interface RGAPIClientSpec : XCTestCase

@end

@implementation RGAPIClientSpec

- (void) testGetSearch {
    XCTestExpectation* expectation = [self expectationWithDescription:@""];
    [[RGAPIClient manager] GET:@"https://itunes.apple.com/search" parameters:@{ @"term" : @"Pink Floyd" } keyPath:nil class:nil completion:^(RGResponseObject* response) {
        [expectation fulfill];
        XCTAssert(response.responseBody);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError* error) {
        
    }];
}

@end
