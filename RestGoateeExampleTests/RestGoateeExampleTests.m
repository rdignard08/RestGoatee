//
//  RestGoateeExampleTests.m
//  RestGoateeExampleTests
//
//  Created by Ryan Dignard on 8/8/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface RGTestObject : NSObject

@property (nonatomic, strong) NSString* string;
@property (nonatomic, strong) NSArray* array;
@property (nonatomic, strong) NSNumber* number;
@property (nonatomic, assign) BOOL b;
@property (nonatomic, assign) uint32_t value;
@property (nonatomic, assign) Class type;

@end
@implementation RGTestObject @end

@interface RestGoateeExampleTests : XCTestCase

@end

@implementation RestGoateeExampleTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testSerialization {
    RGTestObject* testObject = [[RGTestObject alloc] init];
    
    testObject.string = @"world";
    testObject.array = @[ @"abc" ];
    testObject.number = @2;
    testObject.value = 42;
    
    NSDictionary* serializedTest = [testObject dictionaryRepresentation];
    
    XCTest([serializedTest[@"string"] isEqual:@"world"], @"string failed");
}

- (void) testDeserialization {
    NSDictionary* testJSON = @{
                               @"_str_ing" : @"heelo!",
                               @"array" : @[ @"1", @"2", @"3" ],
                               @"number" : @"3",
                               @"__b" : @YES,
                               @"value" : @1214,
                               @"type" : @"RGTestObject"
                               };
    
    RGTestObject* test = [RGTestObject objectFromJSON:testJSON];
    XCTest(test.b == YES, @"__b failed");
    XCTest([test.string isEqual:testJSON[@"_str_ing"]], @"_str_ing failed");
}

@end
