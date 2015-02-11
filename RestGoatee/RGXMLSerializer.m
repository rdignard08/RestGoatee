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

#import "RGXMLSerializer.h"
#import "RestGoatee.h"

@interface RGXMLSerializer () <NSXMLParserDelegate>
@property (nonatomic, weak) RGXMLNode* currentNode;
@property (nonatomic, strong) NSMutableString* currentString;
@end

@implementation RGXMLSerializer
@synthesize rootNode = _rootNode;

- (instancetype) initWithParser:(NSXMLParser*)parser {
    self = [super init];
    self.parser = parser;
    return self;
}

- (RGXMLNode*) rootNode {
    if (!_rootNode) {
        _rootNode = [RGXMLNode new];
        _currentNode = _rootNode;
        if (![self.parser parse]) {
            RGLog(@"Warning, XML parsing failed");
        }
    }
    return _rootNode;
}

- (NSMutableString*) currentString {
    if (!_currentString) {
        _currentString = [NSMutableString new];
    }
    return _currentString;
}

- (void) setParser:(NSXMLParser*)parser {
    if (_parser != parser) {
        _rootNode = nil;
        _parser = parser;
        _parser.delegate = self;
    }
}

#pragma mark - NSXMLParserDelegate
- (void) parser:(__unused NSXMLParser*)p didStartElement:(NSString*)element namespaceURI:(__unused NSString*)n qualifiedName:(__unused NSString*)q attributes:(NSDictionary*)attributes {
    RGXMLNode* node = [RGXMLNode new];
    node.name = element;
    [node.attributes addEntriesFromDictionary:attributes];
    [self.currentNode addChildNode:node];
    self.currentNode = node;
}

- (void) parser:(__unused NSXMLParser*)p foundCharacters:(NSString*)string {
    [self.currentString appendString:string];
}

- (void) parser:(__unused NSXMLParser*)p didEndElement:(__unused NSString*)e namespaceURI:(__unused NSString*)n qualifiedName:(__unused NSString*)q {
    self.currentNode.innerXML = self->_currentString;
    self->_currentString = nil;
    self.currentNode = self.currentNode.parentNode; /* move up the parse tree */
}

- (void) parser:(__unused NSXMLParser*)p foundCDATA:(NSData*)CDATABlock {
    [self.currentString appendString:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
}

@end
