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
