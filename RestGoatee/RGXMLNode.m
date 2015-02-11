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

@implementation RGXMLNode
@synthesize parentNode = _parentNode;
@synthesize attributes = _attributes;
@synthesize childNodes = _childNodes;

- (NSArray*) childNodes {
    if (!_childNodes) {
        _childNodes = [NSMutableArray new];
    }
    return _childNodes;
}

- (NSMutableDictionary*) attributes {
    if (!_attributes) {
        _attributes = [NSMutableDictionary new];
    }
    return _attributes;
}

- (void) addChildNode:(RGXMLNode*)node {
    node->_parentNode = self;
    [(id)self.childNodes addObject:node];
}

- (id) childrenNamed:(NSString*)name {
    NSMutableArray* ret = [NSMutableArray new];
    for (RGXMLNode* child in self.childNodes) {
        if ([child.name isEqualToString:name]) {
            [ret addObject:child];
        }
    }
    return ret.count > 1 ? ret : [ret lastObject];
}

@end
