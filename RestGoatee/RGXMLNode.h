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

extern const NSString* const kRGInnerXMLKey;

@interface RGXMLNode : NSObject

/**
 Set when `-addChildNode:` is called.  A weak reference to the enclosing node.
 */
@property (nonatomic, weak) RGXMLNode* parentNode;

/**
 Attributes come from <object id="123" name="cool"> and will equal @{ "id" : "123", "name" : "cool" }.
 
 Value can be obtained through valueForKeyPath:, @"object.id", in this example.
 
 You may mutate the collection.
 
 The inner text is provided as on the key `kRGInnerXMLKey`.
 */
@property (nonatomic, strong) NSMutableDictionary* attributes;

/**
 The name of the tag.  <foobar>...</foobar> will have the value of `foobar` here.
 */
@property (nonatomic, strong) NSString* name;

/**
 The innerXML if any, including unwrapped CDATA. 
 
 self-closing nodes will have nil; <br/>
 
 adjacent open and close tags will be the empty string; <object></object>
 */
//@property (nonatomic, strong) NSString* text;

@property (nonatomic, strong, readonly) NSArray* childNodes;

/**
 May be either NSArray<RGXML>* or RGXML*
 */
- (id) childrenNamed:(NSString*)name;

- (void) addChildNode:(RGXMLNode*)node;

@end
