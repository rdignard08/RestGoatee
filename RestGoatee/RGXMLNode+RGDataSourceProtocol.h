/* Copyright (c) 2/5/15, Ryan Dignard
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

#import "RGXMLNode.h"

/**
 These are the methods that a data source must implement in order to be consumable by the `+[NSObject objectFromDataSource:]` family of methods.
 
 Currently NSDictionary and RGXMLNode (the parsed output from NSXMLParser) are supported implicitly.
 
 must be able to `for X in id<RGDataSourceProtocol>`
 */
@protocol RGDataSourceProtocol <NSObject, NSFastEnumeration>

@required

/**
 The data source must support `id value = dataSource[@"key"]`.
 */
- (id) objectForKeyedSubscript:(id<NSCopying, NSObject>)key;

/**
 The data source must support `dataSource[@"key"] = value`.
 */
- (void) setObject:(id)object forKeyedSubscript:(id<NSCopying, NSObject>)key;

/**
 The data source must support `id value = dataSource[@"foo.bar"]`.
 */
- (id) valueForKeyPath:(NSString*)string;

@end

/**
 `NSDictionary` already declares and implements all of these methods.  This allows us to pass an `NSDictionary*` where ever a variable is typed `id<RGDataSourceProtocol>`.
 */
@interface NSDictionary (RGDataSourceProtocol) <RGDataSourceProtocol> @end

/*
 `RGXMLNode` does not provide these method implicitly.  They are implemented in the category `RGXMLNode+RGDataSourceProtocol`.
 */
@interface RGXMLNode (RGDataSourceProtocol) <RGDataSourceProtocol> @end
