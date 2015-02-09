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

/**
 This category can be used for the latter half of the serialization => deserialization => serialization process.
 
 Methods here can turn typical (i.e. non-cyclically strong) objects into JSON (specifically a JSON composed solely only of arrays, dictionaries, strings, and null).
 */
@interface NSObject (RG_SerializationPublic)

/**
 @abstract returns the receiver represented as a dictionary with its property names as keys and the values are the values of that property.  By default the parser will follow weak references.
 */
- (NSDictionary*) dictionaryRepresentation;

/**
 @abstract returns the recevier serialized to JSON.
 */
- (NSData*) JSONRepresentation;

/**
 @abstract equivalent to `-dictionaryRepresentation` but the parser will not parse into objects which are `weak`, `assign`, or `unsafe_unretained` if the parameter `weakReferences` is `NO`.  The default is `YES`.
 */
- (NSDictionary*) dictionaryRepresentationShouldFollowWeakReferences:(BOOL)weakReferences;

@end
