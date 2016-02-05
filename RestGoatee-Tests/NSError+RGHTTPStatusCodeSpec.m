//
//  NSError+RGHTTPStatusCodeSpec.m
//  RestGoatee
//
//  Created by Ryan Dignard on 2/5/16.
//  Copyright © 2016 Ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NSError+RG_HTTPStatusCode.h"

@interface NSError_RGHTTPStatusCodeSpec : XCTestCase

@end

@implementation NSError_RGHTTPStatusCodeSpec

- (void) testStatusCodeNil {
    NSError* error = [NSError new];
    XCTAssert(error.HTTPStatusCode == 0);
}

- (void) testSetStatusCode {
    NSError* error = [NSError new];
    error.HTTPStatusCode = 400;
    XCTAssert(error.HTTPStatusCode == 400);
}

- (void) testExtraDataNil {
    NSError* error = [NSError new];
    XCTAssert(error.extraData == nil);
}

- (void) testSetExtraData {
    NSError* error = [NSError new];
    error.extraData = @"foobar";
    XCTAssert([error.extraData isEqual:@"foobar"]);
}

@end
